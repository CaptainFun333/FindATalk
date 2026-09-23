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

## Cloud sync (Firestore / Firebase Auth)

- **Sync merge is additive/union-only by design — a deletion on one
  device does not propagate to others via sync**, and a conflicting note
  is queued for manual user resolution rather than auto-merged. If you
  touch the sync/merge code, preserve this; don't "fix" it into
  last-write-wins, that's what caused the data-loss bugs below in the
  first place.
- **Not everything syncs.** Only favorites, read state, visit counts,
  collections, notes, and streak sync (the field set in
  `exportBackupData()`). `recentKeys`, `earnedBadges`, Talk-of-the-Day
  history, and device prefs (theme/palette/reminders/onboarding/sort
  order) are local-storage-only and permanently lost if that device is
  lost, even for signed-in users.
- **A "successful" write can still be a silent data loss.** Pushing local
  data to Firestore via `setDoc()` without first pulling and merging the
  latest cloud state can silently overwrite another device's concurrent
  additions (e.g. favorites added on one device vanishing after another
  device's push overwrote the doc). Fix: `pushLocalDataToCloud` always
  pulls and merges the latest cloud state before saving.
- **One bad field can zero out an entire sync if the merge isn't
  fault-isolated.** A single malformed value in one part of the synced
  payload could throw and abort merging *everything* else in that sync
  too. Streak in particular now merges first and independently from
  favorites/notes/lists so one can't take the other down.
- **A failed background sync can look successful to the app.** A push
  failure must not set the same "sent" flag a real successful push sets —
  an earlier bug did exactly that, which silently blocked all future
  retries for that data with no visible error.
- **The old cross-device streak merge picked whichever device's
  `lastDate` was more recent and adopted that whole side's `count`** — so
  a freshly-opened device with a 1-day streak could silently overwrite
  another device's real 8-day streak, and a separate "stale streak"
  self-heal (`settleStreak()`) could then zero it out entirely. Fix:
  recompute the streak from the **union** of both devices' actual active
  days, never pick a "winning" side.
- **Firestore security rules default-deny.** A brand-new collection
  (e.g. `donations/{uid}`) is not automatically covered by existing
  per-user rules — it's blocked until an explicit rule is added.
  `firestore.rules` needs updating as a matching step whenever a new
  collection is introduced, not an afterthought discovered via a live
  `permission-denied` error at first real use.
- **`signInWithCredential()` can simply never resolve inside a WKWebView**
  — a known upstream Firebase JS SDK bug on iOS, not an app bug. Any code
  that awaits that promise directly hangs forever on iOS specifically;
  the correct pattern is to listen for `onAuthStateChanged` instead of
  awaiting the sign-in call. A retry-guard flag meant to stop
  double-listener-attachment has previously also blocked the legitimate
  delayed retry from this workaround — reset that guard properly in the
  *stop* path, not only on success, or the app ends up only half-syncing
  (pushes work, but nothing is ever pulled/listened for).
  - Native platforms used to bridge the native Sign in with Apple/Google
    credential into the Firebase **Web** SDK (`window.firebaseWeb`) via
    that same `signInWithCredential()` call, because Firestore access
    went through the web-SDK bridge — and that bridge only ran at the
    moment the sign-in button was tapped, so a normal relaunch with an
    already-signed-in native session never re-bridged it:
    `window.firebaseWeb.auth.currentUser` silently stayed `null` forever
    and sync just never started, with no error logged. This is why sync
    could appear to "randomly" break on iOS after any relaunch. Fixed by
    switching to the native `@capacitor-firebase/firestore` plugin
    (`skipNativeAuth: false`), which reuses the native Firebase Auth
    session directly — no web-SDK bridge needed at all.
- **When several iOS auth failures compound, they aren't necessarily one
  bug.** A debugging session once had the WKWebView promise-hang above,
  an SPM package name collision, and a missing Google URL scheme (a
  silent crash on Google sign-in) all hiding behind each other at once.
- **Apparent iOS-simulator sync failures can just be a stale, over-reused
  simulator**, not a real bug — after a dozen-plus install/relaunch
  cycles the WKWebView can carry stale state. If sync looks broken only
  on a heavily-reused simulator, try a fresh install or a real device
  before chasing more code.
- **There's no sandbox/test-account system for "Sign in with Apple"**
  (unlike StoreKit's sandbox testers) — testing multi-device sync
  genuinely requires a dedicated test Apple ID. iOS Simulator tip:
  Features → Face ID → Enrolled, then Features → Face ID → Matching Face
  instantly approves the biometric prompt without typing a password.
- **Google's OAuth consent screen shows the raw Firebase-generated
  domain** (`findatalk-28e26.firebaseapp.com`), not the app name — this
  is controlled entirely in Google Cloud Console (OAuth consent screen
  "App name" + a custom Firebase Auth domain like `auth.findatalk.com`),
  not fixable from app code at all.

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
  (or need to be recreated) at submission time. IDs are effectively
  **permanent once created** — a typo can't be edited in place, only
  deleted and recreated under a new ID.
- **You can't create Play Console in-app products until *some* build has
  been uploaded** — but Play never checks that build's bundled product-ID
  strings against what you create; it only gates on "a build exists at
  all." So it's not really a chicken-and-egg problem: upload any build
  first, then create the real products, matching strings baked into a
  later build.
- **Play Console has a minimum Play Billing library version** (8.0+) that
  isn't obviously flagged until a submission is rejected for it — worth
  checking the current floor before every release, since Google moves it.
- **`play-services-auth` 22.0.0 deleted the legacy `GoogleSignIn` /
  `GoogleSignInClient` classes** that the Capacitor Firebase Auth plugin's
  Java code still references directly — the Android build breaks above
  that version. Cap at 21.6.0 (newest version that still has them) until
  the plugin itself updates.
- **`firebase-auth`'s Android SDK transitively re-pins `androidx.credentials`
  to a pre-release RC build even in its own latest published version** —
  bumping the version in `variables.gradle` alone doesn't override it,
  because firebase-auth keeps re-asserting its own pin. Needed a global
  `resolutionStrategy.force` block in `android/build.gradle`, confirmed
  with `./gradlew :app:dependencyInsight`.
- **Play App Signing re-signs the app with a certificate Google holds**,
  different from the upload certificate — Android App Links / deep
  linking (`assetlinks.json`) needs *that* certificate's fingerprint
  listed as trusted, not the one used to sign the upload, or verified
  links silently fall back to opening in the browser instead of the app.
- **A package name (`applicationId`) is permanently reserved on Play once
  published, even after unpublishing** — a "new paid version of the same
  app" needs a different package name; only the display title can be
  reused. Play also doesn't allow flipping an already-free app's base
  price to paid later (Apple does allow this for new downloads) — the
  workaround is gating features behind an in-app purchase with a local
  grandfathering flag, not trying to change the base price.
- **Android Developer Verification (2026) requires the package name +
  signing key to be registered against a verified developer identity**,
  separate from Play App Signing. If Google's registry shows a
  "conflict" for an app you legitimately own, it can be a false conflict
  from a cross-store package-name collision, not an actual problem —
  check the Identity tab and current account first. Resolution is by
  install-share: a key with >50% of installs gets automatic priority, one
  with 50+ installs is eligible to register itself, otherwise it needs
  manual approval with proof of ownership (a signed verification APK).
- **Xcode "Upload completed with warnings" about missing dSYMs for
  `FirebaseFirestoreInternal`, `grpc`, `grpcpp`, `absl`, `openssl_grpc` is
  expected and benign** — these ship as precompiled SwiftPM binary
  frameworks with no dSYMs available, there's no source-side fix, and it
  does not block App Store review. The only effect is unsymbolicated
  stack frames if a crash ever originates inside Firestore's native
  networking layer.
- **Sign in with Apple and Google sign-in share zero code on iOS** — the
  Apple path (`AppleAuthProviderHandler`, generic Firebase `OAuthProvider`
  + browser redirect) is entirely separate from the Google Credential
  Manager path. A fix to one never touches the other, even on the same
  platform.
- **Play Console's Data Safety declaration and Apple's App Privacy
  "nutrition label" are separate, structured forms**, not just the store
  listing text — adding a feature like accounts/cloud sync can make the
  listing copy accurate while these forms silently go stale, which is a
  rejection/flag risk both stores check independently of listing text.
- **Facebook will not render a pre-filled share caption**, regardless of
  what the Open Graph tags or share-sheet text say — this is a platform
  restriction on all link shares, not something fixable from this app's
  side. Don't spend time trying to work around it again.
- **Targeting SDK 35+ (Android 15+) makes the OS draw edge-to-edge
  unconditionally — there is no manifest flag or theme attribute to opt
  out**, and Capacitor's `BridgeActivity` (still true as of `@capacitor/
  android` 8.5.0) does nothing to compensate; it neither enables
  edge-to-edge deliberately nor pads the WebView for it. Left alone, the
  WebView's content draws under the status/nav bars on affected devices
  (Play Console flags this as "Edge-to-edge may not display for all
  users" under App warnings). Fixed by attaching a
  `ViewCompat.setOnApplyWindowInsetsListener` to `getBridge().getWebView()`
  in `MainActivity.onCreate()` that pads the WebView by
  `WindowInsetsCompat.Type.systemBars()` — simpler and more reliable here
  than trying to thread `env(safe-area-inset-*)` through Android's WebView,
  which (unlike iOS's WKWebView) doesn't consistently report those insets
  to CSS without native help.

## In-app purchases (StoreKit / Play Billing)

- **"App Apple ID" (the numeric App Store Connect identifier, e.g.
  `6807210681`) is a completely different value from the developer's
  Apple ID login email** — easy to conflate; the purchase-verification
  code needs the numeric one specifically.
- **Purchase verification is done via offline signature checks**
  (StoreKit 2 / Play Billing signed receipts) rather than calling out to
  Apple/Google APIs — deliberate, avoids needing store API credentials in
  the Cloud Function.
- **Android Play Billing has no simulator/offline test path** equivalent
  to iOS's Simulator — real testing requires an actual Play Console
  internal test track.
- **StoreKit's `displayPrice` and Play Billing's `getFormattedPrice()`
  format the same price differently** ("$3.00" vs "$3") even from
  identical shared JS — swapping in the store's native formatted price
  string makes iPad and Android show visibly different-looking labels for
  the same tier. Fix: don't use native price formatting for the tier
  labels at all; hardcode static labels instead.
- **New IAP code once got accidentally nested inside `initApp()`'s
  closure instead of top-level**, which silently broke an unrelated
  function (`renderBadgesList()`) elsewhere in the file — a reminder that
  top-level function placement in this single-file app is easy to get
  wrong and can break features that have nothing to do with what you're
  adding. See "closure-scoping trap" below.

## Sharing a generated file (Capacitor Share vs. Web Share API)

- **Capacitor's native `Share` plugin has no `files` array parameter at
  all** — unlike the Web Share API, it only ever takes a `url` pointing at
  a real on-device file path. To attach a generated image (or any other
  file) to a native share, write it to disk first via the `Filesystem`
  plugin (`writeFile({..., directory:'CACHE'})`, base64-encoded), then pass
  the returned `uri` as `Share.share({url})` — the same pattern
  `saveBackupToFile()` already used for exporting the JSON backup, just
  for an image instead of a document. `navigator.share({files:[File]})`
  is a completely different, unrelated API shape that only applies on the
  plain-web path (`navigator.share`), gated behind
  `navigator.canShare({files})` since not every browser with
  `navigator.share` also supports file attachments.
- **A canvas `Blob` cannot be handed to either share path directly.** For
  Capacitor's `Filesystem.writeFile`, it needs to become a base64 string
  first (`FileReader.readAsDataURL`, strip the `data:...;base64,` prefix).
  For the Web Share API, it needs to become a `File` object
  (`new File([blob], filename, {type})`) — `Blob` alone doesn't satisfy
  `navigator.canShare({files})`.

## App architecture / code-organization gotchas

- **Closure-scoping trap:** several long-standing helpers (e.g.
  `CHECK_ICON_SVG`) are defined *inside* `initApp()`'s closure, not at
  top level. A new top-level function that references them directly
  breaks silently (undefined reference) — this has happened more than
  once. The established fix pattern is an indirection slot (e.g.
  `onReadBadgeHtml`) assigned from inside `initApp()`, rather than
  referencing the closure-scoped constant directly from a top-level
  function.
  **Another concrete instance (idea 73, My Stats):** `TALKS_BY_KEY` (the
  O(1) key→talk lookup) is built inside `initApp()`, not top-level —
  despite being one of the most obviously-reusable-looking constants in
  the file. A new top-level feature needing "look up a talk by its key"
  either needs the indirection-slot pattern, or can fall back to a plain
  `TALKS.find(t => talkKey(t) === key)` linear scan (`TALKS` itself
  *is* top-level) when the lookup only runs on a rare user action (a
  modal open, a button click) rather than in a hot loop — cheap insurance
  that avoids a new slot for a one-off read.
- **Per-talk UI elements need a broadcast-refresh pattern, or they go
  stale.** Favorite-star buttons were originally built as isolated
  closures per view (`createFavoriteButton()`), so toggling a favorite
  only updated the button that was clicked (plus two hardcoded special
  cases) — any other view rendering the same talk (Talk of the Day,
  Recently Viewed, etc.) kept showing a stale star. The general fix
  already used elsewhere in the app: tag each instance with
  `data-talk-key`, stash a `_sync*Badge` function per instance, and
  broadcast a refresh to every on-screen copy by key whenever that talk's
  state changes. Check whether any *new* per-talk indicator (a badge,
  read state, a note) was wired up without this broadcast — it's an easy
  thing to miss.
- **`checkPendingRead()` runs synchronously at the very top of app
  startup and on every foreground event, ahead of anything else.** That
  strict serialization is what makes it safe to backdate streak credit to
  "the day the talk was opened" instead of "the day the app was
  reopened" — only a defensive backwards-guard (never move
  `activeDays`/`count` older than `streak.lastDate`) is needed for edge
  cases like manual localStorage edits or clock/timezone changes, not
  complex out-of-order handling for normal flow.
- **Adding a new color palette does not automatically reach the native
  widgets.** Both `TalkOfDayWidgetProvider.java` (Android) and
  `TalkOfDayWidget.swift`'s `paletteSet(for:)` (iOS) hold a hardcoded
  per-palette switch/case that must be updated explicitly for each new
  palette, or the widget silently falls back to a stale/wrong color set.
  This exact bug shape has recurred more than once.
- **A bare `.swift` plugin file dropped directly into `ios/App/App/` gets
  silently stripped from `packageClassList` by every `npx cap sync ios`**
  — a recurring, silent regression. The permanent fix is packaging it as
  a real (even if unpublished) local Capacitor plugin under
  `packages/<name>/` with its own `package.json` Capacitor manifest and
  `Package.swift`; `cap sync` then auto-registers it every time instead
  of needing a hand-edit of `project.pbxproj`/`packageClassList`. Already
  documented as a landmine in `PROJECT_HANDOFF.md` too.
- **`ios/App/App/capacitor.config.json` has repeatedly shown an
  unrelated, pre-existing local diff that removes `StreakBridgePlugin`
  from the plugin list.** Every session so far has correctly left it
  uncommitted as out-of-scope, but it keeps reappearing and has never
  actually been root-caused (possibly Xcode/Capacitor regenerating the
  file). Worth investigating properly before it accidentally gets
  committed and breaks native streak syncing.
- **`android/app/src/main/assets/public/`** (the `npx cap sync android`
  output) is git-ignored — it's rebuilt from `docs/` at build time, so
  there's never anything real to stage there after a sync.
- **iOS has no OS-level back-button convention.** The only analog,
  WKWebView's `allowsBackForwardNavigationGestures` (edge-swipe-to-go-
  back), only works on real `history.pushState`/`popstate` entries — and
  this app does all zone/list navigation via in-memory JS/CSS state, not
  real browser history, so turning that flag on alone does nothing. If
  the app ever moves to real history-based navigation, both the Android
  back button and iOS edge-swipe could be solved by the same underlying
  change, rather than two separate one-off fixes (Android's back button
  was solvable directly, via Capacitor's already-integrated `App` plugin
  `backButton` listener — no new native dependency needed).
- **All ~105 font-size declarations in `docs/index.html` are hardcoded
  `px`, with no `rem`/`em`/root-scaling anywhere** — iOS Dynamic Type and
  Android's system text-size setting currently have zero effect inside
  the WebView. Pinch-to-zoom is a partial workaround on Android but does
  not work in the iOS simulator. Any future "text size" feature needs the
  px→rem conversion done first (mechanical: px÷16) before a single root
  multiplier can work.

## Android widget / Doze

- **`ACTION_DEVICE_IDLE_MODE_CHANGED` (Doze enter/exit) is broadcast with
  `FLAG_RECEIVER_REGISTERED_ONLY`** — a hard platform rule, not an OEM
  quirk — meaning it can *never* reach a manifest-declared
  `BroadcastReceiver` (like an app widget provider), only a receiver
  registered at runtime by a live process. Confirmed as dead code on a
  real emulator via `dumpsys activity broadcasts history` after a commit
  assumed otherwise; that commit was reverted.
- **The correct way to force a widget refresh across Doze is
  `AlarmManager.setAndAllowWhileIdle()`** targeting a manifest receiver
  directly, re-armed on every fire and on boot — confirmed via
  `dumpsys alarm` showing `device_idle=--` (no idle delay) vs. a normal
  alarm's real delay. Note `setExactAndAllowWhileIdle()` requires the
  `SCHEDULE_EXACT_ALARM` permission on Android 12+; the inexact
  `setAndAllowWhileIdle()` avoids that requirement entirely.
- **A freshly-installed Android app sits in the OS "stopped" state until
  first launched**, and stopped apps receive no broadcasts at all
  regardless of any exemptions — worth remembering before concluding a
  receiver is broken during fresh-install testing.
- **A stale midnight widget update was really two independent gaps
  stacking, not one bug:** the `DATE_CHANGED` broadcast can itself be
  deferred by Doze on an idle phone, and separately, opening the app
  wasn't forcing a widget redraw at all (it only fired on streak-value
  change) — so the natural fallback of "just open the app" did nothing
  either. Both needed fixing independently.

## Working across concurrent sessions (this repo specifically)

- **Multiple Claude Code sessions routinely edit `docs/index.html` and
  `CHANGELOG.md` concurrently, uncommitted, in the same working tree** —
  this is a normal, recurring occurrence in how this project gets worked
  on, not a one-off accident. Before staging or committing either file,
  check `git diff` for hunks that aren't yours (partial/patch-based
  staging, or a scratch-copy comparison against `HEAD`) rather than
  assuming the working tree only contains your own edits.
- **A real near-miss happened from this:** one session discarded its own
  uncommitted `docs/index.html` changes per user instruction; a different
  concurrent session had already read and built against that in-tree
  code, then found it "gone" and initially suspected corruption or an
  accidental revert. It was actually an intentional discard by a sibling
  session neither one knew about. Uncommitted work in this shared file is
  invisible and unrecoverable to other sessions the instant it's
  discarded — commit early, or don't assume another session's uncommitted
  state will still be there.

## Debugging tooling quirks (not app bugs)

- **The browser-pane JS-eval tool's context can see `window.*` bindings
  but not top-level `let`/`const` declarations from the page's own
  script.** An apparent "undefined variable" runtime error during live
  debugging has turned out to be this eval isolation, not an actual app
  bug — check this explanation before chasing a phantom bug when
  `javascript_tool` reports an undefined top-level `const`/`let`. When
  verifying UI changes live, driving the DOM directly with the actual
  production classnames/markup is more reliable than trusting
  synthetic JS-injected test data.
