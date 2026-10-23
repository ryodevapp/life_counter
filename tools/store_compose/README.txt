ストアのスクリーンショットの合成(見出し+角丸の画面+影)。10/17 に作った道具が一時フォルダにしか無く、
1.1.4 の撮り直しで会話の記録から戻した(10/23)。

1. 撮る: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/store_shots_test.dart -d <UDID> [--dart-define=LANG=en]
   (画像は SCREENS_DIR か build/screens の store_<ja|en>_<番号>_<名前>.png)
2. 組み立て: xcrun swiftc -O tools/store_compose/compose_ipad13.swift -o <一時フォルダ>/compose
   (iPhone 6.9 インチは compose_iphone69.swift。見出しの文は design/store/listing-v1.1.0.md のスクリーンショットの表)
3. 合成: <compose> <入力png> <出力フォルダ>/<番号>.png "<見出し>" "<小見出し>" <ja|en>
4. 透明度を外す: xcrun swift tools/store_compose/flatten.swift <出力フォルダ> <design/store/screenshots/…> <幅> <高さ>
   (iPad 13 は 2064 2752、iPhone 6.9 は 1320 2868。App Store Connect は透明度のある画像を受け付けない)
