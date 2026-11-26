#!/usr/bin/env bash
# 裝有攔截器的 POS 前台操作（UAT／vm1 登入後的所有操作都走這支）。
# 每次操作前確認攔截器已武裝，操作後重裝（頁面可能已換）。
# 分工：login、logout 用 pos-ab.sh（登入前與登出後沒有頁面可裝攔截器）；登入後先跑 guard，之後 click、iframe-click、dismiss 都走本檔。
# 用法：
#   pos-guard.sh <session> guard
#   pos-guard.sh <session> click <文字> [first|last]
#   pos-guard.sh <session> iframe-click <文字>
#   pos-guard.sh <session> dismiss
#   pos-guard.sh <session> ack                     # 清除擋下紀錄以繼續操作（被擋的請求從未送出）；須先由主控判斷原因
#   pos-guard.sh <session> void-ok <10 碼單號>     # 登記一次作廢核准；需 POS_GUARD_APPROVED=<核准清單檔，一行一號>
#   pos-guard.sh <session> isolated-ok <站>        # 隔離站放行拆帳與開票；需 POS_GUARD_ISOLATED=<核准清單檔，一行一站>，且站在 pos-guard.js 的 ISOLATED_SITES；頁面重載後須重跑
# 流程約束（程式無法強制）：核准清單檔由主控提供，代理不得自行建立或改寫；ack 與 void-ok 只在主控指示後執行。
# 同一系統使用者可直接改檔或呼叫 ack，本檔不驗證呼叫者身分。
# 作廢核准只涵蓋一般作廢，送出一次即消耗；折讓事件一律擋下，不在核准範圍。
# Exit：0 正常；2 用法錯誤；8 未核准的作廢或隔離站；9 攔截器未武裝；10 有請求被擋下。
set -euo pipefail

[ "$#" -ge 2 ] || { echo "usage: pos-guard.sh <session> <command> [args]" >&2; exit 2; }
S="$1"; CMD="$2"; shift 2
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ab_eval() { agent-browser --session "$S" eval "$1"; }

# 只認 armed === true；輸出不是預期的 JSON 一律視為未武裝。
guard_check() {
  local out
  out="$(ab_eval "$(cat "$DIR/pos-guard.js")")" || { echo "GUARD NOT ARMED: eval failed" >&2; exit 9; }
  printf '%s' "$out" | python3 -I "$DIR/pos-guard-state.py" || exit $?
}

case "$CMD" in
  guard)
    guard_check ;;
  click|iframe-click|dismiss)
    guard_check >/dev/null
    bash "$DIR/pos-ab.sh" "$S" "$CMD" "$@"
    guard_check ;;
  ack)
    ab_eval "JSON.stringify({ acknowledged: window.__posGuard ? window.__posGuard.blocked.splice(0) : [] })"
    guard_check ;;
  void-ok)
    NO="${1:-}"
    [[ "$NO" =~ ^[0-9]{10}$ ]] || { echo "單號必須是 10 碼數字" >&2; exit 2; }
    [ -f "${POS_GUARD_APPROVED:-}" ] || { echo "REFUSED: 未設定 POS_GUARD_APPROVED" >&2; exit 8; }
    tr -d '\r' < "$POS_GUARD_APPROVED" | grep -qxF -- "$NO" || { echo "REFUSED: 核准清單內沒有 $NO" >&2; exit 8; }
    guard_check >/dev/null
    ab_eval "window.__posGuard.voidOK.push('$NO')" >/dev/null
    echo "approved $NO" ;;
  isolated-ok)
    SITE="${1:-}"
    [[ "$SITE" =~ ^[a-z0-9_]+$ ]] || { echo "站名只能是小寫英數與底線" >&2; exit 2; }
    [ -f "${POS_GUARD_ISOLATED:-}" ] || { echo "REFUSED: 未設定 POS_GUARD_ISOLATED" >&2; exit 8; }
    tr -d '\r' < "$POS_GUARD_ISOLATED" | grep -qxF -- "$SITE" || { echo "REFUSED: 核准清單內沒有 $SITE" >&2; exit 8; }
    guard_check >/dev/null
    out="$(ab_eval "(() => { const ok = location.pathname.split('/').filter(Boolean)[0] === '$SITE'; if (ok) window.__posGuard.isolated = '$SITE'; return ok ? 'isolated $SITE' : 'REFUSED: page not on $SITE'; })()")"
    case "$out" in *REFUSED*) echo "$out" >&2; exit 8 ;; esac
    echo "$out" ;;
  *)
    echo "unknown command: $CMD" >&2; exit 2 ;;
esac
