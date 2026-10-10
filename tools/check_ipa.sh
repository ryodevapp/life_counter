#!/bin/bash
# 本番用のアーカイブに、シミュレーター用の部品が混ざっていないかを確かめる
# 使い方: tools/check_ipa.sh [アーカイブのパス]
set -u
ARCHIVE="${1:-build/ios/archive/Runner.xcarchive}"
APP="$ARCHIVE/Products/Applications/Runner.app"
[ -d "$APP" ] || { echo "アーカイブが見つかりません: $ARCHIVE"; exit 2; }
bad=0
while IFS= read -r bin; do
  platform=$(vtool -show-build "$bin" 2>/dev/null | awk '/platform/{print $2; exit}')
  [ -z "$platform" ] && continue
  if [ "$platform" != "IOS" ]; then
    echo "NG  $platform  ${bin#$APP/}"
    bad=1
  fi
done < <(find "$APP" -type f \( -perm -u+x -o -name "*.dylib" \) ! -name "*.sh")
if [ $bad -eq 0 ]; then echo "OK  すべて実機(IOS)用です: $APP"; else echo "シミュレーター用などが混ざっています。flutter clean してから作り直してください"; exit 1; fi
