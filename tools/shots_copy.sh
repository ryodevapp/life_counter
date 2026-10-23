#!/bin/bash
# 写しで撮る: 毎回新しい一時フォルダに写してから flutter drive で撮る(1.1.4、10/23)
#
# 使い方: tools/shots_copy.sh [--rev <コミット>] <画像の場所> <シミュレーターの UDID> <撮影のテスト...> [-- flutter drive に足す引数...]
# 例:     tools/shots_copy.sh --rev HEAD "$TMPDIR/before/iphone" 2A187CA0-... all_screens_test -- --dart-define=THEME=dark --dart-define=TEXT=max
#         tools/shots_copy.sh "$TMPDIR/after/iphone" 2A187CA0-... all_screens_test phrase_break_shots_test -- --dart-define=TEXT=max
#
# 何のため: 直す前と後を並べて撮る・iPhone と iPad を同時に撮る・作業中の本体を動かさずに撮るとき、本体とは別の場所で撮る。
#   --rev なし … 今の作業の中身(git の追跡しているファイルと、無視していない追跡外のファイル)を写す
#   --rev あり … そのコミットの中身を写す(git archive。作業の場所は触らない)
#
# なぜ毎回新しい場所か: 同じ写しに rsync で上書きして2回目を撮ると、写しに残った build/・.dart_tool/・ios/Pods/ が
#   前の回の中身(前の回の pub のキャッシュの場所・前の回に組んだアプリ)を指したまま走り、
#   直した後の画像のつもりが直す前のアプリで撮れていた(10/23、Xcode が前の回の pub-cache の場所の
#   flutter_local_notifications の .h を探して失敗した回もある)。rsync の --exclude は「写さない」だけで「消さない」ので、
#   毎回 mktemp -d で空の場所を作り、生成物は写さない。写しは消さずに残す(ログを見直すため。$TMPDIR の下)
#
# 画像は <画像の場所>/ に、テストごとのログは <画像の場所>/log_<テスト>.txt に書く。
# 最後に、テストごとの合否と「語の途中の割れ(PHRASE_SPLITS)」「文字の切れ」「縮めた語(PHRASE_SHRUNK)」をまとめて出す。
# 1本でも落ちたら終了コード 1
set -uo pipefail

rev=""
if [ "${1:-}" = "--rev" ]; then
  rev="${2:?--rev にはコミットを渡す}"
  shift 2
fi
out="${1:?画像の場所を渡す}"
udid="${2:?シミュレーターの UDID を渡す(xcrun simctl list devices available)}"
shift 2
tests=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do
  tests+=("$1")
  shift
done
[ "${1:-}" = "--" ] && shift
[ ${#tests[@]} -gt 0 ] || { echo "撮影のテストの名前を1つ以上渡す(例 all_screens_test)" >&2; exit 2; }

repo="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/lc_shots.XXXXXX")"

if [ -n "$rev" ]; then
  git -C "$repo" archive "$rev" | tar -x -C "$work"
  echo "写し: $work($rev の中身)"
else
  # 生成物(build/・.dart_tool/・ios/Pods/・ios/.symlinks/ など .gitignore のもの)は写さない。.claude/ も写さない
  (cd "$repo" && git ls-files -co --exclude-standard -z) |
    tr '\0' '\n' | grep -v '^\.claude/' |
    rsync -a --files-from=- "$repo/" "$work/"
  echo "写し: $work(今の作業の中身)"
fi

cd "$work" || exit 1
status=0
for t in "${tests[@]}"; do
  log="$out/log_$t.txt"
  echo "=== $t → $log"
  SCREENS_DIR="$out" flutter drive --driver=test_driver/integration_test.dart \
    --target="integration_test/$t.dart" -d "$udid" "$@" >"$log" 2>&1
  code=$?
  [ $code -eq 0 ] || status=1
  echo "    終了コード $code"
  grep -E "All tests passed|Some tests failed|Error \(Xcode\)" "$log" | sort -u | sed 's/^/    /'
  grep -E "^  - " "$log" | sort -u | sed 's/^/    /'
  grep -E "PHRASE_SHRUNK" "$log" | sed 's/^flutter: //' | sort -u | sed 's/^/    /'
done
echo "画像: $out"
exit $status
