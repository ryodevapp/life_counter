#!/bin/bash
# LC-21 新しい iPhone に移したときに記録が戻るかを、シミュレーター2台で確かめる
#
# 1. 移す元(SRC)で integration_test/backup_restore_test.dart を write で動かし、記録・設定・ウィジェットの共有のデータを書く
# 2. 元を止め(UserDefaults を書き切らせる)、アプリのデータの入れ物と App Group の入れ物から、
#    iCloud バックアップの対象の所だけを写す(Library/Caches と tmp と、バックアップから外す印の付いたものは写さない)
# 3. 移した先(DST)にアプリを入れ、一度も開かずに止めて、写したものを置く
# 4. 先で同じ試験を verify で動かす(本物の main から開き、記録・設定・ウィジェットのスタンプがそろうか)
#
# 使い方: tools/lc21_transfer.sh <SRC の UDID> <DST の UDID>
# どちらも、この試験のためだけに作った空のシミュレーターを渡す(普段の撮影の端末は渡さない。中身を上書きする)
# 写しは mktemp -d の新しい場所に置く。何も消さない
set -euo pipefail

src="${1:?SRC の UDID}"
dst="${2:?DST の UDID}"
bundle=com.lifecounter.lifeCounter
group=group.com.lifecounter.lifeCounter
root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
echo "写しの場所: $work"

drive() { # $1=UDID $2=phase
  # --keep-app-running: 付けないと、終わったあとにアプリを消し、データの入れ物ごと無くなる(10/23 に確かめた)
  (cd "$root" && flutter drive -d "$1" --keep-app-running \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/backup_restore_test.dart \
    --dart-define=LC21_PHASE="$2")
}

group_dir() { # $1=UDID。App Group の入れ物の場所
  xcrun simctl get_app_container "$1" "$bundle" groups | awk -v g="$group" '$1==g {print $2}'
}

# バックアップの対象の所だけを写す(Caches・tmp・Snapshots は対象外。Apple の File System Programming Guide)
copy_backup_scope() { # $1=元 $2=先
  rsync -a --exclude '/Library/Caches/' --exclude '/tmp/' \
    --exclude '/Library/SplashBoard/' "$1/" "$2/"
}

# バックアップから外す印(isExcludedFromBackup)が付いたものを並べる。1つでもあれば、それは移らない
list_excluded() { # $1=場所
  find "$1" -print0 | while IFS= read -r -d '' f; do
    if xattr -p com.apple.metadata:com_apple_backup_excludeItem "$f" >/dev/null 2>&1; then
      echo "  バックアップから外す印: ${f#$1/}"
    fi
  done
}

echo "== 1. 元で書く"
xcrun simctl boot "$src" 2>/dev/null || true
drive "$src" write

src_data="$(xcrun simctl get_app_container "$src" "$bundle" data)"
src_group="$(group_dir "$src")"
echo "元のデータ: $src_data"
echo "元の App Group: $src_group"

echo "== 2. 元を止めて、バックアップの対象の所だけ写す"
xcrun simctl shutdown "$src"
echo "-- 元のデータの中身"
(cd "$src_data" && find Documents Library -type f | grep -v '^Library/Caches/' | sort)
echo "-- 元の App Group の中身"
(cd "$src_group" && find . -type f | grep -v '^./Library/Caches/' | sort)
echo "-- バックアップから外す印(無ければ何も出ない)"
list_excluded "$src_data"
list_excluded "$src_group"
mkdir -p "$work/data" "$work/group"
copy_backup_scope "$src_data" "$work/data"
copy_backup_scope "$src_group" "$work/group"

echo "== 3. 先にアプリを入れ、開かずに止めて置く"
app="$root/build/ios/iphonesimulator/Runner.app"
xcrun simctl boot "$dst" 2>/dev/null || true
xcrun simctl install "$dst" "$app"
dst_data="$(xcrun simctl get_app_container "$dst" "$bundle" data)"
dst_group="$(group_dir "$dst")"
echo "先のデータ: $dst_data"
echo "先の App Group: $dst_group"
xcrun simctl shutdown "$dst"
rsync -a "$work/data/" "$dst_data/"
rsync -a "$work/group/" "$dst_group/"

echo "== 4. 先で、本物の起動から確かめる"
xcrun simctl boot "$dst"
drive "$dst" verify
