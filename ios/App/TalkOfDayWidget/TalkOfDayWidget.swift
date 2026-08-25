import WidgetKit
import SwiftUI

struct TalkEntry: TimelineEntry {
    let date: Date
    let talk: Talk?
    let streakText: String?
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
            streakText: "🔥 122 of the last 365 — 10-day streak"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TalkEntry) -> Void) {
        let pick = TalkStore.talkOfTheDay(from: TalkStore.loadTalks())
        completion(TalkEntry(date: Date(), talk: pick, streakText: StreakStore.currentText()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TalkEntry>) -> Void) {
        let talks = TalkStore.loadTalks()
        let now = Date()
        let pick = TalkStore.talkOfTheDay(from: talks, date: now)
        let entry = TalkEntry(date: now, talk: pick, streakText: StreakStore.currentText())

        // Reload right after local midnight so tomorrow's pick shows up
        // promptly, rather than waiting on WidgetKit's own daily budget.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)

        completion(Timeline(entries: [entry], policy: .after(startOfTomorrow)))
    }
}

// Palette mirrors docs/index.html's :root custom properties — keep in sync.
private enum TalkPalette {
    static let paperRaised = Color(red: 0.980, green: 0.969, blue: 0.933)
    static let ink = Color(red: 0.110, green: 0.173, blue: 0.259)
    static let inkSoft = Color(red: 0.239, green: 0.302, blue: 0.392)
    static let brass = Color(red: 0.663, green: 0.510, blue: 0.184)
    static let line = Color(red: 0.788, green: 0.749, blue: 0.635)
    static let burgundy = Color(red: 0.431, green: 0.169, blue: 0.204)
}

struct TalkOfDayWidgetEntryView: View {
    var entry: TalkOfDayProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TALK OF THE DAY")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundColor(TalkPalette.brass)

            if let talk = entry.talk {
                Text(talk.title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(TalkPalette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Text(talk.speaker)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(TalkPalette.inkSoft)
                    .lineLimit(1)
            } else {
                Text("Find A Talk")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(TalkPalette.ink)
            }

            if let streakText = entry.streakText {
                Text(streakText)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(TalkPalette.burgundy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(entry.talk?.url)
        .talkOfDayBackground()
    }
}

private extension View {
    /// containerBackground(for:) is required on iOS 17+ (and warns/behaves
    /// oddly without it); older OSes fall back to a plain background fill.
    @ViewBuilder
    func talkOfDayBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                TalkPalette.paperRaised
            }
        } else {
            self.background(TalkPalette.paperRaised)
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
        .description("Shows today's Talk of the Day and opens it in Safari when tapped.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
