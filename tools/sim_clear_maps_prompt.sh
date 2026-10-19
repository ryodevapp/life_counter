#!/bin/bash
# シミュレーターのホーム画面から、マップのウィジェットの位置情報の許可の小窓を消す
#
# iOS 26 以降の新しいシミュレーターは、ホーム画面のマップのウィジェットが位置情報の許可を求める小窓を出す。
# 小窓がアプリを隠し、撮影の画像が全部白くなる(10/19 に120枚)。simctl privacy の grant では消えない。
# ここでは、シミュレーターを止めて、①ホーム画面のマップのウィジェットをマップのアイコンに差し替え、
# ②位置情報の記録(locationd の clients.plist)からマップの欄を外し、起動し直す。
# 触るのは、そのシミュレーターの中の2つのファイルだけ。元のファイルは控えのフォルダに写す。
#
# 使い方: tools/sim_clear_maps_prompt.sh <UDID>
set -euo pipefail

udid="${1:-}"
if [[ -z "$udid" ]]; then
  echo "使い方: $0 <シミュレーターの UDID>" >&2
  exit 2
fi
lib="$HOME/Library/Developer/CoreSimulator/Devices/$udid/data/Library"
icons="$lib/SpringBoard/IconState.plist"
clients="$lib/Caches/locationd/clients.plist"
[[ -f "$icons" ]] || { echo "ホーム画面の配置が見つかりません: $icons" >&2; exit 1; }

backup="$(mktemp -d)"
cp "$icons" "$backup/IconState.plist"
[[ -f "$clients" ]] && cp "$clients" "$backup/clients.plist"
echo "控え: $backup"

xcrun simctl shutdown "$udid" 2>/dev/null || true
/usr/bin/python3 -I - "$icons" "$clients" <<'PY'
import os, plistlib, sys
icons, clients = sys.argv[1], sys.argv[2]
with open(icons, 'rb') as f:
    s = plistlib.load(f)
n = 0
for page in s.get('iconLists', []):
    for i, e in enumerate(page):
        if isinstance(e, dict) and e.get('bundleIdentifier') == 'com.apple.Maps.GeneralMapsWidget':
            page[i] = 'com.apple.Maps'
            n += 1
with open(icons, 'wb') as f:
    plistlib.dump(s, f, fmt=plistlib.FMT_BINARY)
keys = []
if os.path.exists(clients):
    with open(clients, 'rb') as f:
        c = plistlib.load(f)
    keys = [k for k in c if 'com.apple.Maps' in k]
    for k in keys:
        del c[k]
    with open(clients, 'wb') as f:
        plistlib.dump(c, f, fmt=plistlib.FMT_BINARY)
print(f"マップのウィジェット {n} 個をアイコンに、位置情報の記録から {len(keys)} 件を外しました")
PY
xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" >/dev/null
echo "起動し直しました。ホーム画面が出るまで1分ほど待ってから撮ってください"
