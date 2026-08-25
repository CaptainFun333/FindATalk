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
/// hashString() in docs/index.html — don't let the three drift apart.
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

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let dateSeed = String(format: "%04d-%02d-%02d", comps.year ?? 1970, comps.month ?? 1, comps.day ?? 1)

        let hash = hashString(dateSeed)
        let index = Int(hash % UInt32(sorted.count))
        return sorted[index]
    }

    /// DJB2 variant, bit-for-bit match of the JS hashString() (32-bit
    /// wraparound) — UInt32's `&*` overflow operator gives the same mod
    /// 2^32 truncation as JS's `>>> 0` coercions.
    static func hashString(_ s: String) -> UInt32 {
        var h: UInt32 = 5381
        for scalar in s.unicodeScalars {
            h = (h &* 33) ^ scalar.value
        }
        return h
    }
}
