import Foundation

let jsonURL = URL(fileURLWithPath: "data.json")
let data = try! Data(contentsOf: jsonURL)
let root = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
let talksRaw = root["talks"] as! [[Any]]

let talks: [Talk] = talksRaw.compactMap { row in
    guard row.count >= 5,
          let title = row[0] as? String,
          let speaker = row[1] as? String,
          let month = row[3] as? String,
          let urlSlug = row[4] as? String else { return nil }
    let year: Int
    if let y = row[2] as? Int { year = y }
    else if let y = row[2] as? String, let p = Int(y) { year = p }
    else { return nil }
    return Talk(title: title, speaker: speaker, year: year, month: month, urlSlug: urlSlug)
}

var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone.current
let comps = DateComponents(year: 2026, month: 8, day: 26, hour: 12)
let date = cal.date(from: comps)!

let day = TalkStore.localDayNumber(date)
print("day=\(day)")
let pick = TalkStore.talkOfTheDay(from: talks, date: date)
print("Pick: \(pick!.title) — \(pick!.speaker) (\(pick!.year)/\(pick!.month)/\(pick!.urlSlug))")
