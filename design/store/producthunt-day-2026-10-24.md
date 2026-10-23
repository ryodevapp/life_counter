# Product Hunt 当日の段取り(2026-10-24 土、LC-2・LC-11)

本人の手は3つだけ: **①出たのを確かめる(出ていなければ押す) ②最初のコメントを差し替える ③返信の下書きに OK を出す**。ほかは Claude(~/Projects の会話、Chrome)がやる。票は頼まない。Product Hunt の1日は太平洋時間の 0:00〜23:59 = **日本時間 10/24 16:01 〜 10/25 15:59**。

## 前日(10/23)に確かめたこと

- ストア: 日米とも **1.1.2**(2026-10-20 16:51 UTC 公開)、無料、言語は EN・JA、iPhone と iPad(iTunes lookup、apps.apple.com の日米のページ)。1.1.3 は未公開
- 紹介文(producthunt-v1.1.0.md、ea1a74f の版)の事実は今のストアと合う(1日1問と follow-up・気分・月のふりかえり・1年前の今日・やりたいことと達成日・中サイズのウィジェットで気分・外とつながない・無料で広告なし・日本語は3月から(lookup の releaseDate 2026-03-24)・英語は今週(1.1.0、10/19))。1.1.2 の2行を足す条件は満たした
- リンク: 公開のページ https://www.producthunt.com/products/lifecounter 、US のストア(計測なし、メインの URL)、計測つき `ct=producthunt`(返しの下書き §11)の3つとも 200 で開く
- 返しの下書き(producthunt-replies-v1.1.0.md)は §1〜11。よく来る質問のうち、プライバシー §2・Android §1・価格 §5・iPad §9・データの移行 §10 を覆う

## 時刻ごと

| 日本時間 | 誰 | すること |
|---|---|---|
| 10/24 15:45 | Claude | iTunes lookup で版を見直す(1.1.3 が出ていても下の差し替えのまま)。Chrome で準備の画面 https://www.producthunt.com/products/lifecounter/lifecounter/prelaunch の予約が 10/24 のままか見る |
| 16:01 | **本人** | 公開のページを開き、出ているか見る。16:10 になっても出ていなければ、準備の画面で公開を押す(①) |
| 16:05 | **本人** | 最初のコメントを開き、「Also inside」の3行を下の4行に差し替えて保存。最初のコメントが出ていなければ、下の全文を貼る(②) |
| 16:05〜25:00 | Claude | 30分ごとにコメントを読み、返しの下書き(§1〜11 を質問に合わせて直す。名前を呼んでお礼→答え、4〜5文)を本人に見せる。本人の OK のあと Claude が Chrome で返す(③) |
| 22:00〜翌3:00 | Claude | 米国の朝〜昼で、コメントが最も来る時間。15分ごとに見る。本人が寝ている間に来たものは下書きをためておき、朝にまとめて OK をもらう |
| 10/25 朝 | sns(承認済み) | LifeCounter の回の最後の返信が Product Hunt のページへ(10/19 の決定。票は頼まない) |
| 10/25 07:00〜15:59 | Claude・**本人** | たまった返しに OK → Claude が返す。全部のコメントに答える |
| 10/25 16:00 | Claude | 順位・票・コメント数・フォローを Jira LC-11 に書く |
| 10/27 ごろ | Claude | App Store Connect で米国の製品ページの表示・DL、流入元(ウェブ)、キャンペーン producthunt を見て LC-11 に書く(帰属は初回の DL が5人に届くまで出ない) |
| 10/31 | 本人 | 英語のコメント数などで、英語の場所を続けるか決める(decisions 2026-10-20) |

## ② の差し替え(コピーして貼る)

「Also inside」の行を次の4行にする(下書きの末尾の指示を当てた形):

```
Also inside:
- Your mood in one tap, a monthly look-back, and "a year ago today"
- A bucket list, with the date you achieved each one
- A Home Screen widget for today's question, with a one-tap mood in the medium size. The Write button and mood faces now stay visible on Tinted and Clear Home Screens
- Screens that still fit at the largest text size
```

最初のコメントが出ていなかったときの全文は producthunt-v1.1.0.md の「First comment」に、上の4行を当てたもの。

## してはいけないこと

- 票を頼む・「upvote」と書く。前日の告知(しない、と決めた)
- まだ決めていない機能を約束する(yet・next version と言わない。iPad の読みやすい幅 LC-15・同期・Android も同じ)
- 返しの下書きをそのまま貼る(質問に合わせて直す)
