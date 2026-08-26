# Find a Talk — project instructions for Claude

## Changelog process (applies in every conversation/session)

This repo keeps a `CHANGELOG.md` at the root. **Any time a bug fix, feature,
or user-visible change is made to this app — in this conversation or any
other — update `CHANGELOG.md` as part of that same change, before
considering the task done.**

Rules:
- Add a one-line bullet under the `## [Unreleased]` section, in the
  appropriate subsection (`### Fixed`, `### Added`, `### Changed`,
  `### Removed` — create the subsection heading if it's the first entry of
  that kind since the last release). Replace a placeholder "Nothing yet."
  line the first time something is added.
- Write the bullet for a user, not for a future Claude session — plain
  language, no file paths or internal implementation detail (that detail
  still belongs in `PROJECT_HANDOFF.md` if it's worth preserving for future
  development context, not in the changelog).
- Do this for both native fixes (Java/Kotlin/Swift, `android/`, `ios/`) and
  web-content fixes (`docs/index.html`, `docs/data.json`) — even changes
  that ship without a new store build still belong here, since it's the
  single running record of what changed and when.
- Commit the changelog edit together with the code change it describes,
  same commit, not as an afterthought commit later.

When a version is actually built and submitted to the App Store / Play
Store:
1. Rename `## [Unreleased]` → `## [x.y.z] — YYYY-MM-DD` (the version you're
   about to ship), matching the `versionName` bumped in
   `android/app/build.gradle` (and the iOS equivalent in `ios/App/App.xcodeproj`
   / `Info.plist` if that's also changing).
2. Add a fresh empty `## [Unreleased]` section above it with a
   "Nothing yet." placeholder, ready for the next round of fixes.
3. The `### Fixed` / `### Added` bullets already accumulated under
   `Unreleased` become that version's release notes — copy them (lightly
   cleaned up) into the Play Console / App Store Connect "What's new" field
   when submitting.

## Release process summary

- **Web-only fixes** (`docs/`): commit + push to `main` → GitHub Pages
  redeploys automatically → users get it on next app relaunch (background
  refresh, not mid-session). No store submission needed.
- **Native fixes** (`android/`, `ios/`): requires a version bump
  (`versionCode`/`versionName` in `android/app/build.gradle`), a new signed
  build (`./gradlew bundleRelease` for Android), and manual upload through
  Play Console / App Store Connect (credentials/2FA — user does this step).

See `PROJECT_HANDOFF.md` for full architecture/history detail.
