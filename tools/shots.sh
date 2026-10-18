#!/bin/bash
# 撮影の条件の2段(2026-10-18 本人の決定。3アプリ共通の案は ~/Projects/playbook/drafts/screenshot-conditions-3apps.md)
#
# 使い方: tools/shots.sh every|release [撮影のテスト(既定 store_shots_test)] [flutter drive に足す引数...]
#   every   毎回(画面を直したら): iOS 27 の iPhone 16 で、昼・夜 × 既定・最大の文字の4回。
#           ウィジェットを直したときは色合いも毎回: ホーム画面を長押し →「編集」→「カスタマイズ」→「色合い」にして
#           xcrun simctl io booted screenshot <ファイル> で撮る(ウィジェットは Swift なので、この道具では撮れない)
#   release 出す前だけ(審査に出す前): every に加えて、iOS 26 の iPhone 16 と iOS 27 の iPhone SE で同じ4回。
#           透明度を下げるは Flutter に値が無いので、シミュレーターの設定で手で見る。ロック画面のウィジェットは持たない
# 例: tools/shots.sh every / tools/shots.sh release all_screens_test / tools/shots.sh every store_shots_test --dart-define=LANG=en
# 画像は build/screens/<OS>-<端末>/ に書く。DRY=1 を付けると、打つコマンドを出すだけ(シミュレーターを探さない)
set -euo pipefail

mode="${1:-}"
target="${2:-store_shots_test}"
shift $(( $# >= 2 ? 2 : $# ))
case "$mode" in
  every) devices=("27|iPhone 16") ;;
  release) devices=("27|iPhone 16" "26|iPhone 16" "27|iPhone SE (3rd generation)") ;;
  *) echo "使い方: tools/shots.sh every|release [撮影のテスト] [flutter drive の引数...]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")/.."

# OS の版(27 など)と端末の名前から、使えるシミュレーターの UDID を1つ選ぶ。無ければ止める
udid_for() {
  xcrun simctl list devices available -j | /usr/bin/python3 -c '
import json, sys
os_major, name = sys.argv[1], sys.argv[2]
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if f".iOS-{os_major}-" not in runtime + "-":
        continue
    for d in devices[runtime]:
        if d["name"] == name:
            print(d["udid"]); sys.exit(0)
sys.exit(f"iOS {os_major} の {name} のシミュレーターがありません(Xcode の Settings → Components で入れる)")
' "$1" "$2"
}

for device in "${devices[@]}"; do
  os="${device%%|*}"
  name="${device#*|}"
  dir="build/screens/ios${os}-$(echo "$name" | tr -cd '[:alnum:]')"
  if [ -n "${DRY:-}" ]; then
    udid="<iOS ${os} の ${name}>"
  else
    udid="$(udid_for "$os" "$name")"
    xcrun simctl boot "$udid" 2>/dev/null || true
  fi
  for theme in light dark; do
    for text in default max; do
      cmd=(flutter drive --driver=test_driver/integration_test.dart --target="integration_test/${target}.dart"
           -d "$udid" --dart-define=THEME="$theme" --dart-define=TEXT="$text" "$@")
      echo "SCREENS_DIR=$dir ${cmd[*]}"
      if [ -z "${DRY:-}" ]; then
        SCREENS_DIR="$dir" "${cmd[@]}"
      fi
    done
  done
done
