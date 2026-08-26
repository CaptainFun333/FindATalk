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
- Added a dark mode toggle. It follows your phone/browser's light or dark setting by default, or you can override it with the new sun/moon button in the top-right corner — your choice is remembered.

### Fixed
- The home-screen "Talk of the Day" widget could show a different talk than the app for the same day. It now always picks the same one.
- The widget's streak count could sit stale for a long time after your streak actually changed. It now updates right away.
- Tapping the "Talk of the Day" widget now opens the app instead of jumping straight to the talk in your browser — open it from there once you're in the app.
- On iPhone, the new dark mode button sat partly under the status bar / Dynamic Island and couldn't be tapped. It's now positioned clear of them.
- The "Find a Talk" button's text was unreadable in dark mode (dark text on a dark button). It's light text again.

## [1.0.0] — initial release

Baseline — first version submitted to the stores. Everything before this
point is tracked in git history, not here.
