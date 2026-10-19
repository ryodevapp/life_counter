# 1.1.2 の「このバージョンの最新情報」

ブリーフ
- 誰に: LifeCounter を使っていて、アップデートの通知から開いた人。ホーム画面を「色合い調整」「クリア」にしている人、文字を大きくしている人
- 持ち帰り: 自分の設定のままで見やすくなった。評価のお願いはしつこく出ない。外へは何も送っていない
- 起こしたい感情: 安心(押し付けない・外へ送らない)
- 1行目の案: ①「ホーム画面の見た目や文字の大きさを変えている方にも、見やすくなりました。」②「いくつかの改善をしました。」③「このアプリは外部と通信しません。」→ ①を「…方に向けて、表示を直しました。」に言い換えて使う(本人 10/19。2つの主な変更を、使う人の設定の話として1つにまとめられる。③は今回の動きの変更ではない)
- 事実の出所: 84c13c6(ウィジェットの色合い・クリア表示。`ios/LifeWidget/WidgetShared.swift`)、c6af396・db4cbdb(いちばん大きい文字のはみ出し)、9ae86eb と `lib/services/review_prompt.dart`(`answeredDaysToAsk = 7`、1回だけ)、`assets/legal/privacy_policy*.html` の6節(10/19 に書き直し)
- 照合役・読み手役(10/19)の指摘で直した: 「はみ出さない」→「収まるように」(確かめたのは例外0と画像)/「見分けられる」→「はっきり見える」/評価は「出す」でなく「お願いする」側の言い方に、7日は「合わせて」/1行目が上2行だけの話なので、残り2つを「そのほか」に分けた/英語の communicate・our を外した
- iOS の表記: 日本語は「色合い調整」「クリア」、英語は Tinted・Clear(iOS 26.5 と 27.0 のシミュレーターの PosterUIFoundation の文言で確かめた 10/19)
- 書かないこと: 撮影の段取り・in_app_review などの内部の名前、Product Hunt、以前の不具合の様子

## 日本語

ホーム画面の見た目や文字の大きさを変えている方に向けて、表示を直しました。
- ホーム画面を「色合い調整」や「クリア」にしていても、ウィジェットの「書く」ボタンと気分の顔がはっきり見えます
- 文字をいちばん大きくしても、各画面が収まるように直しました

そのほか
- 評価のお願いは、答えを書いた日が合わせて7日になったときの1回だけにしました
- このアプリは外部のサービスと通信しません。プライバシーポリシーにも、そう書いてあります

## English (U.S.)

Display fixes for anyone who has customized their Home Screen or text size.
- The widget's Write button and mood faces are now clearly visible when your Home Screen is set to Tinted or Clear
- Screens now fit even at the largest text size

Also
- The app now asks for a rating only once, after you've answered on 7 different days
- The app doesn't connect to any outside services, and the Privacy Policy now says so
