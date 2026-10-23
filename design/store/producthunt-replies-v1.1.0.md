# Product Hunt でよく来る質問への返事(v1.1.0 の下書き、LC-19)

- 当日(2026-10-24)に、質問に合わせて直してから返す。下書きをそのまま貼らない
- 名前を呼んでお礼を言い、すぐ答えに入る。長くても4〜5文
- 言わない言葉: death・countdown・dying。life expectancy は計算を聞かれたときだけ
- 票を頼まない。まだ決めていない機能を約束しない(yet・next version と言わない)
- iPad にも対応しているので、端末は device と言う(iPhone だけと言わない)
- 照合した記録: lib/utils/freq_label.dart(会う頻度と回数)、lib/services/life_calculator.dart・life_tables.dart(平均の出どころ)、lib/services/record_export.dart(書き出し)、lib/views/shared/app_text_styles.dart(大きな数字の書体はアプリに同梱。1.1.1 から)、assets/legal/privacy_policy_en.html(データ・通信・分析)、lib/services/question_bank.dart(日付ごとの問い)、ios/Runner.xcodeproj の TARGETED_DEVICE_FAMILY(iPhone と iPad)

## 1. Android 版はあるか

It's on iPhone and iPad only for now. I'd like to bring it to Android too. Most people in Japan use iPhones, so I started there, and I'll see how things go before adding Android.

## 2. データはどこに保存されるか / 同期やバックアップは

Everything you write stays on your device. There's no account and no server, and the app has no analytics or ads. If you want a copy, Settings > Export Journal turns your entries and bucket list into plain text that you can save to Notes or send by email. There's no sync between devices right now.

(「ネットにはつながるのか」と聞かれたら、次を足す。1.1.1 で書体をアプリに入れ、Google Fonts へ取りに行かなくなった ── a62542d・LC-18。`lib/` に通信の処理と通信のパッケージは無い。10/19 に確かめた)
The app doesn't connect to any server. Even the font for the large numbers is built into the app.

(バックアップ・機種変更を聞かれたら §10 で答える。ここでは触れない)

## 3. 会える回数はどう出しているか

