# FindATalk — Store Listing Copy

Draft copy for both App Store Connect and Google Play Console. Character
counts noted next to each field's limit — trim to fit if needed once
pasted into the actual console (fonts/kerning in the console preview can
shift how things wrap, but counts below are exact).

---

## App Store (App Store Connect)

**App name** (30 char max)
```
FindATalk
```
(9 chars — plenty of room if you want a subtitle folded in, but Apple
keeps Name and Subtitle as separate fields, so leave this plain.)

**Subtitle** (30 char max — shown right under the name in search/listing)
```
General Conference Talks
```
(24 chars)

**Promotional text** (170 char max — shown above the description, editable
anytime without a new build; good for timely notes like "Now includes
April 2026 conference")
```
Instantly find a General Conference talk to read, share, or study — filter by speaker, calling, topic, or conference, or just draw one at random.
```
(145 chars)

**Description** (4000 char max)
```
FindATalk is a fast, focused way to land on a General Conference talk of The Church of Jesus Christ of Latter-day Saints — whether you're picking a topic for a talk, looking for something to read tonight, or just want to be surprised.

WHAT IT DOES
• Draw a random talk from a curated library spanning April 1971 through today — over 4,000 real, verified talks, no gaps.
• Narrow the pool by speaker, calling at the time of the talk, topic, or conference — filters combine, so you can get as specific or as broad as you like.
• Search titles and summaries directly.
• Browse a full list instead of drawing one at a time, in normal or condensed view.

KEEP TRACK
• Star any talk as a Favorite.
• Every talk you actually open is logged to Recently Viewed, so you can find your way back.
• Build your own named lists — a talk night lineup, a Sunday School unit, whatever you're planning.
• Back up your Favorites, Recents, and Lists to a file, and restore them later or on a new device.

BUILT ON REAL DATA
Every topic tag comes from the Church's own official general-conference topics index — not guessed from titles. Callings are tagged for the specific conference the talk was given at, so a talk from someone's years as a Seventy shows as Seventy, even if they were later called as an Apostle.

Everything runs on your device. No accounts, no ads, no analytics, no tracking — see the full privacy policy in-app or at findatalk.com/privacy.html.

FindATalk is an independent, fan-made tool. It is not produced by, endorsed by, or affiliated with The Church of Jesus Christ of Latter-day Saints. For the complete official library, visit churchofjesuschrist.org/study/general-conference.
```
(~1,830 chars — well under the 4000 limit, room to expand later)

**Keywords** (100 char max, comma-separated, no spaces needed — not shown
to users, only used for search indexing)
```
general conference,lds,talk,gospel,church,scripture,mormon,latter-day,seventy,apostle,relief society
```
(exactly 100 chars — at the limit, no room to add more without trimming)

**Support URL** (required)
```
https://findatalk.com
```
Consider adding a `support.html` (or a short section on the main page)
if you want something more explicit than the app's own homepage — not
required to launch.

**Marketing URL** (optional)
```
https://findatalk.com
```

**Privacy Policy URL** (required)
```
https://findatalk.com/privacy.html
```

**Category**
```
Primary: Reference
Secondary: Lifestyle (or Education)
```

**Age rating questionnaire**: no objectionable content of any kind in the
app — should land at 4+.

**App Privacy (data collection) questionnaire**: answer "Data Not
Collected" — the app has no accounts, analytics, or third-party SDKs;
everything is local `localStorage` (see privacy.html for the full
explanation you can lean on if a reviewer asks).

---

## Google Play (Play Console)

**App name** (30 char max)
```
FindATalk
```

**Short description** (80 char max — shown in search results and at the
top of the listing)
```
Find, filter, and save General Conference talks — speaker, topic, or random.
```
(76 chars)

**Full description** (4000 char max)
```
FindATalk is a fast, focused way to land on a General Conference talk of The Church of Jesus Christ of Latter-day Saints — whether you're picking a topic for a talk, looking for something to read tonight, or just want to be surprised.

WHAT IT DOES
• Draw a random talk from a curated library spanning April 1971 through today — over 4,000 real, verified talks, no gaps.
• Narrow the pool by speaker, calling at the time of the talk, topic, or conference — filters combine, so you can get as specific or as broad as you like.
• Search titles and summaries directly.
• Browse a full list instead of drawing one at a time, in normal or condensed view.

KEEP TRACK
• Star any talk as a Favorite.
• Every talk you actually open is logged to Recently Viewed, so you can find your way back.
• Build your own named lists — a talk night lineup, a Sunday School unit, whatever you're planning.
• Back up your Favorites, Recents, and Lists to a file, and restore them later or on a new device.

BUILT ON REAL DATA
Every topic tag comes from the Church's own official general-conference topics index — not guessed from titles. Callings are tagged for the specific conference the talk was given at, so a talk from someone's years as a Seventy shows as Seventy, even if they were later called as an Apostle.

Everything runs on your device. No accounts, no ads, no analytics, no tracking.

FindATalk is an independent, fan-made tool. It is not produced by, endorsed by, or affiliated with The Church of Jesus Christ of Latter-day Saints. For the complete official library, visit churchofjesuschrist.org/study/general-conference.
```
(~1,700 chars)

**App category**
```
Lifestyle (or Books & Reference)
```

**Contact details**
```
Email: b.christensen333@gmail.com
Website: https://findatalk.com
```

**Privacy Policy URL** (required)
```
https://findatalk.com/privacy.html
```

**Data safety form**: same answer as Apple's — no data collected, no data
shared. Walk through the form and select "No" / "Data isn't collected"
for each category; it should be a short form given the app's actual
behavior.

**Content rating questionnaire**: no violence, no user-generated content,
no location sharing, no in-app purchases — should land at "Everyone" /
PEGI 3 equivalent.

**Store listing graphics checklist**
- [x] App icon (512×512, generated from `branding/pulpit-icon-source.png`
  — Play Console will ask you to re-upload at 512×512 even though the
  APK/AAB already bundles the launcher icons; see `branding/` for
  ready sizes or re-export from the source if it wants a specific crop)
- [x] Feature graphic — `branding/play-feature-graphic.png` (1024×500)
- [ ] Phone screenshots — need Android-native captures (2–8 required,
  16:9 or 9:16, min 320px on the short side); the iOS simulator shots in
  `branding/screenshots/` won't pass Play's per-platform screenshot
  check, these need to come from an Android emulator or device
- [ ] Optional: tablet screenshots if you want to highlight the iPad-
  equivalent Android layout (7" / 10")
