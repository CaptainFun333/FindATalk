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
        if count == 1 { return "🔥 Day 1 — come back tomorrow to start a streak" }

        let activeDays = (obj["activeDays"] as? [Any])?.count ?? 0
        return "🔥 \(activeDays) of the last 365 — \(count)-day streak"
    }
}

struct TalkOfDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TalkEntry {
        TalkEntry(
            date: Date(),
            talk: Talk(title: "Why Not Now?", speaker: "Neal A. Maxwell", year: 1974, month: "10", urlSlug: "why-not-now"),
            streakText: "🔥 122 of the last 365 — 10-day streak",
            themeOverride: ThemeStore.currentOverride()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TalkEntry) -> Void) {
        let pick = TalkStore.talkOfTheDay(from: TalkStore.loadTalks())
        completion(TalkEntry(date: Date(), talk: pick, streakText: StreakStore.currentText(), themeOverride: ThemeStore.currentOverride()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TalkEntry>) -> Void) {
        let talks = TalkStore.loadTalks()
        let now = Date()
        let pick = TalkStore.talkOfTheDay(from: talks, date: now)
        let entry = TalkEntry(date: now, talk: pick, streakText: StreakStore.currentText(), themeOverride: ThemeStore.currentOverride())

        // Reload right after local midnight so tomorrow's pick shows up
        // promptly, rather than waiting on WidgetKit's own daily budget.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)

        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }
}

// Palette mirrors docs/index.html's :root custom properties (light) and
// :root[data-theme="dark"] (dark) — keep both in sync with the web app.
// Unlike Android (values-night/colors.xml, resolved automatically by the
// OS), SwiftUI has no resource-qualifier system for plain Color values, so
// the view below picks light/dark explicitly from @Environment(\.colorScheme).
private enum TalkPalette {
    struct Scheme {
        let paperRaised: Color
        let ink: Color
        let inkSoft: Color
        let brass: Color
        let line: Color
        let burgundy: Color
    }

    static let light = Scheme(
        paperRaised: Color(red: 0.980, green: 0.969, blue: 0.933),
        ink: Color(red: 0.110, green: 0.173, blue: 0.259),
        inkSoft: Color(red: 0.239, green: 0.302, blue: 0.392),
        brass: Color(red: 0.663, green: 0.510, blue: 0.184),
        line: Color(red: 0.788, green: 0.749, blue: 0.635),
        burgundy: Color(red: 0.431, green: 0.169, blue: 0.204)
    )

    static let dark = Scheme(
        paperRaised: Color(red: 0.122, green: 0.149, blue: 0.208),
        ink: Color(red: 0.953, green: 0.937, blue: 0.886),
        inkSoft: Color(red: 0.718, green: 0.741, blue: 0.812),
        brass: Color(red: 0.792, green: 0.647, blue: 0.314),
        line: Color(red: 0.200, green: 0.235, blue: 0.310),
        burgundy: Color(red: 0.851, green: 0.541, blue: 0.576)
    )

    static func forScheme(_ colorScheme: ColorScheme) -> Scheme {
        colorScheme == .dark ? dark : light
    }

    /// An explicit "light"/"dark" from entry.themeOverride wins over the
    /// system colorScheme; any other value (nil — no choice made yet, or
    /// unrecognized) falls back to following the system, same as before
    /// the in-app toggle existed.
    static func resolve(override: String?, colorScheme: ColorScheme) -> Scheme {
        switch override {
        case "light": return light
        case "dark": return dark
        default: return forScheme(colorScheme)
        }
    }
}

struct TalkOfDayWidgetEntryView: View {
    var entry: TalkOfDayProvider.Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = TalkPalette.resolve(override: entry.themeOverride, colorScheme: colorScheme)

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
                Text("Find A Talk")
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
