#!/usr/bin/env bash
# pre-mysql-sensitive-select.sh — PreToolUse (mcp__mysql-*__mysql_query) hook。
#
# 擋下對「含帳密欄位的表」下 `SELECT *`，避免帳密被讀進 context。
# 表清單 SSOT：.claude/skills/zdpos-environment/references/mysql.md「### 含帳密欄位的表」。
#   data_redeemtype：api_var1..api_var5（第三方兌換 API 金鑰）
#   data_station：dvr_user、dvr_pass（DVR 帳密）
# 明列欄位的查詢不受影響。
set -o pipefail

. "$(dirname "$0")/_lib/payload.sh"

PAYLOAD="$(cat 2>/dev/null || true)"
SQL="$(extract_tool_input sql "$PAYLOAD")"
[ -z "$SQL" ] && exit 0

SENSITIVE_TABLES='data_redeemtype|data_station'

# 壓成單行、轉小寫後比對：SELECT 清單含 `*`（含 `t.*`），且 FROM／JOIN 對象是敏感表（可帶 schema 與反引號）。
NORM="$(printf '%s' "$SQL" | tr '\n\r\t' '   ' | tr '[:upper:]' '[:lower:]')"
if printf '%s' "$NORM" | grep -Eq "select[[:space:]]+(distinct[[:space:]]+)?([a-z0-9_\`]+\.)?\*" \
  && printf '%s' "$NORM" | grep -Eq "(from|join)[[:space:]]+([a-z0-9_\`]+\.)?\`?(${SENSITIVE_TABLES})\`?([[:space:]]|;|$|\))"; then
  cat <<'EOF' >&2
[guard] BLOCKED: SELECT * on a table with credential columns
data_redeemtype (api_var1..api_var5) / data_station (dvr_user, dvr_pass) hold credentials.
List the columns you need explicitly, e.g.
  SELECT redeem_type, redeem_name, redeem_action, state FROM data_redeemtype
  SELECT store_no, station_no, need_table FROM data_station
SSOT: zdpos-environment references/mysql.md "### 含帳密欄位的表".
EOF
  exit 2
fi

exit 0
