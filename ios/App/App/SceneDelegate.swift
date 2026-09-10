import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let bridgeVC = CAPBridgeViewController()
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = bridgeVC
        window?.makeKeyAndVisible()

        addEdgeSwipeBackGesture(to: bridgeVC)

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    /// Idea 60, Path A: a left-edge swipe navigates back one level, same
    /// as Android's hardware/gesture back button (idea 59) — but through
    /// a native gesture recognizer calling the *same* JS logic
    /// (`stepBackOneLevel()`, exposed as `window.handleEdgeSwipeBack` in
    /// docs/index.html) rather than WKWebView's own
    /// `allowsBackForwardNavigationGestures`. That built-in gesture only
    /// walks real `history.pushState`/`popstate` entries, and this app
    /// has none — zones are plain JS/CSS state — so it would have nothing
    /// to navigate through even if enabled. Deliberately does NOT mirror
    /// idea 59's "exit the app" terminal case: an edge swipe with nothing
    /// left to back out of should just do nothing on iOS, not quit —
    /// unlike a hardware back button, that's not what the gesture means
    /// to an iOS user, so `handleEdgeSwipeBack`'s return value is ignored
    /// here on purpose.
    private func addEdgeSwipeBackGesture(to bridgeVC: CAPBridgeViewController) {
        let recognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipeBack(_:)))
        recognizer.edges = .left
        // WKWebView's own scroll-view pan gesture lives on the same view;
        // without this the two compete and the edge swipe can get
        // swallowed instead of recognized.
        recognizer.delegate = self
        bridgeVC.webView?.addGestureRecognizer(recognizer)
    }

    @objc private func handleEdgeSwipeBack(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let bridgeVC = window?.rootViewController as? CAPBridgeViewController {
            bridgeVC.webView?.evaluateJavaScript("window.handleEdgeSwipeBack && window.handleEdgeSwipeBack();")
        }
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

extension SceneDelegate: UIGestureRecognizerDelegate {
    // Lets the edge-swipe recognizer and the WKWebView's own scroll-view
    // pan gesture both recognize at once, the same way a
    // UINavigationController's interactive-pop gesture coexists with
    // scrolling — without this, whichever the webview claims first can
    // swallow the swipe before it reaches ours.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
