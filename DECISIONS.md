# Decisions

A short log of the *why* behind choices that aren't obvious from the code or
the changelog. This is not a changelog (see `CHANGELOG.md` for user-facing
changes) and not the full architecture history (see `PROJECT_HANDOFF.md`) —
it's the middle layer: enough context that a future session (or future you)
doesn't re-litigate a call that was already made on purpose.

Grouped by how much it matters — business/strategic calls first, then
feature-scope tradeoffs, then minor/cosmetic tuning — newest first within
each group. See `CLAUDE.md` for when to add to this file; add a new entry
under whichever group it belongs in, not just at the top.

---

## Strategic / business

- **2026-09-14** — Monetization model is "free forever" with optional
  donations, not a paywall or subscription — a native IAP tip jar was
  added as one more way to give, not a gate on features. This reverses an
  earlier same-session plan to relaunch Android as a separate paid app,
  rejected because Google Play doesn't allow converting an already-free
  listing to paid, it would have restarted the 14-day closed-testing
  period, and it would have fragmented the install base across two
  listings. Kept here for context in case a paid model is ever
  reconsidered.
- **2026-09-17** — Idea 67's original donation plan (external Stripe
  Payment Links opened from Settings) was built, then abandoned mid-build
  once App Store/Play Store review research suggested it likely wouldn't
  pass compliance. Redirected to native in-app purchase (StoreKit 2 / Play
  Billing) for in-app tipping; the Stripe webhook/Payment Links work was
  repurposed instead as a separate, web-only `donate.html` page that isn't
  part of the bundled native app.
- **2026-09-17** — Only the 5 one-time tip tiers ($2–$25) were wired into
  the native IAP tip jar; the 5 annual-subscription tiers were
  intentionally left unbuilt for a later pass, since subscriptions need
  materially different handling (renewal/status tracking, a different
  verification path, a separate Play Billing product type) rather than
  being a drop-in extension of the one-time flow.
- **2026-09-19** — Donation-ask prompts (reading-count milestones + New
  Year nudge) were built and committed, but held locally rather than pushed
  to `main`, until a version past 1.7.1 ships — so the asks don't land on
  users mid-cycle of an already-shipped version's bug fixes.
- **2026-09-18** — iOS 1.7 was fully pre-flighted and version-bumped, but
  the actual App Store submission and IAP review request were deliberately
  left for a later, deliberate step rather than auto-submitted.
- **2026-09-18** — The Android APK build for the native IAP tip jar is
  being held back deliberately until other in-progress work is ready to
  ship in the same build, so the app isn't submitted piecemeal.
- **Earlier** — Domain migration: Phase 1 (web app live on FindATalk.com)
  shipped; Phase 2 (transferring the registrar itself to Bluehost) was
  cancelled — staying on GoDaddy for the registrar going forward.

## Feature scope & UX tradeoffs

