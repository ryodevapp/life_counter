# 新しい iPhone に移したときの確認(LC-21)

記録が「iCloud バックアップからの復元」「クイックスタート(iPhone から直接転送)」で新しい iPhone に移るかを確かめた結果と、本人が実機で確かめる手順。

## どこに何があり、移るか(2026-10-23 調べ)

| データ | 置き場所 | バックアップ・転送 | 出典・確かめ |
|---|---|---|---|
| 記録・大切な人・やりたいこと(Isar) | アプリの `Documents/default.isar`(`lib/main.dart` の `_openIsar`) | 移る | Apple「File System Programming Guide」: Documents は "backed up by iTunes and iCloud"。`tools/lc21_transfer.sh` で確かめた |
| 設定(誕生日・性別・通知の時刻・夜の画面の時刻・移行の印) | UserDefaults(`Library/Preferences/com.lifecounter.lifeCounter.plist`、shared_preferences) | 移る | 同ガイド: Library/Preferences は "backed up by iTunes and iCloud"。同じ試験で確かめた |
| ウィジェットで押して、まだアプリに取り込んでいないスタンプ・ウィジェットに渡す日ごとの表示 | App Group の UserDefaults(`group.com.lifecounter.lifeCounter`) | 移る見込み。表示はアプリを開くたびに作り直すので、移らなくても困らない | Apple の文書には明記が無い。Apple の DTS の回答(developer.apple.com/forums/thread/693766)は「含まれる」。取り除いた(オフロードした)アプリでは戻らなかった報告あり(thread/95343)。シミュレーターでは写して取り込めることを確かめた |
| 朝の通知の予約 | iOS の通知の予約 | 移ることを当てにしない | アプリを開くたびに予約し直す(`main_tab_view.dart` の `NotificationService.refresh`) |
| Keychain・Caches・tmp | 使っていない | — | `lib`・`ios/Runner`・`ios/LifeWidget` と使っている部品(isar・path_provider・shared_preferences・home_widget・flutter_local_notifications)に `isExcludedFromBackup`・Keychain の呼び出しは無い |

- Apple「Optimizing your app's data for iCloud backup」: `tmp` と `Library/Caches` は "iCloud Backup excludes them by default"。`isExcludedFromBackup` を立てたものも外れる。このアプリはどちらも使っていない
- Keychain の `…ThisDeviceOnly` は「新しい端末へ移らない」(Apple の `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)。このアプリは Keychain を使っていないので当たらない

## 移ったあと最初に開いたとき

1. iOS はアプリとそのデータを戻してからアイコンを使えるようにする。開くと `_openIsar` が Documents の記録を開く
2. 開けなければ(壊れた・途中など)落とさずに「もう一度試す」の画面(LC-24、`lib/views/startup/data_open_error_app.dart`)
3. 開けたら、移行の印が移っているので dayKey の移し替えは走らない(印が無い古い版からでも、走って1回で済む)
4. いつもの画面が出て、ウィジェットに残っていたスタンプを取り込み、通知を予約し直す

## 気をつける所(直していない)

- **誕生日は「時刻の一点」(ミリ秒)で持っている**(`PrefsKeys.birthDate`)。移した先の iPhone の時間帯が西にずれると(例: 日本で入れて、アメリカで使う)、誕生日が1日前に見え、「人生◯日目」が1日増える。大切な人の誕生日・最後に会った日(Isar の `DateTime`)も同じ。バックアップの問題ではなく時間帯の問題(LC-23 の続き)。記録の日は `dayKey` なので当たらない

## 本人が実機で確かめる手順(約20分。iPhone が2台あるとき)

1. 古い iPhone で: 今日の答えを書き、スタンプを押し、人生タブで大切な人とやりたいことを1つずつ足す。中のウィジェットでスタンプを1つ押し、アプリは開かない
2. 設定 → 自分の名前 → iCloud → iCloud バックアップ →「今すぐバックアップを作成」
3. 新しい iPhone(または初期化した iPhone)の設定で「iCloud バックアップから復元」を選ぶ(クイックスタートの「iPhone から転送」でもよい)
4. 新しい iPhone で LifeCounter のアイコンが使えるようになったら開く
   - はじめての画面ではなく、今日タブが出る
   - 1 の答え・スタンプ(ウィジェットで押したもの)・大切な人・やりたいこと・記録タブの過去の記録がそろう
   - マイページの誕生日・通知の時刻が同じ
5. ホーム画面にウィジェットを置き直し、人生◯日目が古い iPhone と同じ
6. 翌朝、通知が届く(届かなければ、設定 → 通知 → LifeCounter で許可を確かめる)

## シミュレーターでの確かめ(AI)

`tools/lc21_transfer.sh <元の UDID> <先の UDID>`。元で `integration_test/backup_restore_test.dart` を `LC21_PHASE=write` で動かして書き、元を止めて、アプリのデータと App Group の入れ物から Library/Caches・tmp を除いて(バックアップの対象の所だけ)別のシミュレーターへ写し、先で `LC21_PHASE=verify` で本物の `main` から開いてそろうかを見る。空のシミュレーターを2台作って渡す(中身を上書きする)。

2026-10-23 の結果(iOS 27.0・iPhone 17 Pro を2台、`feat/1.1.4` の 1080fed の上): 通った(`LC21_OK`)。

- 元のアプリのデータ: `Documents/default.isar`・`default.isar.lock`・`Library/Preferences/com.lifecounter.lifeCounter.plist`(ほかは iOS の画面の控え)。App Group: `Library/Preferences/group.com.lifecounter.lifeCounter.plist`
- バックアップから外す印が付いていたのは `Library/Caches/flutter_callback_cache.json`(通知の部品の控え。作り直されるので困らない)だけ
- 先では、開けない画面・はじめての画面は出ず、いつもの画面。今日・昨日・400日前の答え、大切な人、やりたいこと、誕生日・夜の画面の時刻がそろい、ウィジェットで押したスタンプ(App Group)も今日の記録に取り込まれた
