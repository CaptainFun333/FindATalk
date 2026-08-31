import WidgetKit
import SwiftUI

struct TalkEntry: TimelineEntry {
    let date: Date
    let talk: Talk?
    let streakText: String?
    // "light" / "dark" if the person made an explicit choice with the
    // in-app toggle, nil if they haven't (still following the system
    // setting) — see ThemeStore below.
    let themeOverride: String?
    // "rose" / "slate" / "sage" if the person picked a Color Palette in
    // Settings, nil if they haven't (still Brass, the default) — see
    // PaletteStore below.
    let paletteOverride: String?
}

/// Read-only mirror of an explicit light/dark choice made with the in-app
/// toggle (see mirrorThemeToNative() in docs/index.html and
/// StreakBridgePlugin.setThemePreference). nil means no explicit choice
/// has ever been made (or the App Group isn't set up), in which case the
/// view falls back to the system's own colorScheme, same as before this
/// existed.
private enum ThemeStore {
    // Must match StreakBridgePlugin.appGroupID/.themeKey.
    static let appGroupID = "group.com.captainfun333.findatalk"
    static let themeKey = "findATalkTheme"

    static func currentOverride() -> String? {
        UserDefaults(suiteName: appGroupID)?.string(forKey: themeKey)
    }
}

/// Read-only mirror of a Color Palette choice made in Settings (see
/// mirrorPaletteToNative() in docs/index.html and
/// StreakBridgePlugin.setPalettePreference). nil means Brass, the
/// default.
private enum PaletteStore {
    // Must match StreakBridgePlugin.appGroupID/.paletteKey.
    static let appGroupID = "group.com.captainfun333.findatalk"
    static let paletteKey = "findATalkPalette"

    static func currentOverride() -> String? {
        UserDefaults(suiteName: appGroupID)?.string(forKey: paletteKey)
    }
}

/// Read-only mirror of renderStreak()'s text in docs/index.html — this
/// only displays whatever StreakBridgePlugin last wrote, it never
/// advances the streak itself (that only happens when the app is
/// actually opened). Returns nil if there's no streak yet, or if the App
/// Group isn't set up (see StreakBridgePlugin.swift), so the view can
/// just omit the row entirely rather than show a "0-day" default.
private enum StreakStore {
    // Must match StreakBridgePlugin.appGroupID and STREAK_KEY in
    // docs/index.html.
    static let appGroupID = "group.com.captainfun333.findatalk"
    static let streakKey = "findATalkStreak"

    static func currentText() -> String? {
        guard let raw = UserDefaults(suiteName: appGroupID)?.string(forKey: streakKey),
              let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        let count = obj["count"] as? Int ?? 0
        guard count > 0 else { return nil }
        // Same staleness check as settleStreak() in docs/index.html:
        // `lastDate` neither today nor yesterday means a full calendar day
        // was missed entirely, so the streak is broken even though `count`
        // on disk hasn't been zeroed yet — that only happens the next time
        // a talk is actually opened. Duplicated here (rather than relying
        // on the app to write the zeroed value) because getTimeline() above
        // already schedules a reload right after local midnight, so the
        // widget can show a break the moment it happens, without the app
        // ever being opened that day.
        if let lastDate = obj["lastDate"] as? String, isStale(lastDate) { return nil }
        if count == 1 { return "🔥 Day 1 — come back tomorrow to start a streak" }

        let activeDays = (obj["activeDays"] as? [Any])?.count ?? 0
        return "🔥 \(activeDays) of the last 365 — \(count)-day streak"
    }

    /// True when `lastDate` (a "yyyy-MM-dd" string, same format as
    /// localDateSeed() in docs/index.html) is neither today nor yesterday
    /// — i.e. a full calendar day was missed.
    private static func isStale(_ lastDate: String) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"

        let today = formatter.string(from: Date())
        if lastDate == today { return false }
        let yesterday = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        return lastDate != yesterday
    }
}

struct TalkOfDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TalkEntry {
        TalkEntry(
            date: Date(),
            talk: Talk(title: "Why Not Now?", speaker: "Neal A. Maxwell", year: 1974, month: "10", urlSlug: "why-not-now", topics: []),
            streakText: "🔥 122 of the last 365 — 10-day streak",
            themeOverride: ThemeStore.currentOverride(),
            paletteOverride: PaletteStore.currentOverride()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TalkEntry) -> Void) {
        let pick = TalkStore.talkOfTheDay(from: TalkStore.loadTalks())
        completion(TalkEntry(date: Date(), talk: pick, streakText: StreakStore.currentText(), themeOverride: ThemeStore.currentOverride(), paletteOverride: PaletteStore.currentOverride()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TalkEntry>) -> Void) {
        let talks = TalkStore.loadTalks()
        let now = Date()
        let pick = TalkStore.talkOfTheDay(from: talks, date: now)
        let entry = TalkEntry(date: now, talk: pick, streakText: StreakStore.currentText(), themeOverride: ThemeStore.currentOverride(), paletteOverride: PaletteStore.currentOverride())

        // Reload right after local midnight so tomorrow's pick shows up
        // promptly, rather than waiting on WidgetKit's own daily budget.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)

        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }
}

