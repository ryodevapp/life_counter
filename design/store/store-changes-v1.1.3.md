# 1.1.3 で変えるストアの文(説明と最新情報は 10/23 本人決定。審査メモは下書き)

LC-28。1.1.3 を提出するときに App Store Connect へ入れるものを1枚にまとめる。正本は `listing-v1.1.0.md`(掲載文)と `whats-new-v1.1.3.md`(最新情報)。説明と最新情報は 10/23 午後に本人が決め、正本へ移した。App Store Connect へは提出のときに入れる。

## どこが、いつ変えられるか

| 項目 | 審査なしで今すぐ変えられるか | メモ |
|---|---|---|
| プロモーションテキスト | 変えられる(版の出し直しも審査も要らない) | 今の文は「端末の中だけ」「Stays on your device」で、iPad と合っている。変えない |
| 説明 | 変えられない(新しい版と一緒に審査) | 案A を `listing-v1.1.0.md` に入れた(10/23 本人決定) |
| キーワード | 変えられない(版と一緒) | LC-29 の入れ替え済み。1.1.3(提出準備中)に保存済み(10/23 Jira LC-29) |
| このバージョンの最新情報 | 変えられない(版と一緒) | `whats-new-v1.1.3.md`。起動画面の1行を足した(10/23 本人決定、案1) |
| 名前・サブタイトル・スクリーンショット | 変えられない(版と一緒) | 1.1.3 では変えない(LC-29「1回に1か所」) |
| 審査メモ(App Review Information の Notes) | 提出のときに書く欄(審査に読ませるもの) | 下の「審査メモ」 |

## 説明の直し(iPad に対応しているのに「iPhone の中だけ」と書いている)

アプリは iPhone と iPad の両方に対応している(`TARGETED_DEVICE_FAMILY = "1,2"`)。アプリの中の文は 1.1.3 で「この端末」「this device」に直した(e51b890)。ストアの説明だけ「iPhone」が残っている。

日本語(「▼ 記録は端末の中だけ」の節の1文目)
- 今: すべての記録はお使いの iPhone の中だけに保存されます。
- 案A(おすすめ・10/23 本人決定、正本へ反映済み): すべての記録はお使いの端末の中だけに保存されます。
- 案B: すべての記録はお使いの iPhone・iPad の中だけに保存されます。

English(PRIVATE BY DESIGN の1文目)
- 今: Everything stays on your iPhone.
- 案A(おすすめ・10/23 本人決定、正本へ反映済み): Everything stays on your device.
- 案B: Everything stays on your iPhone or iPad.

おすすめは A。アプリの中の文(「この端末」「this device」)、プロモーションテキスト(「端末の中だけ」「Stays on your device」)、節の見出し(「記録は端末の中だけ」)と同じ言葉になる。B は機種がはっきりするが、見出しと言葉がずれる。字数は ja 713→707 字(案Bは約718字)、en 1508 字のまま(上限 4000)。

## 最新情報に足すか(本人 OK のあとに入った2つ)

`whats-new-v1.1.3.md` を本人が OK した(10/21)あとに、fix/1.1.3 へ2つ入った。
- e51b890 はじめての案内の「この iPhone」→「この端末」: 今の「画面のいくつかの言い回しを見直しました」に含まれる。足さなくてよい
- 441f157 LC-14 起動画面を、アイコンの砂時計と昼夜の地の色にした(前は白の固定で、暗い表示では白く光ってから暗い画面に変わっていた)

案1(おすすめ・10/23 本人決定、`whats-new-v1.1.3.md` へ反映済み): 「そのほか」に1行足す。目に見える変わり方なので、書いたほうが「何が変わった?」に答えられる
- 日本語: 起動するときの画面を、暗い表示でも白く光らないようにしました
- English(箇条の下に別の1行で。箇条は「最大の文字の人向け」なので混ぜない): Also, the launch screen now follows dark mode instead of flashing white.
案2: 足さない(今の OK 済みの文のまま)

## 審査メモ(App Review Information → Notes)

英文は下書き(本人の確認待ち)。

記録に LifeCounter の審査メモは無い。App Store Connect は前の版の欄を引き継ぐので、提出の前に中身を見て、空か古ければ下を入れる。

```
This update fixes text that was cut off or split mid-word at the largest text size, rewords a few labels, and updates the launch screen to match dark mode.

No account or login is required. There are no in-app purchases, no ads, and no network access; all entries are stored only on the device. To reach the main screens, tap Get Started, pick any past birth date, tap Next on each of the next three screens, and choose Not Now on the last onboarding screen; the notification permission prompt appears only if you tap Turn On Notifications. Notifications are optional.
```

確かめた記録: pubspec.yaml に課金・通信・解析の部品が無い、`docs/privacy_policy*.html`(外部と通信しない)、`lib/views/onboarding/onboarding_page.dart`(Get Started → 生年月日 → Next を3回(birth・lifeDays・daysAhead)→ 通知の画面で Not Now を選ぶと主な画面。許可を求めるのは Turn On Notifications を押したときだけ)。照合役(content-checker、10/23)の指摘で「adds」→「updates」、導線を具体に直した。

## ついでに見つけたこと

- (10/23 直した)`listing-v1.1.0.md` の冒頭の注に「キーワード欄に『日記』を入れる」とあるが、LC-29 で「日記」は外した。注が古い(直すなら1行)。同じ注の「キーワード欄に『平均寿命・寿命』だけ残す」も、今の欄(親・残り時間の語を足した)と合わせて書き直す
