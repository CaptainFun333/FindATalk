# Engineering notes

Not for users, not even really for Brad — this is for whichever Claude
session touches this codebase next. A running list of **surprising
technical discoveries**: platform quirks, gotchas, and non-obvious root
causes that were expensive to find once and would be expensive to
re-find. If a bug's real cause wasn't where you'd guess, or a platform
silently requires something undocumented, it belongs here.

This is not `CHANGELOG.md` (user-facing) and not `DECISIONS.md` (why a
product/design call was made) — it's implementation-level. See `CLAUDE.md`
for when to add to it. Never move this file under `docs/` — that folder is
served live at findatalk.com; this one should never be public.

---

## Cloud sync

- **A "successful" write can still be a silent data loss.** Full-replace
  sync writes overwrote whatever was in the cloud with whatever the local
  device had, so two devices syncing near-simultaneously could have one
  silently erase the other's changes. Fix: every sync now merges the
  latest cloud state in before saving, not just at pull time.
- **One bad field can zero out an entire sync if the merge isn't
  fault-isolated.** A single malformed value in one part of the synced
  payload (e.g. streak data) could throw and abort merging *everything*
  else in that sync too. Fix: merge each piece of data independently, so
  a failure in one can't take down the rest — streak in particular now
  merges first and separately from favorites/notes/lists.
- **A failed background sync can look successful to the app.** A bug
  treated a failed cloud write as if it had succeeded, so it never
  retried — data could sit stuck on one device indefinitely with no
  visible error.
- **iOS WebView doesn't reliably report Google Sign-In completion.** A
  bug in Apple's WKWebView meant the app never found out sign-in had
  finished, even though it actually had — needed an explicit workaround
  rather than trusting the WebView's own completion signal.
- **Android's Google Sign-In can fail with "Account reauth failed" for
  reasons unrelated to the account.** Root cause was an outdated
  *pre-release* build of the Google Sign-In library — pin to a stable
  release, not a prerelease, even if it was the latest at integration
  time.

## Data updates / caching

- **The app silently skips an update if its timestamp doesn't change.**
  The background data-refresh logic compares timestamps to decide if
  there's anything new — if a data file is edited but its stamped
  timestamp isn't bumped, the update ships to GitHub Pages but every
  existing install keeps serving stale cached data *indefinitely*, not
  just until next relaunch. Always bump the timestamp on any real data
  change, even one that looks trivial.
- **Talk data and personal data must cache separately.** Early on, both
  lived in one cache bucket — clearing/upgrading could wipe a user's
  favorites/notes/lists/streak along with just the talk database. Keep
  them in independent storage so one can be invalidated without touching
  the other.

## Store / platform requirements (not documented clearly by either store)

- **Play Console silently requires lowercase-only product IDs** for
  in-app purchases — mixed-case IDs that worked in testing get rejected
  (or need to be recreated) at submission time.
- **Play Console has a minimum Play Billing library version** (8.0+) that
  isn't obviously flagged until a submission is rejected for it — worth
  checking the current floor before every release, since Google moves it.
- **Play App Signing re-signs the app with a certificate Google holds**,
  different from the upload certificate — Android App Links / deep
  linking (`assetlinks.json`) needs *that* certificate's fingerprint
  listed as trusted, not the one used to sign the upload, or verified
  links silently fall back to opening in the browser instead of the app.
- **Facebook will not render a pre-filled share caption**, regardless of
  what the Open Graph tags or share-sheet text say — this is a platform
  restriction on all link shares, not something fixable from this app's
  side. Don't spend time trying to work around it again.

## UI / cross-platform behavior differences

- **Android and iOS detect "returned to the app" differently.** A fix
  that reliably marked a talk read / advanced the streak on iOS did
  nothing on Android — the two platforms needed separate detection paths
  for "user came back to the app after opening a talk elsewhere."
- **A "read" / streak credit needs a deliberate delay, not an instant
  trigger**, so an accidental tap or rapid-click-through doesn't
  false-credit a read or inflate a streak — current values are ~10s
  before a talk counts as read, ~60s before the streak advances.
