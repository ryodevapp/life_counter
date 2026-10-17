# 1.1.1 の「このバージョンの最新情報」(本人 OK 10/19)

ブリーフ
- 誰に: LifeCounter を毎日使っていて、アップデートの通知から開いた人
- 持ち帰り: 記録は消えていない。日付のずれなど、困りうることが直った
- 事実の出所: life_counter `fix/1.1.1`(3f88521 日付・0469bdc ウィジェット(`maxPendingStampDays = 7`)・63743a5 開けないとき・a62542d 書体とライセンス)、`lib/l10n/app_ja.arb`・`app_en.arb`(retry・licenses・tabSettings)、`lib/models/stamp.dart`(スタンプ=気分)
- 書かないこと: 連絡先のメールの変更(使う人の困りごとではない)、Product Hunt、内部の仕組みの名前、以前の不具合の様子(「落ちていた」などは記録で確かめていない)
- 書体とライセンスの行は、使う人に関係が薄いので外した(本人 10/19)
- 照合役・読み手役(10/19)の指摘で直した: 「閉じてしまわず」を外す/ウィジェットの行を「記録に入る」に/書体とライセンスの行に使う人の得を足す/英語の7日の数え方

## 日本語

いくつかの不具合を直しました。これまでの記録は、そのまま残っています。
- 海外などで端末のタイムゾーンが変わっても、記録の日付がずれないようにしました
- 記録を開けないときに、案内と「もう一度試す」が出るようにしました
- 数日アプリを開かなくても、ウィジェットで選んだ気分が記録に入るようにしました(7日前の分まで)

## English (U.S.)

Bug fixes. All your past entries are still here.
- Entry dates no longer shift when your device's time zone changes, for example while traveling
- If your entries can't be opened, the app now shows a message and a "Try Again" button
- Moods you pick on the widget now make it into your entries even if you haven't opened the app for several days (up to 7 days back)
