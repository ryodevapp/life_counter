# 1.1.4 で変えるストアの文と画像(下書き・本人の確認待ち)

1.1.3 のあと、Product Hunt の後に出す版。提出するときに App Store Connect へ入れるものを1枚にまとめる。最新情報の正本は `whats-new-v1.1.4.md`。形は `store-changes-v1.1.3.md` にそろえた。

## どこが、いつ変えられるか

| 項目 | 1.1.4 で変えるか | メモ |
|---|---|---|
| プロモーションテキスト | 変えない | 「端末の中だけ」「Stays on your device」のまま。iPad とも合っている |
| 説明 | 変えない | 1.1.3 で「端末の中だけ」に直した文のまま(`listing-v1.1.0.md`) |
| キーワード | 変えない | LC-29 の試しの最中(公開から4週で見る。1回に1か所) |
| このバージョンの最新情報 | 変える | `whats-new-v1.1.4.md`(下書き) |
| スクリーンショット(iPhone) | 変えない | iPhone の見た目は、日本語の折り返しの位置のほかは 1.1.3 と同じ(e241c00: iPhone では幅の直しが効かない) |
| スクリーンショット(iPad 13インチ) | 差し替えをすすめる | 下の「iPad の画像」 |
| 審査メモ(App Review Information の Notes) | 1行目を 1.1.4 の中身に | 下の「審査メモ」 |

## 審査メモ(App Review Information → Notes)

英文は下書き(本人の確認待ち)。1.1.3 の下書きの2段目(導線)は同じ。1段目だけ 1.1.4 の中身に替える。

```
This update improves the layout on iPad: content now sits in a centered, readable-width column that widens with larger text sizes. It also fixes text that was cut off or broken mid-word at larger text sizes, including confirmation dialogs, the segmented control, and the calendar header. There are no new features or permissions.

No account or login is required. There are no in-app purchases, no ads, and no network access; all entries are stored only on the device. To reach the main screens, tap Get Started, pick any past birth date, tap Next on each of the next three screens, and choose Not Now on the last onboarding screen; the notification permission prompt appears only if you tap Turn On Notifications. Notifications are optional.
```

確かめた記録: 1段目は e241c00・22ebe05(iPad の幅 672、文字の倍率だけ広げる)、2133fea(答えの欄の案内の切れ)、60a00bd・222c729(確認の小窓・トースト・切り替え・カレンダーの見出し)。権限・通信は fix/1.1.3..feat/1.1.4 の差分で `ios/Runner/Info.plist`・`pubspec.yaml` の依存に通信・解析の部品が増えていない(足したのは文節を分ける `budoux_dart`。辞書はアプリに入れて読む)。2段目は 1.1.3 の下書きのまま(`store-changes-v1.1.3.md`、照合役 10/23)。

## iPad の画像

- 決まり(Apple「Screenshot specifications」、https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications): 「iPad (if your app supports iPadOS): At least one screenshot for iPad 13-inch display」「Required if app runs on iPad」。受け付ける大きさは 2064×2752・2048×2732(縦)ほか。11インチなどは 13インチから縮めて使われる
- このアプリは iPad に対応している(`TARGETED_DEVICE_FAMILY = "1,2"`)ので、13インチの画像は必須
- 今のストア: 公開の検索 API(`itunes.apple.com/lookup?id=6761015343`、10/23)で、日本・米国とも iPad の画像が5枚ずつ載っている(公開中は 1.1.2)。正本は `screenshots/{ja,en}-ipad13/1〜5.png`(2064×2752、10/17 f8928f3)
- 足りなくはないが、10/17 の画像は 1.1.4 より前の、画面いっぱいに横へ広がる iPad の見た目。1.1.4 では中身が真ん中の幅に集まるので、画像とアプリの見た目が変わる → 1.1.4 と一緒に差し替えるのをすすめる
- 撮り方(10/17 と同じ): `integration_test/store_shots_test.dart` を iOS 27 の iPad Pro 13-inch (M5) で日本語・英語(`--dart-define=LANG=en`)に撮る → 見出しを付けて合成(2064×2752、見出しは `listing-v1.1.0.md` のスクリーンショットの表の1〜5)→ 透明度なしの PNG に書き出す → App Store Connect の 1.1.4 の「iPad 13インチ」の欄で入れ替える(本人の手)
- 10/23 撮り直した(このブランチの別のコミット。前の画像は f8928f3 で戻せる): feat/1.1.4 を iOS 27 の iPad Pro 13-inch (M5) で store_shots_test(ja・en)→ 10/17 と同じ合成(見出しの文字・枠・影の大きさ)→ 2064×2752・透明度なし。今日の問いは撮った日(10/23)の問いになる(「今日、少しだけ丁寧にしたいことは何ですか？」に答え「実家の庭の草取り…」)。10/17 の画像も撮った日の問い(「一度は行ってみたい場所は？」)で、答えは同じ
