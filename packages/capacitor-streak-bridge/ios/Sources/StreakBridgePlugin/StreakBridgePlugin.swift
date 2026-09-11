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
/// Packaged as its own local Capacitor plugin (`packages/
/// capacitor-streak-bridge`, referenced from the root package.json via a
/// `file:` dependency) rather than living directly in `ios/App/App/` —
/// that's what lets `npx cap sync` discover it like any other plugin and
/// keep `ios/App/App/capacitor.config.json`'s `packageClassList` and
/// `ios/App/CapApp-SPM/Package.swift` up to date on its own. Before this
/// move, both of those were hand-maintained and `cap sync` would
/// silently strip this plugin's entry from `packageClassList` on every
/// run, since it only scans plugins it actually knows about (see
/// PROJECT_HANDOFF.md for the fuller story).
///
/// Requires the App Group capability enabled in Xcode on BOTH the App
/// target and TalkOfDayWidget, with the same group ID as `appGroupID`
/// below — a manual, one-time signing step (see PROJECT_HANDOFF.md).
/// Until that's done, `UserDefaults(suiteName:)` below just returns nil
/// and this silently writes nowhere; the app still works, the widget
/// just never shows a streak.
@objc(StreakBridgePlugin)
public class StreakBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StreakBridgePlugin"
    public let jsName = "StreakBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setStreak", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setThemePreference", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setPalettePreference", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "refreshWidget", returnType: CAPPluginReturnPromise)
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
        // unless told to reload now. The actual reload is a separate call
        // (refreshWidget() below) — docs/index.html's mirrorStreakToNative()
        // calls it right after this resolves, same split as the write/
        // refresh calls on the Android side (Preferences.set() then
        // WidgetRefresh.refresh()).
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
        // See the comment in setStreak() above — the reload is a separate
        // refreshWidget() call from the JS side, not done here.
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
        // See the comment in setStreak() above — the reload is a separate
        // refreshWidget() call from the JS side, not done here.
        call.resolve()
    }

    /// Tells the widget to reload right now. The one place all four
    /// JS-side writes (setStreak/setThemePreference/setPalettePreference
    /// above, plus a bare "today's pick just rendered, no state change")
    /// funnel through to actually repaint — see refreshNativeWidget() in
    /// docs/index.html, which calls this after each of them. Split out
    /// as its own call (rather than each setter reloading itself) so a
    /// render with no state change still has something to call: none of
    /// the three setters above fire on a bare app open, only when the
    /// streak/theme/palette itself changes, and getTimeline()'s own
    /// `.after(startOfTomorrow)` policy in TalkOfDayWidget.swift is only a
    /// best-effort promise to reload after local midnight — still subject
    /// to Apple's per-app reload budget, so a lightly-used widget can lag
    /// behind an app that was just opened and already shows today's talk.
    @objc func refreshWidget(_ call: CAPPluginCall) {
        WidgetCenter.shared.reloadTimelines(ofKind: StreakBridgePlugin.widgetKind)
        call.resolve()
    }
}
