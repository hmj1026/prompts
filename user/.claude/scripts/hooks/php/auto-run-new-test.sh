#!/bin/bash
# Auto-run newly written test files to confirm RED state
# Uses dynamic project root detection instead of hardcoded paths

FILE_PATH="$1"

if [[ "$FILE_PATH" == *"protected/tests/"* ]] && [[ "$FILE_PATH" == *"Test.php" ]]; then
  PROJECT_ROOT=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$PROJECT_ROOT" ]] && exit 0

  RELATIVE_PATH="${FILE_PATH#$PROJECT_ROOT/}"

  # Detect Docker container name from docker-compose
  CONTAINER=""
  for f in "$PROJECT_ROOT/docker-compose.yaml" "$PROJECT_ROOT/docker-compose.yml"; do
    [[ -f "$f" ]] && CONTAINER=$(grep -m1 'container_name:' "$f" 2>/dev/null | awk '{print $2}' | tr -d '"'"'") && break
  done
  [[ -z "$CONTAINER" ]] && CONTAINER="pos_php"

  # Detect webroot from docker-compose volumes (fallback to convention)
  WEBROOT="//var/www/www.posdev/zdpos_dev"

  echo "New test file: $RELATIVE_PATH"
  echo "Running: docker exec -i -w $WEBROOT $CONTAINER phpunit $RELATIVE_PATH"
  docker exec -i -w "$WEBROOT" "$CONTAINER" phpunit "$RELATIVE_PATH" 2>&1 | tail -10 || true
fi
