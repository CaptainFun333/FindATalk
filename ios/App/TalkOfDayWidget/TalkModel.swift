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
    /// Official Church topic tags for this talk (TOPIC_LOOKUP in
    /// docs/index.html) — only used to find each CURATED_HOLIDAYS
    /// entry's eligible pool (e.g. "christmas", "easter").
    let topics: Set<String>

    var key: String { "\(year)|\(month)|\(urlSlug)" }

    var url: URL? {
        URL(string: "https://www.churchofjesuschrist.org/study/general-conference/\(year)/\(month)/\(urlSlug)?lang=eng")
    }
}

/// One curated-holiday rule — port of a CURATED_HOLIDAYS entry in
/// docs/index.html. `topic` is an official Church topic tag; `matches`
/// decides whether a given date is that holiday this year.
private struct Holiday {
    let topic: String
    let matches: (Date, Calendar) -> Bool
}

/// Loads talks from the widget extension's own bundled copy of data.json
/// and picks the same deterministic "Talk of the Day" as the web app and
/// the Android widget. This is a straight port of talkOfTheDay()/
/// cyclePick()/CURATED_HOLIDAYS/localDayNumber()/splitmix32() in
/// docs/index.html — don't let the three drift apart.
enum TalkStore {
    /// Port of CURATED_HOLIDAYS in docs/index.html — keep in sync. New
    /// Year's Day maps to "hope" rather than something more on-the-nose
    /// like "repentance" — both fit, but "hope" reads better for a
    /// first-of-the-year pick.
    private static let curatedHolidays: [Holiday] = [
        Holiday(topic: "hope", matches: { date, cal in fixedDate(date, cal, month: 1, day: 1) }),
        Holiday(topic: "love", matches: { date, cal in fixedDate(date, cal, month: 2, day: 14) }),
        Holiday(topic: "relief-society", matches: { date, cal in fixedDate(date, cal, month: 3, day: 17) }),
        Holiday(topic: "easter", matches: { date, cal in isEasterSunday(date, cal) }),
        Holiday(topic: "restoration", matches: { date, cal in fixedDate(date, cal, month: 4, day: 6) }),
        Holiday(topic: "motherhood", matches: { date, cal in isNthWeekdayOfMonth(date, cal, month: 5, weekday: 1, n: 2) }),
        Holiday(topic: "priesthood", matches: { date, cal in fixedDate(date, cal, month: 5, day: 15) }),
        Holiday(topic: "fatherhood", matches: { date, cal in isNthWeekdayOfMonth(date, cal, month: 6, weekday: 1, n: 3) }),
        Holiday(topic: "freedom", matches: { date, cal in fixedDate(date, cal, month: 7, day: 4) }),
        Holiday(topic: "pioneers", matches: { date, cal in fixedDate(date, cal, month: 7, day: 24) }),
        Holiday(topic: "gratitude", matches: { date, cal in isNthWeekdayOfMonth(date, cal, month: 11, weekday: 5, n: 4) }),
        Holiday(topic: "christmas", matches: { date, cal in fixedDate(date, cal, month: 12, day: 25) }),
    ]

    /// True when `date` falls on `month`/`day` (1-indexed, as Calendar
    /// components use) regardless of year.
    private static func fixedDate(_ date: Date, _ cal: Calendar, month: Int, day: Int) -> Bool {
        let c = cal.dateComponents([.month, .day], from: date)
        return c.month == month && c.day == day
    }

    /// Port of isNthWeekdayOfMonth() in docs/index.html — keep in sync.
    /// True when `date` is the n-th occurrence of `weekday` (Calendar's
    /// 1=Sunday..7=Saturday) in `month` (1=January..12=December) — e.g.
    /// Thanksgiving is the 4th Thursday of November.
    private static func isNthWeekdayOfMonth(_ date: Date, _ cal: Calendar, month: Int, weekday: Int, n: Int) -> Bool {
        let c = cal.dateComponents([.month, .day, .weekday], from: date)
        guard c.month == month, c.weekday == weekday, let day = c.day else { return false }
        return ((day - 1) / 7) + 1 == n
    }

    static func loadTalks() -> [Talk] {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let talksRaw = root["talks"] as? [[Any]] else {
            return []
        }

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

    /// Port of talkOfTheDay() in docs/index.html — keep in sync. Checks
    /// today's curated holidays first, then falls back to the no-repeat
    /// cycle shuffle.
    static func talkOfTheDay(from talks: [Talk], date: Date = Date()) -> Talk? {
        guard !talks.isEmpty else { return nil }

        let sorted = talks.sorted { $0.key < $1.key }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        for holiday in curatedHolidays where holiday.matches(date, calendar) {
            let year = calendar.component(.year, from: date)
            if let pick = curatedHolidayPick(holiday, sorted, year) {
                return pick
            }
            break // no talk carries that topic yet — fall through to the cycle
        }

        return cyclePick(sorted, localDayNumber(date))
    }

    /// Port of cyclePick() in docs/index.html — keep in sync. Groups days
    /// into cycles of exactly `sorted.count` consecutive days, each with
    /// its own seeded shuffle, so every talk airs once before any talk
    /// repeats.
    private static func cyclePick(_ sorted: [Talk], _ dayNumber: Int) -> Talk {
        let cycleLength = sorted.count
        let cycleNumber = Int(floor(Double(dayNumber) / Double(cycleLength)))
        let positionInCycle = ((dayNumber % cycleLength) + cycleLength) % cycleLength
        let order = seededShuffledIndices(cycleLength, splitmix32(UInt32(truncatingIfNeeded: cycleNumber)))
        return sorted[order[positionInCycle]]
    }

    /// Port of seededShuffledIndices() in docs/index.html — keep in sync.
    /// Deterministic Fisher-Yates shuffle of [0, count) seeded by `seed`,
    /// re-mixing through splitmix32 on every draw.
    private static func seededShuffledIndices(_ count: Int, _ seed: UInt32) -> [Int] {
        var idx = Array(0..<count)
        var state = seed
        var i = count - 1
        while i > 0 {
            state = splitmix32(state)
            let j = Int(state % UInt32(i + 1))
            idx.swapAt(i, j)
            i -= 1
        }
        return idx
    }

    /// Port of curatedHolidayPick() in docs/index.html — keep in sync.
    /// Returns nil if no talk in the current data carries this holiday's
    /// topic yet.
    private static func curatedHolidayPick(_ holiday: Holiday, _ sorted: [Talk], _ year: Int) -> Talk? {
        let eligible = sorted.filter { $0.topics.contains(holiday.topic) }
        guard !eligible.isEmpty else { return nil }
        let seed = UInt32(truncatingIfNeeded: year) ^ 0x5a5a5a5a
        let index = Int(splitmix32(seed) % UInt32(eligible.count))
        return eligible[index]
    }

    /// Port of isEasterSunday()/easterSunday() in docs/index.html — keep
    /// in sync. Anonymous Gregorian algorithm (Computus).
    private static func isEasterSunday(_ date: Date, _ calendar: Calendar) -> Bool {
        let year = calendar.component(.year, from: date)
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31 // 3=March, 4=April
        let day = ((h + l - 7 * m + 114) % 31) + 1
        let comps = calendar.dateComponents([.month, .day], from: date)
        return comps.month == month && comps.day == day
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
