import Foundation

/// Mirrors the `[title, speaker, year, month, urlSlug]` tuple shape used by
/// docs/data.json / docs/index.html's TALKS array, and the Android widget's
/// TalkOfDayWidgetProvider.Talk — keep all three in sync.
struct Talk {
    let title: String
    let speaker: String
    let year: Int
    let month: String
    let urlSlug: String

    var key: String { "\(year)|\(month)|\(urlSlug)" }

    var url: URL? {
        URL(string: "https://www.churchofjesuschrist.org/study/general-conference/\(year)/\(month)/\(urlSlug)?lang=eng")
    }
}

/// Loads talks from the widget extension's own bundled copy of data.json
/// and picks the same deterministic "Talk of the Day" as the web app and
/// the Android widget. This is a straight port of talkOfTheDay()/
/// localDayNumber()/splitmix32() in docs/index.html — don't let the three
/// drift apart.
enum TalkStore {
    static func loadTalks() -> [Talk] {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let talksRaw = root["talks"] as? [[Any]] else {
            return []
        }

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

            return Talk(title: title, speaker: speaker, year: year, month: month, urlSlug: urlSlug)
        }
    }

    static func talkOfTheDay(from talks: [Talk], date: Date = Date()) -> Talk? {
        guard !talks.isEmpty else { return nil }

        let sorted = talks.sorted { $0.key < $1.key }

        let seed = UInt32(truncatingIfNeeded: localDayNumber(date))
        let hash = splitmix32(seed)
        let index = Int(hash % UInt32(sorted.count))
        return sorted[index]
    }

    /// Days since epoch on the device's local calendar (not UTC) — a
    /// straight port of localDayNumber() in docs/index.html. Must use the
    /// same "local midnight, floor(ms/86400000)" arithmetic as the JS
    /// version, not a timezone-independent day count, so it lines up
    /// exactly with what the web app computes on the same device.
    static func localDayNumber(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let startOfDay = calendar.startOfDay(for: date)
        let ms = startOfDay.timeIntervalSince1970 * 1000
        return Int(floor(ms / 86400000))
    }

    /// Integer mixing hash (splitmix32), bit-for-bit match of the JS
    /// splitmix32() in docs/index.html — replaced a prior DJB2-on-string
    /// version that didn't avalanche for adjacent dates. UInt32's `&+`/`&*`
    /// overflow operators give the same mod 2^32 truncation as JS's
    /// `>>> 0` coercions and Math.imul.
    static func splitmix32(_ seed: UInt32) -> UInt32 {
        let h = seed &+ 0x9e3779b9
        var z = h
        z = (z ^ (z >> 16)) &* 0x21f0aaad
        z = (z ^ (z >> 15)) &* 0x735a2d97
        z = z ^ (z >> 15)
        return z
    }
}
