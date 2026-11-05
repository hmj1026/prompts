#!/usr/bin/env bash
# 本機 Docker 站台的 migration 落差檢查，以及單支套用。
# 用法：
#   migration-drift.sh list  [config=dev4] [db=zdpos_dev_2]
#   migration-drift.sh apply <version> [config=dev4] [db=zdpos_dev_2]
# 做法：先比對 protected/migrations/ 與 tbl_migration；apply 只跑指定的那一支。
# 不用 `yiic migrate to`，因為它會連同排在前面的 pending 一起套用。
# 只適用本機 pos_php 容器（工作目錄 /var/www/www.posdev/zdpos-217）。
set -euo pipefail

ACTION="$1"; shift
VERSION=""
if [ "$ACTION" = "apply" ]; then VERSION="$1"; shift; fi
CONFIG="${1:-dev4}"
DB="${2:-zdpos_dev_2}"

HOST_REPO=/home/paul/projects/zdpos-217
CT_REPO=/var/www/www.posdev/zdpos-217
SRC="$(dirname "$0")/migration-drift.php"
TMP_NAME="tmp_migration_drift_$$.php"

cp "$SRC" "$HOST_REPO/protected/runtime/$TMP_NAME"
trap 'rm -f "$HOST_REPO/protected/runtime/$TMP_NAME"' EXIT
docker exec -i -w "$CT_REPO" pos_php php "protected/runtime/$TMP_NAME" "$CONFIG" "$DB" "$ACTION" $VERSION
