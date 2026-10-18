---
name: ios-ui-rules
description: 3アプリ(ことばめくり・しずか・LifeCounter)共通の iOS の画面の決まり。画面・部品・ウィジェット・色・文字・余白を作る、直す、見直すときに使う。SwiftUI でも Flutter でも、見た目に触る変更の前に読み、「できた」と言う前に末尾の確かめを通す。アプリ固有の値(色・書体・余白の段・部品の一覧)は持たず、各アプリの design-system を指す。
when_to_use: 「画面を作って」「部品を足して」「ウィジェットを直して」「デザインを見直して」「色・文字・余白を変えて」「iOS 27 に合わせて」と言われたとき。View・Widget・Theme・design-system.md を書き換えるとき。
---

# iOS の画面の決まり(3アプリ共通)

正本は各アプリの文書。ここに無い値はそこから取る。**アプリの文書とぶつかったら、アプリの文書が勝つ**(決めた理由がそこにある)。

| アプリ | 値の正本 | 補い |
|---|---|---|
| ことばめくり(himekuri) | `Documentation/design-system.md` | `.claude/rules/design.md` |
| しずか(shizuka-home-app) | `docs/design/design-system.md` | `.kiro/steering/ui-inventory.md`・`visual-fidelity.md` |
| LifeCounter(life_counter、Flutter) | `design/design-system.md` | ― |

## 作る前

1. 部品の一覧(各 design-system の「部品」の節)に有るものを使う。無い部品は作らず、先に文書へ足す案を出す
2. 新しい色・余白・角・文字の値は、先に design-system に足してから使う。コードに16進・生の数を書かない

## 決まり

- **標準の部品を先に。** NavigationStack・toolbar・TabView・sheet・List・Form・標準のボタンとコントロールを使う。自作するときは理由を1行コメントに書く(アプリの顔の部分だけ)
- **ナビとツールバーに背景を付けない。** ガラス(Liquid Glass)は中身の上に浮かぶ操作の層だけ。中身の層には当てない。自作の部品に使うのは控えめに、複数なら `GlassEffectContainer`。Flutter ではガラスを自作でまねない(不透明な面と影にする)
- **色は役割の名前で呼ぶ。** 昼・夜の両方で文字のコントラストを確かめる(本文 4.5:1、18pt 以上・太字は 3:1)。色だけで意味を伝えない(文字か記号も添える)
- **文字は text style(Dynamic Type)に相対。** 最小 11pt(縮小後も)。**本文と操作は切らない**(スクロールする画面は折り返しで全文。一覧・ウィジェットは詳細で全文が読めるときだけ切ってよい)。アクセシビリティサイズでは横並びを縦に積む。`dynamicTypeSize` の上限は飾りの大きな数字と固定枠の記号だけで、本文・ボタンの文字には付けない(記号に付けるなら AX3 以上)。ウィジェットは AX2 まで。それより大きい文字は、タップで開くアプリの画面で全文。アプリが別に決めていれば、その決定と理由を design-system に書く
- **押せる範囲は 44×44pt 以上。** 記号だけのボタンには読み上げ名(`accessibilityLabel`/Flutter は `Semantics`)
- **動きは「視差効果を減らす」で止める**(`accessibilityReduceMotion`)。ガラスや半透明は「透明度を下げる」で不透明に変わっても読めること
- **ウィジェットは `widgetRenderingMode` で分ける。** 色合い・クリア(`.accented`)とロック画面(`.vibrant`)では系が色を塗り替える。テーマ色を塗るのは `.fullColor` のときだけ。画像は `.widgetAccentedRenderingMode(.accentedDesaturated)`(または `.desaturated`)、`.fullColor` は作品の画像だけ
- **日本語の組み方。** 言葉の途中で折り返さない。改行や約物の扱いはアプリの決まり(しずかの `PhrasedText` など)に従い、新しい自作の組版は足さない
- **OS の版で分けるときは `if #available` で両方を描く**(iOS 26 と 27)。配置の数値を固定せず、OS の変更を受け取れるようにする

## 「できた」の前に(確かめ)

撮影した画像を自分で開いて見る。言葉で「直った」と言わない。条件は3アプリ共通の撮影の条件(`~/Projects/playbook/drafts/screenshot-conditions-3apps.md`)に従い、少なくとも次を見る:

- 昼・夜/既定と最大の文字(`accessibility5`)/「透明度を下げる」/iOS 26 と 27/ウィジェットは色合い表示(`.accented`)も
- 直す前と後を同じ条件で撮って並べる
- 撮り方: ことばめくり `Tools/test.sh --render <出力先>`、しずか `make snap`(崩れは `make check-robust`)、LifeCounter `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<名前>.dart`

## 出典(Apple Human Interface Guidelines)

- Accessibility(押せる範囲 44×44pt、コントラスト、視差効果を減らす): https://developer.apple.com/design/human-interface-guidelines/accessibility
- Typography(最小 11pt、text style、大きい文字での切り詰めを減らす): https://developer.apple.com/design/human-interface-guidelines/typography
- Larger Text の評価基準(200% 以上、折り返しを切り詰めより先に、一覧は詳細で全文なら切ってよい): https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria
- Color(昼・夜・コントラストを上げるで確かめる、意味で呼ぶ色): https://developer.apple.com/design/human-interface-guidelines/color
- Materials(ガラスは操作の層だけ、中身の層に使わない、控えめに): https://developer.apple.com/design/human-interface-guidelines/materials
- Widgets(full color・accented・vibrant、フルカラーの画像は控えめに、色だけで伝えない): https://developer.apple.com/design/human-interface-guidelines/widgets
- Liquid Glass の採り入れ方: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

本体は `~/Projects/playbook/claude/skills/ios-ui-rules/`。各リポジトリの写しは直接直さず、本体を直してから写す。
