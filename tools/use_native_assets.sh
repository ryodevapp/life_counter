#!/bin/bash
# objective_c.framework を、シミュレーター用か実機用に切り替える(上書きのみ。何も消さない)
#
# Flutter は build/native_assets/ios/objective_c.framework を作り直さないので、
# シミュレーターで動かしたあとに本番ビルドを作ると、シミュレーター用が混ざって App Store に拒否される。
# 逆に実機用のままだと、シミュレーターで起動できない。
#
# 使い方: tools/use_native_assets.sh sim     (シミュレーターで動かす前)
#         tools/use_native_assets.sh device  (flutter build ipa の前)
# 控え: ~/Library/Developer/lifecounter_native_assets/{sim,device}/objective_c.framework
set -euo pipefail

kind="${1:-}"
if [[ "$kind" != "sim" && "$kind" != "device" ]]; then
  echo "使い方: $0 sim|device" >&2
  exit 2
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$HOME/Library/Developer/lifecounter_native_assets/$kind/objective_c.framework"
dst="$root/build/native_assets/ios/objective_c.framework"

if [[ ! -f "$src/objective_c" ]]; then
  echo "控えがありません: $src" >&2
  exit 1
fi
mkdir -p "$dst"
cp -R "$src/." "$dst/"

want=$([[ "$kind" == "sim" ]] && echo IOSSIMULATOR || echo IOS)
got="$(vtool -show-build "$dst/objective_c" | awk '/platform/{print $2; exit}')"
if [[ "$got" != "$want" ]]; then
  echo "NG  切り替えられませんでした($got)" >&2
  exit 1
fi
echo "OK  objective_c を $kind 用($got)にしました"
