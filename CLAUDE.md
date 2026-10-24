# LifeCounter(life_counter)

「人生◯日目」と今日の問い・気分のスタンプ・やりたいことリストを出す Flutter の iOS アプリとウィジェット。ソロ開発。
App Store で配信中(v1.1.1+39 が `main`)。日本語と英語。課題の台帳は Jira(キー LC)。

- 全リポジトリ共通の進め方とリポジトリの地図は `~/Projects/CLAUDE.md`(本体は `playbook/claude/projects-CLAUDE.md`)

## 地図

- `lib/main.dart` 起動。Isar を開き(スキーマの登録はここ)、日付の移し替え `migrateDayKeys` を走らせる。開けないときは `lib/views/startup/` の画面
- `lib/models/` 保存の型(Isar。`*.g.dart` は build_runner が作る。手で直さない)
- `lib/repositories/` 保存の読み書き / `lib/providers/` Riverpod / `lib/router/app_router.dart` go_router
- `lib/services/` 計算と端末の機能(`life_calculator.dart`・`question_bank.dart`・`notification_service.dart`・`widget_sync.dart`・`record_export.dart` など)
- `lib/utils/day_key.dart` 記録の日の文字 `yyyy-MM-dd`
- `lib/views/` 画面(today・life・record・my_page・onboarding・tab・startup)。`lib/views/shared/` は色・文字・余白のトークンと共通の部品
- `lib/l10n/` 文言。`app_ja.arb` が元、`app_en.arb` が英語(`app_localizations*.dart` は生成物)
- `ios/LifeWidget/` ウィジェット拡張(Swift)。アプリとは App Group でデータを渡す
- `test/` 単体テスト / `integration_test/` シミュレーターで動かす結合テストと撮影(`store_shots_test.dart` など)
- `tools/` `check_ipa.sh`(本番のアーカイブにシミュレーター用が混ざっていないか)・`use_native_assets.sh`(sim と device の切り替え)・`shots.sh`(撮影の条件の2段)・`shots_copy.sh`(写しで撮る)
- `design/` 正本の文書: `design-system.md`(色・文字・余白)、`specs/`・`plans/`(v1.1 の設計と計画)、`checklists/`(実機の確認)、`store/`(ストアの文・Product Hunt・スクリーンショット)
- `docs/` 公開ページ(規約・プライバシーポリシー、日英)

## コマンド

- 検査: `flutter analyze`(警告0)
- テスト: `flutter test`
- 生成: `dart run build_runner build --delete-conflicting-outputs`(models を変えたとき)。Isar の生成は `build.yaml` で `lib/models/` だけに絞っている(isar_generator 3.1 は analyzer 5 で、Dart 3.8 以降の `?x` などを読めない)。`@collection` の型は `lib/models/` に置く
- 結合テスト・撮影: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<名前>.dart`
- 撮影の条件は2段(2026-10-18 本人の決定。3アプリ共通)。**毎回**(画面を直したら)= 昼夜・既定と最大の文字・iOS 27・ウィジェットの色合い → `tools/shots.sh every [テストの名前]`(昼夜は `--dart-define=THEME=dark`、最大の文字は `--dart-define=TEXT=max`。色合いはウィジェットを直したときにホーム画面を「色合い」にして手で撮る)。**出す前だけ**(審査に出す前)= iOS 26・SE・透明度を下げる・ロック画面 → `tools/shots.sh release`(透明度を下げるは Flutter に値が無いのでシミュレーターの設定で手で、ロック画面のウィジェットは無い)。既定(昼・既定の文字)の画像の名前は今のまま
- 直す前と後を並べて撮る・iPhone と iPad を同時に撮る・作業中の本体を動かさずに撮るときは、`tools/shots_copy.sh [--rev <コミット>] <画像の場所> <UDID> <テスト...> -- <flutter drive の引数>` で撮る。毎回 `mktemp -d` の新しい場所に写す。**同じ写しの場所に上書きして2回撮らない**(残った `build/`・`.dart_tool/`・`ios/Pods/` が前の回の pub-cache の場所と前の回のアプリを指したまま走り、直した後のつもりで直す前を撮った。10/23)。直す前は `--rev` か `git stash create` のコミットで固定する(撮っている間に本体を直しても混ざらない)
- シミュレーター用のビルド: `flutter build ios --simulator --no-codesign`
- 本番: `tools/use_native_assets.sh device` → `flutter build ipa` → `tools/check_ipa.sh`。シミュレーターに戻すときは `tools/use_native_assets.sh sim`
- flutter・dart はサンドボックスの中ではキャッシュに書けず止まる。このリポジトリの `.claude/settings.local.json` の `excludedCommands` は、リポジトリの中で起動したときだけ効く

## 変えてはいけないこと

1. 記録の日は `dayKey`(`yyyy-MM-dd`、その地域で見た日付)で持つ。時刻の一点(UTC)で日を決めない。タイムゾーンが変わっても同じ日は同じ文字(LC-23)
2. Bundle ID `com.lifecounter.lifeCounter`(拡張は `.LifeWidget`)と App Group `group.com.lifecounter.lifeCounter` は変えない。保存の型は足すだけにし、出荷済みの記録が読めなくならないようにする
3. 記録を開けないときに落とさない。説明と「もう一度試す」を出す(LC-24)
4. 書体はアプリに入れたものだけ。外のサーバー(Google Fonts など)から読まない。利用者のデータを端末の外へ送らない(ポリシーと合わせる)
5. ウィジェットには答えの文を渡さない
6. 画面のコードに色・文字・余白の値を直接書かない。`lib/views/shared/` のトークンと部品を使う(`design/design-system.md`)
7. 文言は ja と en の両方の arb に足す
8. `feature/family-v1.1` は中身が 2.0 系の別の線。`main` に合わせない(データが消える恐れ)
9. 問い合わせ先は `ryo.dev.app+lifecounter@gmail.com`(アプリ・同梱の規約・公開ページで同じ)

## 進め方

- 終わりの条件: `flutter analyze` でエラー0、`flutter test` が全部通る、触った画面はシミュレーターで撮って直す前と見比べる
- 見た目を変えるときは `design/design-system.md` を先に読む
- ストアの文・Product Hunt の文は content-writing スキルで書き、本人の OK をもらう