// Palette mirrors docs/index.html's :root custom properties (per
// data-palette, light and dark) — keep all four in sync with the web app's
// CSS "color palettes" block and Android's TalkOfDayWidgetProvider color
// constants. Unlike Android (values-night/colors.xml, resolved
// automatically by the OS for the no-override case), SwiftUI has no
// resource-qualifier system for plain Color values, so the view below
// always picks explicitly, folding in @Environment(\.colorScheme) only
// when there's no explicit theme override.
private enum TalkPalette {
    struct Scheme {
        let paperRaised: Color
        let ink: Color
        let inkSoft: Color
        let brass: Color
        let line: Color
        let burgundy: Color
    }

    struct PaletteSet {
        let light: Scheme
        let dark: Scheme
    }

    static let brass = PaletteSet(
        light: Scheme(
            paperRaised: Color(red: 0.980, green: 0.969, blue: 0.933),
            ink: Color(red: 0.110, green: 0.173, blue: 0.259),
            inkSoft: Color(red: 0.239, green: 0.302, blue: 0.392),
            brass: Color(red: 0.663, green: 0.510, blue: 0.184),
            line: Color(red: 0.788, green: 0.749, blue: 0.635),
            burgundy: Color(red: 0.431, green: 0.169, blue: 0.204)
        ),
        dark: Scheme(
            paperRaised: Color(red: 0.122, green: 0.149, blue: 0.208),
            // Pure white, not a tinted off-white — see the "dark palettes
            // use pure white ink" comment below the PaletteSet definitions.
            ink: Color(red: 1.0, green: 1.0, blue: 1.0),
            inkSoft: Color(red: 0.718, green: 0.741, blue: 0.812),
            brass: Color(red: 0.792, green: 0.647, blue: 0.314),
            line: Color(red: 0.200, green: 0.235, blue: 0.310),
            burgundy: Color(red: 0.851, green: 0.541, blue: 0.576)
        )
    )

    static let rose = PaletteSet(
        light: Scheme(
            // paperRaised/line pulled more saturated than a first draft
            // that read too close to Brass's own ivory — see the
            // "boosted Rose's light-mode saturation" comment below.
            paperRaised: Color(red: 0.984, green: 0.925, blue: 0.910),
            ink: Color(red: 0.235, green: 0.145, blue: 0.188),
            inkSoft: Color(red: 0.420, green: 0.298, blue: 0.345),
            brass: Color(red: 0.643, green: 0.353, blue: 0.447),
            line: Color(red: 0.878, green: 0.718, blue: 0.729),
            burgundy: Color(red: 0.639, green: 0.475, blue: 0.184)
        ),
        dark: Scheme(
            paperRaised: Color(red: 0.153, green: 0.102, blue: 0.125),
            ink: Color(red: 1.0, green: 1.0, blue: 1.0),
            inkSoft: Color(red: 0.788, green: 0.702, blue: 0.729),
            brass: Color(red: 0.831, green: 0.569, blue: 0.659),
            line: Color(red: 0.239, green: 0.173, blue: 0.200),
            burgundy: Color(red: 0.788, green: 0.639, blue: 0.369)
        )
    )

    static let slate = PaletteSet(
        light: Scheme(
            paperRaised: Color(red: 0.961, green: 0.969, blue: 0.980),
            ink: Color(red: 0.125, green: 0.169, blue: 0.227),
            inkSoft: Color(red: 0.298, green: 0.353, blue: 0.424),
            brass: Color(red: 0.290, green: 0.435, blue: 0.573),
            line: Color(red: 0.765, green: 0.796, blue: 0.831),
            burgundy: Color(red: 0.416, green: 0.231, blue: 0.361)
        ),
        dark: Scheme(
            paperRaised: Color(red: 0.106, green: 0.137, blue: 0.180),
            ink: Color(red: 1.0, green: 1.0, blue: 1.0),
            inkSoft: Color(red: 0.702, green: 0.741, blue: 0.788),
            brass: Color(red: 0.498, green: 0.663, blue: 0.788),
            line: Color(red: 0.173, green: 0.220, blue: 0.275),
            burgundy: Color(red: 0.788, green: 0.545, blue: 0.690)
        )
    )

