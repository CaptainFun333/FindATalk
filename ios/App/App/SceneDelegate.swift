import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CAPBridgeViewController()
        window?.makeKeyAndVisible()

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // This scheme (registered in Info.plist's CFBundleURLTypes) has no
        // other caller — it only ever arrives here from the "Talk of the
        // Day" widget's widgetURL() tap (see TalkOfDayWidget.swift), so any
        // open through it always means "reset to Home" (see
        // goToHomeScreen() in docs/index.html). Backgrounding the app
        // doesn't reload the WebView — it just suspends it — so without
        // this the app resumes exactly wherever it was left instead of
        // going to Home like the widget promises. Only handles the
        // already-running case (this delegate method, not a cold launch
        // via connectionOptions.urlContexts in willConnectTo above): a
        // cold start already opens fresh on Home with no stale state to
        // reset, so there's nothing to do there.
        if URLContexts.first?.url.scheme == "com.captainfun333.findatalk",
           let bridgeVC = window?.rootViewController as? CAPBridgeViewController {
            bridgeVC.webView?.evaluateJavaScript("window.goToHomeScreen && window.goToHomeScreen();")
        }
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }
}