It's a rough estimate from averages, not a prediction. The app looks up the average years ahead for someone your age and for someone your parent's age, using life tables for the region your device is set to (Japan's official tables, or WHO data elsewhere). It takes the shorter of the two and multiplies it by how often you meet. So if you see each other once or twice a year and the shorter average is 20 years, it shows about 40 visits.

## 4. 会える回数を出すのは、つらくならないか

I see my parents about once a year. When I first saw the number for them, my honest thought was: that's not many. That's what made me want to plan the next trip home. So on each person's card, the big number is visits, not years. It only appears in the Life tab, under People who matter. The morning notification and the widget show the day's question, never the visits.

## 5. 無料で続けられるのか

It's free, with no ads and no subscription. I build it on the side, and since nothing runs on a server, keeping it going doesn't cost much beyond my own time.

## 6. 問いは選べるか / 自分で作れるか

There's one question for each day of the year, 365 in all, so everyone gets the same question on the same date. You can't pick or write your own right now. If you skip a day, that's fine. Tomorrow just brings a new one.

## 7. AI を使っているか

No, there's no AI inside the app. Nothing you write leaves your device unless you export it yourself.

(「作るのに AI を使ったか」「問いや英訳は AI か」と聞かれたら)
Yes, of course. I build the app with Claude Code, and the English questions were translated from my Japanese ones with AI. If any of them read oddly, please tell me.

## 8. 機能の要望をもらったとき

(要望の中身に一言触れてから) I've noted it, and I'll think about it for a future update.

## 9. iPad で使えるか

(10/23 に足した。照合: ios/Runner.xcodeproj の TARGETED_DEVICE_FAMILY = "1,2"、iTunes の lookup で iPad が対応端末に入っている。公開中の 1.1.2 は iPad で中身が横いっぱいに広がる。読みやすい幅に寄せる直し LC-15 はまだ出ていないので、出るとは言わない。ウィジェットは iPad の実機で確かめていない・iOS 17 以上が要るので、聞かれるまで触れない)
Yes, it runs on iPad too. The layout was designed for iPhone first, so on a big screen the content stretches wide. Your iPhone and iPad keep separate journals, since nothing syncs between devices.

## 10. 新しい端末へ移せるか / 機種変更でデータは残るか

(10/23 に足した。照合: lib/main.dart は記録を getApplicationDocumentsDirectory に置き、バックアップから外す設定は無い。iOS は Documents を iCloud とコンピュータのバックアップに含める。LC-21(68a8f22、10/23)で、バックアップの対象の所だけを別のシミュレーターへ写して開き、記録・設定・ウィジェットのスタンプがそろうのを確かめた(iOS 27.0・iPhone 17 Pro 2台)。実機での復元は本人も AI もまだ試していないので「should」までにし、シミュレーターでだけ確かめたと言う(10/24 に直した)。書き出しはファイルを作らず、テキストを共有シートに渡す(my_page.dart の _exportRecords)。中身は答え・気分・感謝・ふりかえりなどの記録とやりたいことで、大切な人のカードは入らない。読み込みの機能は無い。照合役・読み手役 10/23 の指摘で、file→text、iPhone→device、バックアップが入っているときだけ、に直した)
Yes, it should. Your entries are saved on your device, and iOS includes them in iCloud and computer backups when those are on. So restoring a backup, or setting up a new device with Quick Start, should bring your entries along. In a test, I copied the data iOS backs up from one simulated iPhone to another, and everything showed up. I haven't done a real restore on a phone, though, so it's worth keeping a copy too: Settings > Export Journal turns your entries, moods, and bucket list into plain text. That text is a copy for you to keep, and the app can't import it back.

## 11. ダウンロードのリンクを聞かれたら

Product Hunt のメインの URL は計測なし(decisions 2026-10-19。Product Hunt は計測つきの URL を受け付けない)。コメントでリンクを貼るときだけ、計測つきのこちらを使う(10/23 に開くのを確かめた。App Store Connect の「キャンペーン」に producthunt で出る。初回の DL が5人に届くまで画面に出ない)。
It's free on the App Store for iPhone and iPad: https://apps.apple.com/us/app/lifecounter-question-journal/id6761015343?pt=375608344&ct=producthunt&mt=8

## 12. 人生◯日目が1日ずれている / 旅行したら日数が変わった

(10/24 に足した。照合: 公開中の 1.1.2 は誕生日を「時刻の一点」(ミリ秒)で持つ ── lib/providers/user_settings_provider.dart の setBirthDateAndGender。入れたときより西の時間帯で開くと誕生日が1日前に見え、日数が1日多くなることがある(ずれは時差の分の時間なので、1日のうちの一部の時刻だけ。照合役 10/24)。大切な人の誕生日・最後に会った日も同じ。LC-30 の試験で、東京で 1990-01-01 を入れてニューヨークで開くと 1989-12-31 に見えた(03ec57d)。直しは fix/LC-30 にあるが出ていないので、直ると言わない(next version と言わない)。設定 > 誕生日で日付を選び直すと、今の時間帯の 0:00 で保存し直すので戻る ── my_page.dart の _editBirthDate。数え方の話(生まれた日が Day 1。life_calculator.dart の lifeDays は +1)なら、ずれではないので謝らず、全体を次の注の文に替える)
Thanks for catching this, and sorry about that. If you entered your birthday in one time zone and your device is now set to one further west, the app can show your birthday a day early, and the day count can be one too high. Re-picking your date of birth in Settings saves it for your current time zone and fixes the count. Dates for the people you've added under People who matter can shift the same way, and re-picking their birthday or last-met date fixes those too.

(数え方を聞かれたとき、全体をこれに替える)
Good question. The day you were born counts as Day 1, so the number is one higher than the days that have passed since then.

