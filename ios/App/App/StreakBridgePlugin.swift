import Foundation
import Capacitor
import WidgetKit

/// Tiny custom plugin whose only job is getting the streak from the
/// WebView's localStorage into somewhere TalkOfDayWidgetExtension can
/// actually read. WKWebView storage and a widget extension are fully
/// sandboxed from each other — the only thing they can share is an
/// explicit App Group container — and @capacitor/preferences doesn't
/// support that on iOS (its "group" option only prefixes keys within
/// UserDefaults.standard, which the extension still can't see). Hence a
/// dedicated plugin instead of a generic one.
///
/// Requires the App Group capability enabled in Xcode on BOTH this
/// target (App) and TalkOfDayWidget, with the same group ID as
/// `appGroupID` below — a manual, one-time signing step (see
/// PROJECT_HANDOFF.md). Until that's done, `UserDefaults(suiteName:)`
/// below just returns nil and this silently writes nowhere; the app
/// still works, the widget just never shows a streak.
@objc(StreakBridgePlugin)
public class StreakBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StreakBridgePlugin"
    public let jsName = "StreakBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setStreak", returnType: CAPPluginReturnPromise)
    ]

    // Must match the group ID entered under Signing & Capabilities ->
    // App Groups on both the App and TalkOfDayWidget targets, and the
    // suiteName TalkOfDayWidget.swift reads from.
    static let appGroupID = "group.com.captainfun333.findatalk"
    // Must match STREAK_KEY in docs/index.html.
    static let streakKey = "findATalkStreak"

    // Must match the `kind` in TalkOfDayWidget.swift.
    static let widgetKind = "TalkOfDayWidget"

    @objc func setStreak(_ call: CAPPluginCall) {
        guard let json = call.getString("json") else {
            call.reject("Missing json")
            return
        }
        UserDefaults(suiteName: StreakBridgePlugin.appGroupID)?.set(json, forKey: StreakBridgePlugin.streakKey)

        // Writing to UserDefaults alone doesn't repaint an already-placed
        // widget — WidgetKit only re-renders on its own schedule (see the
        // `.after(startOfTomorrow)` policy in TalkOfDayWidget.swift)
        // unless told to reload now. Without this, a streak advance made
        // mid-day just sits unseen on the widget until the next midnight
        // reload.
        WidgetCenter.shared.reloadTimelines(ofKind: StreakBridgePlugin.widgetKind)

        call.resolve()
    }
}
