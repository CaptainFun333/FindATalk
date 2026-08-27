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
        CAPPluginMethod(name: "setStreak", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setThemePreference", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPalettePreference", returnType: CAPPluginReturnPromise)
    ]

    // Must match the group ID entered under Signing & Capabilities ->
    // App Groups on both the App and TalkOfDayWidget targets, and the
    // suiteName TalkOfDayWidget.swift reads from.
    static let appGroupID = "group.com.captainfun333.findatalk"
    // Must match STREAK_KEY in docs/index.html.
    static let streakKey = "findATalkStreak"
    // Must match the native-mirror key mirrorThemeToNative() writes to
    // in docs/index.html.
    static let themeKey = "findATalkTheme"
    // Must match the native-mirror key mirrorPaletteToNative() writes to
    // in docs/index.html.
    static let paletteKey = "findATalkPalette"

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

    /// Mirrors an explicit light/dark choice from the in-app toggle so the
    /// widget can match it instead of always following the system-wide
    /// setting. Despite the plugin's name (kept as-is to avoid the native
    /// project-file churn of registering a second plugin), this has
    /// nothing to do with the streak — it's just the one existing bridge
    /// into the App Group both the app and TalkOfDayWidget can see.
    @objc func setThemePreference(_ call: CAPPluginCall) {
        guard let theme = call.getString("theme") else {
            call.reject("Missing theme")
            return
        }
        UserDefaults(suiteName: StreakBridgePlugin.appGroupID)?.set(theme, forKey: StreakBridgePlugin.themeKey)
        WidgetCenter.shared.reloadTimelines(ofKind: StreakBridgePlugin.widgetKind)
        call.resolve()
    }

    /// Mirrors the Color Palette choice from Settings, same idea as
    /// setThemePreference above but its own key — independent of the
    /// light/dark choice, a person can have a palette without an explicit
    /// theme override and vice versa.
    @objc func setPalettePreference(_ call: CAPPluginCall) {
        guard let palette = call.getString("palette") else {
            call.reject("Missing palette")
            return
        }
        UserDefaults(suiteName: StreakBridgePlugin.appGroupID)?.set(palette, forKey: StreakBridgePlugin.paletteKey)
        WidgetCenter.shared.reloadTimelines(ofKind: StreakBridgePlugin.widgetKind)
        call.resolve()
    }
}
