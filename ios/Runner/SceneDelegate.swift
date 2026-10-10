import Flutter
import SwiftUI
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // 開発用: -widgetPreview <page> で、ウィジェットの確認画面を出す
    let args = ProcessInfo.processInfo.arguments
    if let i = args.firstIndex(of: "-widgetPreview") {
      let page = i + 1 < args.count ? Int(args[i + 1]) ?? 0 : 0
      DispatchQueue.main.async {
        self.window?.rootViewController = UIHostingController(rootView: WidgetPreviewGrid(page: page))
      }
    }
  }
}
