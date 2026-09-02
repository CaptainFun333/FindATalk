# Changelog

All notable changes to FindATalk are logged here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/): grouped by version, with
`Fixed` / `Added` / `Changed` / `Removed` subsections as needed.

`Unreleased` collects everything since the last version that was actually
built and submitted to a store — see `CLAUDE.md` for the process that keeps
this updated.

## [Unreleased]

### Added
- Added a "Show me around" tour that walks new users through Talk of the Day, filters, finding talks, favorites/lists/notes, the "Come, Follow Me" tab, and following citations. It shows automatically the first time you open the app, and you can replay it anytime from Settings → Show me around.
- Tapping a citation now offers the same "go to the source, or see where the talk cites it" choice for Other Talks, Church Magazines, and Hymns, not just scripture citations — wherever citations show up (a talk's own Citations row, Show a List, Recently Viewed, Favorites, My Lists, My Notes, and the "Come, Follow Me" tab).
- Switching between Home, CFM, Recent, Favs, Notes, and Lists (by tapping a tab or swiping) now animates with a quick fade/slide instead of an instant cut.

### Changed
- Rose, Slate, and Sage color themes now use a distinct accent color for the eyebrow text and "Talk of the Day" label (a teal for Rose, sand for Slate, lavender for Sage), in both light and dark mode, instead of a shade that was too close to the theme's own background or body text. The Brass theme is unchanged.
- The number of talks matching your filters is now much easier to spot: it leads the "Looking for something more specific?" header right by the top "Find Another"/"Show a List" buttons, and shows again as a small badge next to "Reset filters" by the bottom pair. Both update together and briefly highlight whenever a filter or search changes the count.

### Fixed
- Fixed the background glow appearing in a different spot on different pages (e.g. top on Favorites, right side on CFM) — it now stays anchored in the same place everywhere.
- Fixed the "Come, Follow Me" tab showing no matches the first time you opened it after updating the app — it would sit empty until you closed and reopened the app a second time. It now shows this week's matches right away.
- Fixed the home-screen widget on iOS never showing your streak, even with a streak active in the app.
- New users now see the streak badge on page load with an invitation to "Choose a talk to begin your streak" instead of it being hidden until after they open their first talk.
- Fixed the new Other Talks/Church Magazines/Hymns "go to the source, or see where it's cited" citation popup never actually reaching anyone's copy of the app — the data update behind it was stamped with an unchanged timestamp, so the app's background refresh treated it as nothing new and silently skipped it for everyone, indefinitely, not just until the next relaunch.

## [1.4] — 2026-08-31

### Added
- Added a "CFM" tab — talks matching this week's "Come, Follow Me" reading, ranked by how closely they match. The week heading is now a link straight to that week's real page in the Church's own manual. Use the arrows to browse other weeks. Most weeks match by cited scripture; Easter and Christmas now also match against real verse lists pulled from the Church's own Easter and Christmas scripture study pages (on top of matching the "Easter"/"Christmas" topic tag), and the very first week matches both Matthew 4:19 (the verse the program takes its name from) and every scripture referenced in that week's own manual page, plus talks that mention "Come, Follow Me" itself. Since a 6th tab didn't fit as plain text, the whole tab bar switched to small icons with short labels underneath, matching how most phone apps handle more than four or five tabs.
- Christmas morning and Easter now show a Christmas- or Easter-themed talk instead of whatever the daily rotation happened to land on. Also added themed picks for New Year's Day, Valentine's Day, the Relief Society anniversary (March 17), Restoration Day (April 6), Mother's Day, the Aaronic Priesthood restoration anniversary (May 15), Father's Day, Independence Day, Pioneer Day, and Thanksgiving.
- You can now swipe left or right to move between Home, Recents, Favorites, Notes, and Lists, instead of only tapping the links at the top of the page.
- Added a small calendar icon next to "Talk of the Day" — tap it to browse back through previous days and see what was featured, one month at a time. Only days with a real recorded pick are selectable. Days you've already opened show a small checkmark, same as the "Read" checkmark elsewhere in the app.
- "Find Another" and "Show a List" now also appear at the bottom of the filters/search area, so you don't have to scroll back up to reach them after searching or adjusting a filter. On narrower phone screens, both button rows now stay side by side instead of stacking.
- "Search titles & summaries" now also catches everyday words that aren't literally in a talk's title or summary but point to a real topic — searching "chastity" now also shows talks tagged with "Sexual purity," for example — with a small note explaining why those extra talks showed up.
- "Search titles & summaries" now also catches other forms of the same word — searching "gratitude" now also finds talks that say "grateful" or "thankful" instead, for example, with the same small explanatory note.
- Both of the above now kick in a few keystrokes earlier — typing just "chas" or "grat" already shows the extra matches, instead of needing the whole word typed out. If what you've typed so far could honestly mean more than one different thing, it waits for you to finish typing rather than guessing.
- The Topic and Speaker filters now offer a "Did you mean" spelling correction when a search comes up empty — typing "honessty" suggests "Honesty," and "Uctdorf" suggests "Uchtdorf, Dieter F.," for example. If a misspelling could plausibly mean more than one real topic or person, it won't guess — you'll just see "No matches" instead of a possibly-wrong suggestion.
- The "Come, Follow Me" tab now has the same Topic/Calling/Speaker/Conference/Session filters as the home page (labeled "Want to narrow down these matches?" there, since it's answering a different question than the home page's own filters), a Best Match/Most Recent sort, and pages through results 10 at a time — with "Select First 10"/"Select All" to add a whole page (or every match) to a list at once, same as "Show a List" already offers. Handy on a week with a lot of matches: filter down to just talks by a Calling you care about, then sort by whichever is more useful.
- Added a calendar icon to the "Come, Follow Me" tab, next to the page title — tap it to jump straight to any week in the year instead of clicking through one week at a time. The week you're currently viewing is outlined on the calendar so it's easy to see where you are.
- The "Come, Follow Me" tab now continues seamlessly into 2027's New Testament schedule right after 2026's Old Testament weeks end, so it won't go stale come January.
- Added a "This Week" link next to the calendar icon on the "Come, Follow Me" tab — appears whenever you've browsed to a different week, so there's always a quick way back to the current one.
- On the "Come, Follow Me" tab, a week's scripture title now stays on one line and trims with "…" if it's especially long, instead of occasionally wrapping onto two lines.
- Both calendar popouts (the "Talk of the Day" history calendar and the "Come, Follow Me" week picker) now support swiping left or right to move between months, in addition to the previous/next arrows.
- On the "Come, Follow Me" tab, tapping the "N citations match CFM" badge on a talk now shows exactly which scripture citations matched, each a real link to that verse.
- Tapping a scripture citation that appears both here and in the talk itself now asks where you'd like to go — the verse, or the exact spot in the talk that cites it — instead of only linking out to the verse. This works the same way everywhere a citation like that shows up, not just here — Show a List, Recently Viewed, Favorites, My Lists, and My Notes included.

### Changed
- On the "Come, Follow Me" tab, the "N citations match CFM" badge (formerly "N citations in range") now sits right next to the citation-type icons instead of on its own line below them, and its text now matches the size of the "Citations:" label beside it.
- Moved "Come, Follow Me" up to the 2nd tab (right after Home), instead of last — it's a weekly-lesson feature people come back to often, not just a place to review past activity like Recents/Favorites/Notes/Lists.
- The "Talk of the Day" heading and calendar icon above it now line up with the left and right edges of the card below, instead of sitting further apart from it — with a bit of breathing room kept between that row and the card, so the calendar icon doesn't sit flush against it.
- On the "Come, Follow Me" tab, the date range is now bigger and set apart from the explanation text below it, and that explanation is now a few short lines instead of one long sentence — and now says specifically how that week's talks were chosen (Christmas and Easter say topics & scriptures; every other week says scripture). The week's title and dates now stay properly centered between the previous/next arrows no matter how long or short the title is, instead of the arrows crowding in close on a short title. The Christmas/Easter explanation line is also shorter now, so it fits on one line on a phone instead of wrapping — every other week's explanation line now reads the same short way ("Matched by footnoted scripture.").
- Talk of the Day no longer repeats a talk until every talk in the app has had its turn — previously it was picked independently each day, so with thousands of talks in rotation the same one could resurface again after only a few weeks purely by chance.
- Shortened the footer's explanatory text and mentioned that session and citation data are pulled from the Church's own official records too, not just topics. Also narrowed the footer so its centered lines wrap into a tidy column instead of spanning the full width of the page.
- Added a few line breaks to the footer text so each sentence/clause sits on its own line, instead of relying on the browser to wrap it.
- Trimmed the footer's "Topics, sessions, & citations" line slightly so it fits on one line on more phone screens.

### Fixed
- The app was silently re-saving the entire offline talk database on every single launch, even when nothing about it had changed, which could bloat the app's on-device storage over time for no reason. It now only re-saves when the data actually has an update.
- Fixed the daily streak not resetting after a missed day until you opened another talk — if you skipped a day, the streak badge (and home-screen widget) now correctly shows the break as soon as you look at it, instead of still showing the old count until your next talk open.
- Fixed a data update silently never reaching anyone who'd used the app before it shipped — a missed timestamp update meant the app thought nothing had changed, so it kept serving the old cached data indefinitely instead of picking up the update on the next relaunch like it's supposed to.
- Fixed the "Talk of the Day" home-screen widget failing to build on iOS, which would have shown a blank/placeholder widget instead of today's talk.

### Changed
- The app's name is now written as "FindATalk" everywhere it appears, instead of "Find A Talk"/"Find a Talk."

## [1.3.1] — 2026-08-29

### Added
- Long notes no longer stretch a talk's tile out of shape — they're now clipped to 3 lines with a "Show more" link that expands the tile to show the whole note (and "Show less" to collapse it back), wherever a note preview appears (Show a List, Recently Viewed, Favorites, My Lists, My Notes).
- Show a List now has "Select First 10" and "Select All" buttons above the results, so you can add a whole page — or every matching talk, across every page — to a list in one action instead of checking boxes one at a time. Selecting more than what's shown on the first page asks you to confirm first, since it could mean adding a lot of talks at once. A selection now also stays checked as you page through results, instead of being cleared every time you click Next/Previous.
- The Topic filter's "Did you mean" suggestions now cover a lot more everyday words and phrases that aren't official topic names — things like "worry," "doubt," "money," "racism," "job," "teenagers," "breakup," "exercise," and many more now point you to the matching real topic instead of coming up empty.
- Talks that cite scripture now show a "Citations: Scriptures" pill wherever they appear — the ticket, Show a List, Recently Viewed, Favorites, and My Lists. Tap it to see every verse cited, each a real link straight to that verse on the Church's site. Talks with nothing to cite show no pill at all.
- The Citations row now also covers Other Talks (linking straight to that talk in the app), Hymns (linking to the hymn), and Church Magazines (linking to the Ensign/Liahona article) — each only shows up when a talk actually cites that kind of thing. A few older citations to books, personal correspondence, and similar unlinkable sources now show too, under "Other Sources," as plain text since there's nowhere to send you.
- Added a "Search Scriptures & Hymns" box on the home page, right below the existing title/summary search — type a verse (like "Alma 32") or a hymn (like "I Am a Child of God") and it narrows things down to talks that actually cite it.

### Changed
- A talk you draw with "Find Another" now appears above the Find Another/Show a List buttons instead of below them, so those buttons stay a short, fixed distance from the filters underneath — no more scrolling past a drawn talk to reach "Show a List" after adjusting a filter. The now-redundant "Find Another" button inside the drawn talk's card was removed (the one right below it does the same thing), letting "Open This Talk" take the full width of its row.
- On every talk row (Show a List, Recently Viewed, Favorites, My Lists, My Notes), the Favorite/Add to List/Add Note/Share icons moved from squeezed in next to the title down to a centered row at the bottom of the tile — matching how they already look on a drawn talk. The title now always gets the full width of its row (fixing an awkward early line-break some titles had), and the select checkbox in Show a List stays centered beside the title even when it wraps onto two lines.
- Tightened up the filters section on the home page to make room for the new Scripture/Hymn search without the page getting any longer: removed the "Recent/Favorites" filter (Recently Viewed and Favorites already have their own search on their own pages), tightened the spacing under each filter's label, and combined "Reset filters" with the "N talks match" count into one line instead of two.
- Scripture citations now always show in a short, consistent abbreviated form ("D&C 1:38," "1 Cor. 15:29") instead of however the original talk happened to write it — some were spelled out in full, and a few were genuinely confusing out of context ("verse 79," "chapter 13") since they were just whatever text the original talk's author had linked. Where they link to is unchanged, only how they're labeled.

### Fixed
- Talks with citations could silently stop showing them (and Search Scriptures & Hymns could silently stop finding anything) for people upgrading from an older version, unless they cleared the app's storage — which also would have wiped their favorites, notes, lists, and streak. The talk data itself now caches separately from your personal data, so this can't happen and nothing needs to be cleared.
- Export Backup silently did nothing on Android and iOS — tapping it saved no file anywhere, even though it looked like it worked. It now saves a real copy straight to your device (in Files, under Documents) every time, and also opens the share sheet so you can send it to Drive, email, etc. if you'd rather.
- Editing a note on a talk (e.g. on Talk of the Day) didn't refresh that talk's note preview on screen — the old text stuck around until you restarted the app, even though the change had actually saved (My Notes and everywhere else showed it correctly). Note previews now update immediately everywhere the talk is shown.
- Searching Scriptures & Hymns now understands abbreviations both ways — "D&C 1:38" and "Doctrine and Covenants 1:38" (or "1 Ne." and "1 Nephi," "Ps." and "Psalms," and every other standard scripture abbreviation) now find the exact same talks.
- Searching a single verse now also finds talks that cite a range including it — searching "Alma 32:3" now finds a talk that cites "Alma 32:1–5," not just an exact "32:3" match.
- "Doctrine & Covenants" (with the ampersand) is now recognized too, alongside "D&C" and "Doctrine and Covenants" — all three find the same talks.
- Searching "Eph." (Ephesians) no longer also pulls in unrelated Zephaniah citations (it was matching "Eph." as a piece of "Zeph."). Found and fixed by checking every book's search against the other 100, not just the one being tested at the time.

## [1.2] — 2026-08-28

### Added
- Before asking for notification permission, the app now shows a short explanation of why (a daily reminder with your talk of the day) instead of the phone's permission prompt appearing out of nowhere.
- "Show a List" now has "Previous 10" / "Next 10" buttons, so you can page through every matching talk (e.g. everything by one speaker) instead of only ever seeing the first 10.
- Added a Settings menu, opened from the small gear icon in the top-right corner, with a Light / Dark / System appearance choice — replacing the old floating dark-mode button.
- The Settings menu also has an on/off switch for the daily reminder notification, so you can turn it on later if you skipped it the first time, or turn it off without digging into your phone's app settings.
- The Settings menu now also lets you pick what time your daily reminder shows up, instead of it always being fixed at 8:00 AM.
- The home-screen "Talk of the Day" widget now follows your phone's dark mode setting too, instead of always showing the light version.
- If you pick Light or Dark in Settings, the widget now matches that choice too, instead of only ever following the phone's overall setting.
- The Settings menu now has a Color Palette choice — Brass (the original look), Rose, Slate, or Sage — that works alongside Light/Dark/System and applies instantly.
- The home-screen "Talk of the Day" widget now matches your chosen Color Palette too, not just Light/Dark.
- Added a note button (the pencil icon) on every talk, next to Favorite and Add to List, for jotting down a quick "what I learned" note. Notes show up wherever that talk appears, and there's a new "My Notes" page (next to My Lists in the menu) for browsing everything you've written, with the same filtering and sorting as Favorites. Notes are backed up along with Favorites and My Lists in Export/Import Backup.
- Added a new "Session" filter (Saturday Morning/Afternoon/Evening, Sunday Morning/Afternoon, General Priesthood, General Women's, or Other) alongside the existing five, with every one of the 4,054 talks correctly tagged to the real session it was given in. "Saturday Evening" is its own option since the Church replaced the old standalone Priesthood broadcast with an open-to-everyone evening session starting in 2020.
- My Notes now has a search box, searching what you wrote plus the talk's title, speaker, calling, and topic.
- My Lists now has a search box for finding a list by name, and a sort toggle — "Recently Updated" (lists you've added a talk to most recently come first) or "Alphabetical."

### Changed
- Reordered the filters to Topic, Calling, Speaker, General Conference, Session, Recent/Favorites, and moved the "Search titles & summaries" box to sit below the filters instead of above them.
- Removed the Speaker/Calling/Conference/Topic filters from Recently Viewed, Favorites, My Notes, and each individual List — those collections are small and personal, so a search box (now on all four, matching title, speaker, calling, and topic — not just title/speaker like before) plus the existing sort options gets you to a talk faster than filter menus did. Also added search and a "Recently Added" / "Conference Date" sort to a List's own page, which had neither before.
- Moved Export Backup / Import Backup to the bottom of the My Lists page, below your actual lists, instead of at the top.
- The "From General Conference of The Church of Jesus Christ of Latter-day Saints" line at the top of the page now wraps at the same fixed spot on every device, instead of the browser breaking it differently depending on screen width.
- The Settings gear icon no longer floats over the page while you scroll — it now sits quietly in the top-right corner of the page itself, styled to match the thin divider line under the title instead of standing out.
- Replaced the app's headline font with Lora, a calmer, more traditional serif — used for the title, talk titles, list items, and menu headers throughout.
- Rebalanced the Home page around picking a random talk instead of filtering: "Find Another" and "Show a List" now sit right under Talk of the Day, above the filters, instead of below them. The filters are grouped under a "Looking for something more specific?" box further down the page. A talk you draw appears right above that box; a list you show still appears below it.
- Reordered the buttons on a drawn talk into three clear groups: Open This Talk + Find Another first, then Previous/Next, then Favorite/Add to List/Add Note/Share — instead of one run-together row.
- The Favorite/Add to List/Add Note/Share buttons on a drawn talk are now small circle icons (matching Talk of the Day and every list row) instead of labeled buttons, so they fit on one line under Previous/Next instead of stacking into four separate rows on a phone. Whether a talk's already favorited, on a list, or has a note now shows as a filled icon plus a tooltip, the same way it already works everywhere else in the app.
- Moved the Sort control (Random / Most Recent) from under the Find Another/Show a List buttons to right above the list itself in "Show a List," so it's never scrolled out of reach once a long list is on screen. (It only ever affected "Show a List" anyway — "Find Another" was always a true random pick.)
- In "Show a List," the "Showing 1–10 of X talks that match" line now sits above the Sort control with proper spacing, instead of the two nearly touching, and dropped the redundant "right now" from the end of the sentence.
- Tightened and evened out the spacing around the Sort control in "Show a List" — it was crowding "Showing 1–10 of X talks that match" above it while touching the first talk in the list below; both gaps now match.
- The streak badge under Talk of the Day ("🔥 Day 1 — come back tomorrow...") now lines up its left edge with the Talk of the Day card above it, instead of sitting further left, on wider screens.

### Fixed
- The home-screen "Talk of the Day" widget could show a different talk than the app for the same day. It now always picks the same one.
- The widget's streak count could sit stale for a long time after your streak actually changed. It now updates right away.
- Tapping the "Talk of the Day" widget now opens the app instead of jumping straight to the talk in your browser — open it from there once you're in the app.
- Tapping the widget when the app was already open in the background could drop you wherever you'd left it (mid-list, a note open, etc.) instead of the Home screen. It now always opens to Home.
- On iPhone, the new Settings button sat partly under the status bar / Dynamic Island and couldn't be tapped. It's now positioned clear of them.
- The "FindATalk" button's text was unreadable in dark mode (dark text on a dark button). It's light text again.
- On Android, a long talk title in the small widget size could spill text out past the bottom of the card. The title now stays on one line (shortened with "…" if needed), the widget's spacing is tighter so there's reliably enough room for the streak line too, and the speaker name is a touch smaller for a cleaner look.
- On some tablets, the widget defaulted to a much taller size than needed. It should now offer the same compact size as on phones (remove and re-add the widget to get the new default — an existing placed widget won't resize itself).
- If the app was left open in the background overnight, the "Talk of the Day" and streak badge could keep showing yesterday's pick after midnight until you fully closed and reopened it. They now refresh automatically as soon as you bring the app back to the foreground.
- On a narrow phone screen, the "My Notes" and "My Lists" menu labels could wrap onto two lines each, making the top menu look ragged. Shortened them to "Notes" and "Lists" and tightened the spacing between menu items so the whole row fits on one line.
- Tapping "Show a List" scrolled a little too far, landing right on top of "Showing 1–10 of…" with almost no room to breathe. It now stops with a bit of the filter box still visible above it.

## [1.0.0] — initial release

Baseline — first version submitted to the stores. Everything before this
point is tracked in git history, not here.
