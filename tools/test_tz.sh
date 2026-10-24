#!/bin/bash
# 時間帯を変えて単体テストを流す(LC-30)。夏時間のある地域と、日付変更線の近くを含める。
# 使い方: tools/test_tz.sh [テストのファイル...](省略すると、時間帯に左右されるテストだけ)
# 親が打つときに頭に環境変数を付けなくてよいよう、TZ はこの中で付ける。
set -euo pipefail
cd "$(dirname "$0")/.."
targets=("$@")
if [ ${#targets[@]} -eq 0 ]; then
  targets=(test/services/dst_day_count_test.dart test/services/birth_day_key_migration_test.dart test/utils/day_key_test.dart test/services/morning_schedule_test.dart test/services/widget_sync_test.dart)
fi
zones=(America/New_York America/Los_Angeles Europe/London Australia/Sydney Pacific/Honolulu Pacific/Kiritimati Asia/Tokyo)
failed=()
for z in "${zones[@]}"; do
  echo "=== TZ=$z ==="
  if ! TZ="$z" flutter test "${targets[@]}"; then
    failed+=("$z")
  fi
done
if [ ${#failed[@]} -gt 0 ]; then
  echo "落ちた時間帯: ${failed[*]}"
  exit 1
fi
echo "全部の時間帯で通った: ${zones[*]}"