    static let sage = PaletteSet(
        light: Scheme(
            // ink/inkSoft/brass/line pulled back toward neutral from a
            // first draft that saturated too many roles toward green,
            // which read as a color wash over the whole widget rather
            // than a palette — see the "rebalanced Sage" comment below.
            paperRaised: Color(red: 0.973, green: 0.969, blue: 0.925),
            ink: Color(red: 0.157, green: 0.196, blue: 0.165),
            inkSoft: Color(red: 0.361, green: 0.392, blue: 0.365),
            brass: Color(red: 0.435, green: 0.486, blue: 0.247),
            line: Color(red: 0.792, green: 0.780, blue: 0.729),
            burgundy: Color(red: 0.549, green: 0.290, blue: 0.184)
        ),
        dark: Scheme(
            paperRaised: Color(red: 0.125, green: 0.161, blue: 0.125),
            ink: Color(red: 1.0, green: 1.0, blue: 1.0),
            inkSoft: Color(red: 0.725, green: 0.761, blue: 0.710),
            brass: Color(red: 0.616, green: 0.690, blue: 0.416),
            line: Color(red: 0.200, green: 0.251, blue: 0.200),
            burgundy: Color(red: 0.851, green: 0.541, blue: 0.388)
        )
    )

    // Two fixes from user feedback after reviewing all four palettes live:
    // (1) every dark Scheme.ink above is now pure white (1,1,1), not a
    // tinted off-white — dark ink dominates the widget's visual weight
    // (the talk title), so any hue there read as "a color filter over the
    // whole thing," worst on Sage. (2) Rose's light paperRaised/line were
    // too close to Brass's own ivory to feel like a distinct palette;
    // Sage's light ink/inkSoft/brass/line were pulled back toward neutral
    // for the same reason (1) fixes in dark — only the brass/burgundy
    // accent roles should carry real saturation, matching how Brass
    // itself already works. Keep docs/index.html's CSS palette block and
    // Android's TalkOfDayWidgetProvider color constants in sync with
    // these exact values if either changes again.

    /// nil or any unrecognized string falls back to Brass, the default —
    /// same rule as setPalette()'s 'brass' case in docs/index.html.
    static func paletteSet(for palette: String?) -> PaletteSet {
        switch palette {
        case "rose": return rose
        case "slate": return slate
        case "sage": return sage
        default: return brass
        }
    }

    /// An explicit "light"/"dark" from entry.themeOverride wins over the
    /// system colorScheme; any other value (nil — no choice made yet, or
    /// unrecognized) falls back to following the system, same as before
    /// palettes existed. The palette override picks which of the four
    /// PaletteSets to resolve light/dark within, independent of that.
    static func resolve(paletteOverride: String?, themeOverride: String?, colorScheme: ColorScheme) -> Scheme {
        let set = paletteSet(for: paletteOverride)
        switch themeOverride {
        case "light": return set.light
        case "dark": return set.dark
        default: return colorScheme == .dark ? set.dark : set.light
        }
    }
}

struct TalkOfDayWidgetEntryView: View {
    var entry: TalkOfDayProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = TalkPalette.resolve(paletteOverride: entry.paletteOverride, themeOverride: entry.themeOverride, colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 4) {
            Text("TALK OF THE DAY")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundColor(palette.brass)

            if let talk = entry.talk {
                Text(talk.title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(palette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Text(talk.speaker)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(palette.inkSoft)
                    .lineLimit(1)
            } else {
                Text("FindATalk")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(palette.ink)
            }

            if let streakText = entry.streakText {
                Text(streakText)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(palette.burgundy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Opens the app rather than the talk's URL directly, so the
        // person taps "Open This Talk" from inside it — that's the one
        // place recordOpened()/touchStreak() actually run in
        // docs/index.html, so this is what makes the streak advance at
        // all. Going straight to Safari bypassed the app entirely and
        // the streak just never moved. Requires the custom URL scheme
        // registered in App/Info.plist (CFBundleURLTypes).
        .widgetURL(URL(string: "com.captainfun333.findatalk://"))
        .talkOfDayBackground(palette.paperRaised)
    }
}

private extension View {
    /// containerBackground(for:) is required on iOS 17+ (and warns/behaves
    /// oddly without it); older OSes fall back to a plain background fill.
    @ViewBuilder
    func talkOfDayBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                color
            }
        } else {
            self.background(color)
        }
    }
}

struct TalkOfDayWidget: Widget {
    let kind: String = "TalkOfDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TalkOfDayProvider()) { entry in
            TalkOfDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Talk of the Day")
        .description("Shows today's Talk of the Day and your streak — tap to open the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
