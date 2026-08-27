# Changelog

All notable changes to Find a Talk are logged here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/): grouped by version, with
`Fixed` / `Added` / `Changed` / `Removed` subsections as needed.

`Unreleased` collects everything since the last version that was actually
built and submitted to a store — see `CLAUDE.md` for the process that keeps
this updated.

## [Unreleased] — targeting 1.1

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
- Added a new "Session" filter (Saturday AM/PM, Sunday AM/PM, General Priesthood, General Women's, or Other) alongside the existing four. For now every talk shows up under "Other" — tagging talks with their real session is a separate, in-progress data project.

### Changed
- Reordered the filters to Calling, Topic, Speaker, General Conference, Session, Recent/Favorites, and moved the "Search titles & summaries" box to sit below the filters instead of above them.
- The "From General Conference of The Church of Jesus Christ of Latter-day Saints" line at the top of the page now wraps at the same fixed spot on every device, instead of the browser breaking it differently depending on screen width.
- The Settings gear icon no longer floats over the page while you scroll — it now sits quietly in the top-right corner of the page itself, styled to match the thin divider line under the title instead of standing out.
- Replaced the app's headline font with Lora, a calmer, more traditional serif — used for the title, talk titles, list items, and menu headers throughout.

### Fixed
- The home-screen "Talk of the Day" widget could show a different talk than the app for the same day. It now always picks the same one.
- The widget's streak count could sit stale for a long time after your streak actually changed. It now updates right away.
- Tapping the "Talk of the Day" widget now opens the app instead of jumping straight to the talk in your browser — open it from there once you're in the app.
- On iPhone, the new Settings button sat partly under the status bar / Dynamic Island and couldn't be tapped. It's now positioned clear of them.
- The "Find a Talk" button's text was unreadable in dark mode (dark text on a dark button). It's light text again.
- On Android, a long talk title in the small widget size could spill text out past the bottom of the card. The title now stays on one line (shortened with "…" if needed), the widget's spacing is tighter so there's reliably enough room for the streak line too, and the speaker name is a touch smaller for a cleaner look.
- On some tablets, the widget defaulted to a much taller size than needed. It should now offer the same compact size as on phones (remove and re-add the widget to get the new default — an existing placed widget won't resize itself).
- If the app was left open in the background overnight, the "Talk of the Day" and streak badge could keep showing yesterday's pick after midnight until you fully closed and reopened it. They now refresh automatically as soon as you bring the app back to the foreground.

## [1.0.0] — initial release

Baseline — first version submitted to the stores. Everything before this
point is tracked in git history, not here.
