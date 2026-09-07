import AppIntents
import Foundation

/// Siri Shortcut (idea 44) — "Hey Siri, give me my Talk of the Day."
/// Reuses TalkModel.swift's TalkStore verbatim (shared with
/// TalkOfDayWidget via multi-target membership, see project.pbxproj) so
/// this can never drift from what the widget — or docs/index.html's own
/// talkOfTheDay() — actually picks. Requires App Group access to read the
/// mirrored streak (see StreakBridgePlugin.swift); the entitlement is
/// already present on this target from that feature, no new signing step
/// needed.
///
/// `loadTalks()`'s `Bundle.main.url(forResource:withExtension:)` call
/// only searches a bundle's top level, but this target bundles `data.json`
/// nested inside the `public` folder reference (the WebView's own assets),
/// not as a flat top-level resource the way the widget extension has it —
/// confirmed by checking project.pbxproj's Resources phases before writing
/// this, not assumed. Rather than duplicating data.json as a second, flat
/// copy in this target purely for Swift to find it (real app-size cost,
/// data.json is several MB), this looks in both locations: bundle root
/// first (works for the widget target, and this target if that ever
/// changes), falling back to the `public` subdirectory (this target's
/// actual layout today).
private func loadBundledTalkData() -> [Talk] {
    if let url = Bundle.main.url(forResource: "data", withExtension: "json"),
       let talks = talksFrom(url), !talks.isEmpty {
        return talks
    }
    if let url = Bundle.main.url(forResource: "data", withExtension: "json", subdirectory: "public"),
       let talks = talksFrom(url) {
        return talks
    }
    return []
}

/// Parses one data.json URL into [Talk] — the exact same parsing
/// TalkStore.loadTalks() does internally, pulled out here since that
/// function only knows the single flat-bundle path, not this target's
/// subdirectory case.
private func talksFrom(_ url: URL) -> [Talk]? {
    guard let data = try? Data(contentsOf: url),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let talksRaw = root["talks"] as? [[Any]] else { return nil }

    let topicLookup = root["topicLookup"] as? [String: [String]] ?? [:]

    return talksRaw.compactMap { row -> Talk? in
        guard row.count >= 5,
              let title = row[0] as? String,
              let speaker = row[1] as? String,
              let month = row[3] as? String,
              let urlSlug = row[4] as? String else { return nil }

        let year: Int
        if let y = row[2] as? Int {
            year = y
        } else if let y = row[2] as? String, let parsed = Int(y) {
            year = parsed
        } else {
            return nil
        }

        let topics = Set(topicLookup["\(year)|\(month)|\(urlSlug)"] ?? [])
        return Talk(title: title, speaker: speaker, year: year, month: month, urlSlug: urlSlug, topics: topics)
    }
}

/// Read-only mirror of renderStreak()'s data, same UserDefaults key
/// StreakStore in TalkOfDayWidget.swift reads — duplicated here rather
/// than shared, since that copy lives in the widget target's own file and
/// pulling one more file across targets for a single nice-to-have string
/// wasn't worth it. Returns nil (never a "0-day" default) for no streak,
/// a stale streak, or a missing App Group — the dialog just omits the
/// clause in every one of those cases.
@available(iOS 16.0, *)
private func currentStreakClause() -> String? {
    guard let raw = UserDefaults(suiteName: "group.com.captainfun333.findatalk")?.string(forKey: "findATalkStreak"),
          let data = raw.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let count = obj["count"] as? Int, count > 0,
          let lastDate = obj["lastDate"] as? String else { return nil }

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone.current
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    let today = formatter.string(from: Date())
    let yesterday = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    guard lastDate == today || lastDate == yesterday else { return nil } // stale — same rule as the widget's isStale()

    return count == 1 ? " You're on day 1 of a new streak." : " You're on a \(count)-day streak."
}

@available(iOS 16.0, *)
struct TalkOfTheDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Talk of the Day"
    static var description = IntentDescription("Speaks today's Talk of the Day and opens FindATalk to it.")
    // Standard App Intents mechanism for "this intent should bring the app
    // to the foreground" — matches the widget's own principle of always
    // opening the real app rather than a bare talk URL, so recordOpened()/
    // touchStreak() in docs/index.html (which only run from inside the
    // app) still work normally once the person taps through from there.
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let talks = loadBundledTalkData()
        guard let pick = TalkStore.talkOfTheDay(from: talks) else {
            return .result(dialog: "I couldn't load today's Talk of the Day — try opening FindATalk directly.")
        }
        let streakClause = currentStreakClause() ?? ""
        return .result(dialog: "Today's Talk of the Day is \"\(pick.title)\" by \(pick.speaker).\(streakClause)")
    }
}

@available(iOS 16.0, *)
struct FindATalkShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TalkOfTheDayIntent(),
            phrases: [
                "Give me my Talk of the Day in \(.applicationName)",
                "What's my \(.applicationName) pick today",
                "Open my Talk of the Day in \(.applicationName)"
            ],
            shortTitle: "Talk of the Day",
            systemImageName: "text.book.closed"
        )
    }
}
