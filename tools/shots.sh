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

# OS の版(27 など)と機種の名前から、使えるシミュレーターの UDID を1つ選ぶ。
# 名前でなく機種で探す(「iPhone 16 26.5」のように名前を変えたものも拾う)。名前が同じものを先に選ぶ。
# その版にその機種が無ければ、新しい版の OS で作る(作るだけで、何も消さない)。OS が無ければ止める
udid_for() {
  /usr/bin/python3 - "$1" "$2" <<'PY'
import json, subprocess, sys
os_major, name = sys.argv[1], sys.argv[2]
def simctl(*args):
    return subprocess.run(["xcrun", "simctl", *args], check=True, capture_output=True, text=True).stdout
types = json.loads(simctl("list", "devicetypes", "-j"))["devicetypes"]
type_id = next((t["identifier"] for t in types if t["name"] == name), None)
if type_id is None:
    sys.exit(f"{name} という機種がありません")
runtimes = [r for r in json.loads(simctl("list", "runtimes", "available", "-j"))["runtimes"]
            if r["identifier"].startswith(f"com.apple.CoreSimulator.SimRuntime.iOS-{os_major}-")]
if not runtimes:
    sys.exit(f"iOS {os_major} のシミュレーターがありません(Xcode の Settings → Components で入れる)")
devices = json.loads(simctl("list", "devices", "available", "-j"))["devices"]
for runtime in sorted((r["identifier"] for r in runtimes), reverse=True):
    found = [d for d in devices.get(runtime, []) if d.get("deviceTypeIdentifier") == type_id]
    found.sort(key=lambda d: d["name"] != name)
    if found:
        print(found[0]["udid"]); sys.exit(0)
newest = max(runtimes, key=lambda r: [int(x) for x in r["version"].split(".")])
print(simctl("create", f"{name} (shots)", type_id, newest["identifier"]).strip())
PY
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
