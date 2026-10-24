# 1.1.5 で変えるストアの文と画像(下書き・本人の確認待ち)

1.1.4 が通ったあとに出す版(本人の決定 10/24 午後: 10/25 に 1.1.3 → 通ったらすぐ 1.1.4 → そのあと 1.1.5)。中身は「日付が地域でずれない」直しだけで、文言・見た目は変えない。最新情報の正本は `whats-new-v1.1.5.md`。形は `store-changes-v1.1.4.md` にそろえた。

## どこを変えるか

| 項目 | 1.1.5 で変えるか | メモ |
|---|---|---|
| プロモーションテキスト | 変えない | 1.1.4 のまま |
| 説明 | 変えない | 1.1.4 のまま(`listing-v1.1.0.md`) |
| キーワード | 変えない | LC-29 の試しの最中(1回に1か所) |
| このバージョンの最新情報 | 変える | `whats-new-v1.1.5.md`(下書き) |
| スクリーンショット(iPhone・iPad) | 変えない | 画面の見た目は 1.1.4 と同じ(`feat/1.1.4..release/1.1.5` で `lib/l10n`・`lib/views/shared` に差が無い) |
| 審査メモ(App Review Information の Notes) | 1段目を 1.1.5 の中身に | 下の「審査メモ」 |

## 審査メモ(App Review Information → Notes)

英文は下書き(本人の確認待ち)。2段目(導線)は 1.1.4 の下書きと同じ。1段目だけ 1.1.5 の中身に替える。

```
This update fixes dates that could appear one day off in some time zones: birth dates, and day counts during daylight saving time. On the first launch after updating, each saved birth date and last-met date is also stored in year-month-day form. The original values are kept, and no saved data is deleted. There are no new features, screens, or permissions.

No account or login is required. There are no in-app purchases, no ads, and no network access; all entries are stored only on the device. To reach the main screens, tap Get Started, pick any past birth date, tap Next on each of the next three screens, and choose Not Now on the last onboarding screen; the notification permission prompt appears only if you tap Turn On Notifications. Notifications are optional.
```

確かめた記録: 1段目は 18b7618(誕生日・大切な人の日付を `yyyy-MM-dd` で持つ。起動時に移し、古い値は消さずに残す。移せなかったときは印を付けず次の起動でやり直す `migrateBirthDayKeysOnce`)・38adde6(夏時間の深夜0時台の日数)。権限・通信は `git diff feat/1.1.4..release/1.1.5 -- ios pubspec.yaml` が版の1行だけ(10/24)。2段目は `store-changes-v1.1.4.md` のまま。照合役(10/24)の指摘で、「converted once」「entries」(この画面では日々の記録を指す)を、古い値を残す・誕生日と最後に会った日だけ、が分かる文に直した。