- **2026-09-22** — The support-ask that used to fire once every January
  ("Happy New Year!") now fires December 18–31 instead ("Merry
  Christmas!") — the read is that people are more generous around
  Christmas than New Year's Day. The window runs through Dec 31, not just
  to Christmas Day, since the actual deadline being urged is "before the
  year is out" and the days between Christmas and New Year's are
  themselves a real second wave of year-end giving. A window (not a
  single date) was kept deliberately, same reasoning as the original
  all-of-January range: this only fires from a foreground check, never a
  push notification, so a single fixed day risks missing anyone who
  doesn't happen to open the app that exact day. A related idea — pinging
  someone who's *already* given this year to buy next year's badge early,
  as a "Christmas gift" — was considered and explicitly rejected: it would
  need a new exception to the "one star per real calendar year" badge
  rule and risked colliding with the existing annual-renewal webhook
  trigger, for a segment `isActiveSupporter()` already correctly mutes.
- **2026-09-22** — The "don't lose your streak" nudge notification is now
  cancelled the instant a talk is opened, instead of after a short
  read-confirmation delay — Android can suspend JS timers the moment the
  app backgrounds, so a delay-based cancel wasn't reliable. Accepted
  tradeoff: a stray accidental tap can suppress that night's reminder;
  judged cheaper than the false-alarm problem it replaces.
- **2026-09-22** — Recently Viewed history and earned badges are
  deliberately excluded from cloud sync and backup, confirmed as a
  preference rather than a gap to close — re-earning a badge on each new
  device is wanted, not something to fix.
- **2026-09-16** — Badge celebration modals no longer replay for badges
  already earned when signing into a new device with existing cloud data —
  new devices now silently backfill already-met thresholds instead of
  celebrating them as "new," since replaying old achievements adds no
  value.
- **2026-09-15** — Renamed Home's "Find Another" / "Show a List" buttons to
  "Find a Talk" / "Show Matches" — the onboarding tour already said "Find a
  Talk" (mismatching the live button), and "Show a List" collided with the
  unrelated My Lists (saved collections) feature. Reused existing in-app
  vocabulary ("draw," "matches") instead of inventing new terms.
- **2026-09-15** — Shared talk links now route through
  `findatalk.com/?talk=<key>` instead of linking straight to Gospel
  Library, so a shared link carries FindATalk attribution — Gospel Library
  stays one tap away via "Open This Talk."
- **2026-09-15** — The "today done" lit/checkmark treatment was
  deliberately kept off the Android/iOS home-screen widgets, staying
  text-only. Beyond the build cost (three separate surfaces — CSS,
  Android XML/Java, iOS SwiftUI), it was rejected partly on principle: a
  widget-only checkmark would nudge people to open the app just to check,
  which is an engagement-driving withholding pattern nothing else in the
  app uses.
- **2026-09-09** — The "Most Read" sort deliberately reads from the
  unbounded `visitCounts` map rather than the capped `recentKeys` list, so
  a talk read many times but not opened recently still surfaces — a scope
  choice to make "most read" reflect true lifetime reads, not recent
  activity.
- **2026-09-08** — Of several layout options considered for long list
  names truncating on phone width (My Lists), only the simplest — stack
  the name onto its own full-width line — was shipped; the alternatives
  were deliberately left on the table for later, even though the shipped
  fix alone doesn't fully solve the longest names. Scope was narrowed to
  ship the simple fix first and revisit only if needed.
- **2026-09-08** — Android's hardware/gesture back button was shipped as
  its own scoped fix (idea 59) rather than being blocked on solving iOS
  too: iOS has no equivalent OS-level back-button convention, and enabling
  WKWebView's edge-swipe-back gesture alone wouldn't help since the app
  doesn't create real browser history entries. iOS edge-swipe was split
  off as a separate, still-open idea — noting that a future move to
  real `history.pushState`/`popstate`-based navigation could solve both
  platforms at once instead of two one-off fixes.

## Minor / cosmetic / secrecy

- **2026-09-18** — The hidden badge/palette unlocked by the star easter egg
  is deliberately never named in changelog, store listing, or email copy —
  keeping it vague is the point; naming it would spoil the discovery. Tip
  jar product icon colors follow the same rule: mapped only to the four
  public palettes (Brass, Rose, Slate, Sage), deliberately excluding
  Celestial so the secret palette's color doesn't leak outside the app.
- **2026-09-16** — The secret star easter egg's discovery threshold was
  lowered from 12 clicks to 5 — tuned so it still reads as a deliberate
  discovery rather than something an accidental double-tap could trigger.
- **2026-09-15** — Google Sign-In's consent screen showing the raw
  Firebase-generated domain (`findatalk-28e26.firebaseapp.com`) instead of
  "FindATalk" was deliberately not fixed — the real fix needs a custom
  Firebase Auth domain (DNS + config changes) and was judged low priority.
  Logged as a future idea rather than acted on.
