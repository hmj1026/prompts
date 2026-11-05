#!/usr/bin/env bash
# agent-browser 操作 zdpos POS 前台的共用子命令。
# 用法：
#   pos-ab.sh <session> login <vault-profile> <base-url> <station> [kick]
#   pos-ab.sh <session> click <按鈕文字> [first|last]       # POS 主頁面葉節點（商品格、功能鍵、數字鍵）
#   pos-ab.sh <session> iframe-click <文字>                  # 桌況 iframe 內的廳別分頁或桌位（文字開頭比對）
#   pos-ab.sh <session> dismiss                              # 關閉 sweetalert（取消）與所有可見的 jQuery UI dialog
#   pos-ab.sh <session> logout <base-url>
# base-url 例：https://www.zdpos.tw/dev 、https://www.posdev.test/dev4
# kick：只在本機站台使用；會設 RepeatAction=1 踢掉同機號的舊 session。DEV／UAT 不要用。
set -euo pipefail

S="$1"; CMD="$2"; shift 2
ab() { agent-browser --session "$S" "$@"; }

js_quote() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

case "$CMD" in
  login)
    PROFILE="$1"; BASE="$2"; STATION="$3"; KICK="${4:-}"
    ab --ignore-https-errors open "$BASE/site/login" >/dev/null
    ab set viewport 1366 900 >/dev/null
    # vault 只填帳密；submit selector 指向無害元素，機號設好後才送出。
    ab auth login "$PROFILE" --url "$BASE/site/login" \
      --username-selector "input[name='LoginForm[username]']" \
      --password-selector "input[name='LoginForm[password]']" \
      --submit-selector "h1, .logo, img" >/dev/null
    RA=0; [ "$KICK" = "kick" ] && RA=1
    ab eval "(() => { const sel = document.querySelector('select[name=\"LoginForm[station]\"]'); if (sel) { sel.value = $(js_quote "$STATION"); sel.dispatchEvent(new Event('change', {bubbles: true})); } const ra = document.querySelector('input[name=RepeatAction]'); if (ra && $RA) ra.value = '1'; document.getElementById('login-form').submit(); return 'submitted'; })()" >/dev/null
    ab wait --load networkidle >/dev/null
    URL="$(ab get url)"
    echo "url=$URL"
    case "$URL" in
      */site/login*) echo "LOGIN FAILED（可能是機號重複；DEV 不要用 kick，回報即可）"; exit 1 ;;
    esac
    ;;
  click)
    TEXT="$1"; WHICH="${2:-first}"
    ab eval "(() => { const want = $(js_quote "$TEXT").replace(/\\s/g, ''); const els = Array.from(document.querySelectorAll('div,td,span,button,a,li,input')).filter(e => e.offsetWidth > 0 && Array.from(e.children).every(c => c.tagName === 'BR')).filter(e => ((e.innerText || e.value || '')).replace(/\\s/g, '') === want); if (!els.length) return 'not found: ' + want; const el = '$WHICH' === 'last' ? els[els.length - 1] : els[0]; ['mousedown', 'mouseup', 'click'].forEach(t => el.dispatchEvent(new MouseEvent(t, {bubbles: true, cancelable: true, view: window}))); return 'clicked ' + want + ' (' + els.length + ')'; })()"
    ;;
  iframe-click)
    TEXT="$1"
    ab eval "(() => { const f = document.querySelector('iframe'); if (!f) return 'no iframe'; const w = f.contentWindow; const want = $(js_quote "$TEXT"); const el = Array.from(w.document.querySelectorAll('a, li')).find(e => e.offsetWidth > 0 && (e.innerText || '').trim().startsWith(want)); if (!el) return 'not found: ' + want; w.jQuery(el).trigger('click'); return 'clicked ' + (el.innerText || '').trim().split('\\n')[0]; })()"
    ;;
  dismiss)
    ab eval "(() => { const out = []; const sw = document.querySelector('.swal2-cancel'); if (sw && sw.offsetWidth > 0) { sw.click(); out.push('swal-cancel'); } Array.from(document.querySelectorAll('.ui-dialog')).filter(d => d.offsetWidth > 0).forEach(d => { const id = d.querySelector('.ui-dialog-content'); if (id && window.jQuery) { window.jQuery(id).dialog('close'); out.push('dialog:' + (id.id || '?')); } }); return out.join(',') || 'nothing'; })()"
    ;;
  logout)
    BASE="$1"
    ab open "$BASE/site/logout" >/dev/null
    ab close >/dev/null
    echo "logged out and closed"
    ;;
  *)
    echo "unknown command: $CMD"; exit 2 ;;
esac
