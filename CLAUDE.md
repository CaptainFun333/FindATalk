# FindATalk — project instructions for Claude

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

`capacitor.config.json` has no `server.url` — the native apps bundle a
**local copy** of `docs/` (`webDir: "docs"`), not a live page. There is no
general "no store submission needed" case for `docs/index.html` changes;
what actually reaches native users without a new build depends on which
file changed:

- **`docs/data.json` only** (talk data): genuinely live — `index.html`'s
  `loadData()` fetches the current copy from `REMOTE_DATA_URL`
  (`https://findatalk.com/data.json`) in the background and swaps it in
  once it lands. No new build needed on either platform.
- **`docs/index.html` itself** (JS/HTML/CSS — logic, markup, styling,
  new features): the website (findatalk.com) gets it immediately, since
  browsers load it live via GitHub Pages. The native apps do **not** —
  they keep running whatever `index.html` was bundled into their last
  build until a new one ships. Any change here needs new iOS/Android
  builds before existing installs see it, even though it's a "web-only"
  file living under `docs/`.
- **Native fixes** (`android/`, `ios/`): requires a version bump
  (`versionCode`/`versionName` in `android/app/build.gradle`), a new signed
  build (`./gradlew bundleRelease` for Android), and manual upload through
  Play Console / App Store Connect (credentials/2FA — user does this step).

When logging a changelog entry for an `index.html` change, don't assume it
ships for free — call out that it needs a new native build, the same way
existing entries already do for native-only fixes.

## Decisions log process (applies in every conversation/session)

This repo also keeps `DECISIONS.md` at the root — a short, one-or-two-line-
per-entry log of *why* a non-obvious call was made (a feature held back on
purpose, a design tradeoff, a rejected approach), separate from
`CHANGELOG.md` (user-facing "what changed") and `PROJECT_HANDOFF.md`
(full architecture/history detail).

**Any time this conversation or any other makes or confirms a decision that
isn't self-explanatory from the code — holding a finished feature back,
choosing one approach over another for a stated reason, cancelling or
pausing a planned piece of work — add a bullet to `DECISIONS.md`, newest
entry at the bottom, before considering the task done.** Format:
`- **YYYY-MM-DD** — one or two sentences, including the *why*.` Commit it
in the same commit as the change it describes, same as the changelog rule
above. Routine bug fixes and straightforward feature adds don't need an
entry here — only ones where the reasoning would otherwise be lost.

## Engineering notes process (applies in every conversation/session)

This repo also keeps `ENGINEERING_NOTES.md` at the root — purely for
future Claude sessions, not for Brad and never for users. It's where
non-obvious technical discoveries go: a bug whose real cause was
surprising, a platform requirement that isn't documented anywhere
official (Play Console, App Store Connect, a library's undocumented
floor version), a race condition or gotcha that cost real debugging time
to find.

**Any time this conversation or any other tracks down a root cause that
wasn't where you'd expect, or discovers a platform/library requirement
that isn't obvious from official docs, add a short entry to
`ENGINEERING_NOTES.md`** under the relevant heading (or a new one),
before considering the task done. Write it for a Claude session with zero
memory of this conversation — state the surprising fact and the fix, not
a narration of how it was found. Commit it in the same commit as the fix
it documents. Routine bugs with an obvious cause don't need an entry —
only ones where the lesson would otherwise be lost.

**Never move or copy this file into `docs/`** — that folder is served
live at findatalk.com; `ENGINEERING_NOTES.md` must stay off the public
site. It is not linked from `docs/ledger.html` for the same reason.

## Project ledger page

`docs/ledger.html` is a live-updating page (findatalk.com/ledger.html) that
reads `CHANGELOG.md`, `DECISIONS.md`, and recent commits directly from
GitHub client-side (`raw.githubusercontent.com` + the GitHub REST API) — it
needs no build step and no Action. Keeping `CHANGELOG.md` and
`DECISIONS.md` up to date (per the two processes above) is what keeps this
page current; the page itself should only need edits when its static
"Style Guide" tab goes stale against `docs/index.html`'s actual palettes/
type/shape tokens.

See `PROJECT_HANDOFF.md` for full architecture/history detail.
