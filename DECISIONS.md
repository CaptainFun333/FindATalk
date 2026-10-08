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

- **2026-09-30** — Uptime monitoring runs as a GitHub Action in this repo
  (every 10 minutes, alerts by opening a GitHub issue) rather than a
  third-party service like UptimeRobot, because the failure that prompted
  it — one of two nameservers serving a stale zone — is only caught by
  asking each nameserver directly, which hosted HTTP monitors don't do.
  Two failures 90 seconds apart are required before alerting, and the
  run stays green so GitHub doesn't also email on every failed run.
  Moving DNS hosting off GoDaddy's nameservers to Cloudflare (free,
  DNS-only / not proxied, GoDaddy staying the registrar) was considered
  and deliberately deferred: the stale nameserver was fixed by
  republishing the zone, and the monitor now catches a recurrence within
  minutes. Revisit the Cloudflare move only if GoDaddy's nameservers
  cause another problem.
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

- **2026-10-02** — The ledger's daily-readers calendar publishes raw
  per-day counts (even 1 or 2) rather than applying the 5-person minimum
  the "Loved by the community" stats use. That minimum exists so a small
  group's reading taste isn't exposed; here the talk is the publicly
  featured Talk of the Day and the count names no one, and with ~24
  accounts a minimum would blank almost every day of a calendar whose
  whole purpose is tracking growth. Each day's featured talk is stored
  the first time it's computed and never recomputed, because the pick
  depends on how many talks `data.json` holds — a data update would
  otherwise silently rewrite which talk past days show. The counts cover
  signed-in accounts only; an anonymous per-day counter in the app (idea
  84) is queued for the release after 1.7.7 rather than rushed into a
  build already in Apple review.
- **2026-09-23** — The ledger's cloud stats are computed server-side by a
  Cloud Function (Admin SDK) into one public-read `stats/ledger` doc,
  rather than by a scheduled GitHub Action, because the Action would need
  a Firebase service-account key and this project's org policy is already
  hostile to public/keyed access (see the Domain Restricted Sharing notes
  in `PROJECT_HANDOFF.md`). Deliberately aggregate-only — counts of
  accounts, reads, and supporters, never per-user data and never dollar
  amounts — since the ledger URL is public even though it's unlinked and
  `noindex`. Recalculated daily, plus a throttled on-demand refresh
  (once per 10 minutes) so a button-mashing visitor can't run up
  Firestore reads.
- **2026-09-22** — My Stats' standalone modal was retired the same day it
  shipped: once its content sat one tap behind the new "Your FindATalk"
  panel (below), almost every number it revealed was already visible at
  the panel's own root, making the extra tap-through pure friction. All
  six numbers now render directly in the trophy panel instead. This also
  surfaced a real duplicate: the panel's "My Badges" button and My Stats'
  own "N badges earned — View My Badges" link both opened the identical
  modal from the same screen — resolved by keeping only the informative
  summary link and dropping the bare button. Reads & Rereads was demoted
  from its own big-number cell to a `.stats-context-row` paired directly
  with Most-Read Talk, under a shared "Reading Activity" label — both are
  about *what/how much* was read, distinct from the toggle cells above
  (*how many different* talks, *how consistently*).
- **2026-09-22** — Split Settings: My Badges, My Stats, and Support the
  App moved to a new "Your FindATalk" panel behind a new top-left button,
  leaving Account/Appearance/Notifications/Help/Account & Data/Backup in
  Settings. Settings had grown to 9-10 sections and mixed two different
  kinds of content — set-once preferences vs. things worth revisiting —
  so the split follows that real seam. Only the new button gets visual
  weight (filled accent-fill circle); the Settings gear stays exactly as
  subtle as before, per explicit direction not to make Settings itself
  more prominent. (My Stats was later folded directly into this same
  panel the same day — see the entry above.)
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
- **2026-09-22** — Streak "salvage" (missing exactly one day) continues
  the consecutive-day count on a second credited read the same day rather
  than literally backdating yesterday into the streak's `activeDays`
  history — `activeDays` also drives the "days active out of the last
  365" stat and gets unioned across devices on sign-in, so fabricating a
  day in it would have silently propagated a false activity record
  everywhere it syncs. Capped at once per rolling week and only for a
  single missed day (never two or more), so it stays a genuine save
  rather than a quietly looser definition of "daily." The standing
  recurring 8am reminder was deliberately left untouched — a second,
  purpose-built one-off notification (scheduled only at the moment a
  salvage is actually available) avoids the risk of the recurring
  reminder firing with stale copy or promising a save no longer on offer.
- **2026-09-22** — My Stats deliberately does not absorb My Badges — it
  shows exactly six numbers (unique reads, total reads, current streak,
  longest streak, days active, most-read talk) and links out to the
  existing My Badges modal via a single summary row instead of
  duplicating the badge list, so there's one authoritative badge display
  rather than two that could drift out of sync with each other. List and
  favorites counts were considered and deliberately left out of scope —
  spun into their own idea (showing a count on the Favorites/My Lists
  pages themselves) rather than folded in here, since those are page-
  level counts, not personal stats collected into a dashboard.

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
- **2026-09-22** — Generated share-card images (talk, badge, Supporter,
  streak) render in whatever Appearance x Palette the sender's own device
  currently has set, **including the secret Celestial palette** — a
  deliberate exception to the 2026-09-18 rule keeping Celestial's colors
  off public-facing surfaces like the tip jar icons. Judged different here
  because a share card is personal (chosen by the person sharing it, not a
  neutral store asset) and the "why does hers look different" curiosity is
  the intended effect, not a leak to guard against.
- **2026-09-22** — The new share-compose review modal (edit-before-sharing,
  idea 71) is scoped to talk shares only, not badge/Supporter/streak
  shares — those three now attach a generated image too, but stay a
  single-tap instant share exactly as before, to avoid adding the modal's
  extra step everywhere at once. Could be extended later as its own call.
- **2026-09-22** — Share-card images have no "long-press to save" or other
  affordance on a platform/browser that can't attach a file to a share —
  they silently fall back to the existing text-only share instead. Chosen
  over a save-image fallback to keep the share flow's behavior simple and
  predictable across platforms, at the cost of some shares carrying no
  image at all on older/unsupported browsers.
- **2026-09-22** — Idea 74's page-title count only shipped on My Lists, not
  Favorites — Favorites already shows a real count ("Showing all 34
  talks") via its existing search/filter row, so a second number in the
  title would be redundant there. My Lists counts the number of lists
  themselves, not a sum of each list's own talk count — a talk can belong
  to more than one list, so summing would double-count it and show a
  number that doesn't correspond to anything real.
- **2026-09-23** — Idea 76's rating ask can't know whether someone already rated: neither Apple's nor Google's review API reveals that (or even whether the sheet appeared). So "stop asking once rated" is approximated locally — tapping Rate stops asks for good, Not now starts a 90-day cooldown, and there's a lifetime cap of 3 asks (matching Apple's own 3-per-year limit). The ask is shown to everyone, not only happy users, since Google discourages gating it and Apple forbids custom star forms. It skips any day another popup already showed; support asks and badge celebrations don't check that flag, so they win the day.
- **2026-09-23** — Adopted the mission/vision/values in `MISSION.md`. Statements stay open and inviting rather than naming the Church, though the app never hides its connection to it; they name "prophets, apostles, and leaders" because any inspired message is worth hearing. Deep-dive study and advanced search stay out of scope on purpose — FindATalk is the concierge to the Gospel Library, not a competitor to it.
- **2026-09-23** — Locked the final mission wording in `MISSION.md`: "FindATalk helps you draw nearer to Jesus Christ by hearing His voice through His inspired leaders, removing barriers to daily study so that a healthy habit becomes a joy and not a burden." Chosen over softer "ordinary day / without pressure" drafts because it leads with Christ (the stated measure of success) and names both accessibility and the daily habit.
- **2026-09-23** — Locked the final vision wording in `MISSION.md`: "A worldwide community of believers and friends hearing the Lord's servants daily, easily, and joyfully — rediscovering a talk they love or finding one they never knew — and coming back each day to be inspired by God's word." Says "believers and friends" (not "devoted members") so the person who does not yet feel devoted, who the app is built for, is included.
- **2026-09-23** — Shortlisted three taglines in `MISSION.md` (kept together rather than picking one): "Your daily word from the Lord's servants," "The message you didn't know you needed," and "Every day, something inspired." Each is meant for a different space, so the choice is deferred until adapting store, website, and About copy.
- **2026-09-23** — Recorded the four values (Simplicity, Accomplishment, Joy in being inspired, Open to all) with their reasoning in `MISSION.md` as the test for every future feature. Anything that pushes toward rigorous deep-dive study, intimidates the everyday member, adds guilt/comparison/pressure, or gates access is "not FindATalk" — this is also why an advanced search was held back.
- **2026-09-23** — Added a Mission tab (first tab, default view) to the ledger page that reads `MISSION.md` live, so the compass stays visible next to the changelog and decisions. `MISSION.md` is public via the repo, so it deliberately describes in-app surprises only vaguely.
- **2026-09-24** — Idea 77's store badges ship with the App Store side as plain "coming soon" text rather than waiting for Apple's approval or showing a lookalike Apple badge: Google Play is live now, and the Apple badge flips on later by filling in one constant (`APP_STORE_URL`) plus Apple's official badge file.
- **2026-09-26** — The rating ask's Rate button now opens the store listing directly instead of calling the in-app review API. A user reported tapping Rate and nothing happening, and neither store tells us whether its sheet appeared, so a guaranteed redirect beats a nicer sheet that can silently fail. iOS keeps the in-app sheet as a fallback only until `APP_STORE_URL` is set.
- **2026-09-27** — Apple rejected iOS 1.7.2 (Guideline 3.1.1) because the
  in-app Support modal's Yearly option sent people to the website's donate
  page. Store builds now hide the Frequency toggle entirely (one-time IAP
  tips only) and never reference the donate page, including in the
  Supporter badge share text; yearly giving stays web-only until annual
  IAP products are wired in.
- **2026-09-28** — The "Your FindATalk" share card deliberately leaves out
  Most-Read Talk: a streak or a read count says how much someone studies,
  but a most-read talk says what they're drawn to, which could be a
  sensitive subject — not something to broadcast by default. It's a new
  grid layout (`buildStatsShareCardBlob()`), not a reuse of the existing
  one-centerpiece badge/streak card function, since four numbers at once
  doesn't fit that shape.
- **2026-09-28** — The four personal-collection pages (Recently Viewed,
  Favorites, My Notes, a List's own page) get two independently-flippable
  sort buttons instead of four separate ones, since they cover two real,
  distinct orderings (when you added/favorited/noted it, vs. the talk's
  own conference date) that both deserve a reverse. "Conference Date"
  keeps its name with a flipping arrow rather than a full label swap, to
  avoid renaming a label already used identically across four pages;
  the activity-axis button does a full label swap ("Recently Favorited"
  ↔ "Oldest Favorited") instead, matching the tap-to-flip convention
  "Your FindATalk"'s own stat cells already use.
- **2026-09-28** — Idea 79's conference range is an explicit "Select a range" button that fills in checkboxes, not "two checked boxes means a range": the Conference filter is a real multi-select, and someone who wants just April 2024 and April 2026 would be silently surprised. The range fills from every conference, not only the ones currently shown, so it stays a true range when other filters change. The button label uses two-digit years ("Oct ’24 – Apr ’26"), falling back to years only on phones, because the half-width Conference field can't fit more.
- **2026-09-28** — Removed the `EdgeToEdge.enable()` call added in 1.7.6 and accepted Play Console's "Edge-to-edge may not display for all users" recommendation as a false positive: the call didn't clear that warning (R8 inlines it) and caused a new deprecated-APIs one, while the real layout is already correct. Play's "bitmap downsampling" note is also left alone because it points at library code. These changes plus optimized resource shrinking are held for a 1.7.7 build rather than cutting a release just for them.
- **2026-09-30** — Started recording the date of every credited read (idea 80) before any screen uses it, because read dates can't be recovered later: a "this year" count or a December year-in-review is only possible for reads logged from now on. No changelog entry until something visible ships, same as idea 68's counter.
- **2026-09-30** — Repointed the chastity-related search synonyms (chastity, adultery, affair, lust, etc.) from the Sexual purity topic to Morality: Sexual purity has only about 1 tagged talk against Morality's 169, so the old "did you mean" led almost nowhere. New synonym batches are also now checked so no new term makes an existing partial search ambiguous; "baptisms for the dead" and "member missionary" were dropped for that reason.
- **2026-09-30** — Backfilled read dates (idea 80) only where a day is in the streak's active days AND that day's Talk of the Day is marked read — not from the Talk of the Day calendar's checkmark alone, which only means the talk was read at some point and can appear on days the person never saw. Estimates are stored separately from real read dates so a future year-in-review can say "about," and the backfill runs once per device since active days only reach back 365 days.
- **2026-09-30** — Repointed the mental-health search synonyms (self-harm, PTSD, OCD, bipolar, eating disorder, self injury, counseling, therapy) from Mental illness / Mental health (2–3 tagged talks each) to Healing (~74), which those talks are already co-tagged with and where "trauma" and "illness" already pointed.
- **2026-09-30** — Repointed the anxiety and stress search synonyms (worry, worrying, anxious, social anxiety, panic attacks, burnout, overwhelmed) to Peace (~131 talks) and the depression ones (sadness, postpartum depression) to Hope (~80), since Anxiety, Stress, and Depression each have only 1–2 tagged talks; Balance (2 talks) was too thin for the stress terms. Suicide synonyms were deliberately left on the Suicide topic pending a more careful call.
- **2026-09-30** — Idea 80 shipped only the two yearly numbers (talks read, days studied) in a collapsed "Your Journey" section with a ‹ year › switcher, chosen by Brad over the other candidates (speakers heard, scriptures cited, topics, eras, rhythm, Talk of the Day follow-through) to keep Your FindATalk small. Brad chose to keep the whole section hidden until December 31, 2026 (moved from December 1 so the year-end reveal, idea 81, introduces it), while the data keeps collecting in the background. The December year-in-review card was deferred to idea 81. The year of tracking's start reads "At least N" talks, and earlier years are marked as estimates, because dates before tracking began are only partly recoverable. Pre-tracking active days are saved permanently so a past year's "days studied" doesn't shrink once the streak's 365-day history moves past it.
- **2026-09-30** — Idea 81's yearly "Check on your journey in [YEAR]" reveal will show only to people with at least 14 days studied that year, and only from December 31 through January 14. A reveal of tiny numbers would feel like a report card, and a recap of last year feels stale weeks into the new one. Anyone outside either still has Your Journey and its year arrows. Chosen by Brad.
- **2026-09-30** — Idea 82's reading pace divides total reads (rereads included) by calendar days since the first dated read, counting days without a read — the honest pace. It opens on the first average that's 1 or more ("About 1.4 a week," not "About 0.2 a day") and shows the year as "On pace for N a year" so it can't be read as a count already reached; both keep it a habit-building pace tracker rather than something that feels like a grade. Wording chosen after four mockups: "About" and "a day" (plain and warm), no subtitles.
- **2026-09-30** — Idea 82's start date is the earliest dated thing on record (read log and its backfill, estimated study days, streak days, badge/note/favorite timestamps), since no first-read date was ever stored. For long-time readers with nothing older than the 365-day streak window, it lands late and the average reads a little high — accepted for a fun pace tracker. Averages stay hidden until that span reaches 14 days.
- **2026-09-30** — Shared lists (idea 57) are one Firestore document per list that every member listens to, and every change goes through a Cloud Function; the app can only read them. That makes "Added by" impossible to fake, keeps two people editing at once from overwriting each other, and makes ownership hand-off atomic, at the cost of needing a connection to add or remove a talk.
- **2026-09-30** — Shared-list choices made at build time (user said "build it" without picking): any member can add or remove any talk (it's for families); sharing a list moves it rather than copying it, so there aren't two versions drifting apart; when the owner leaves, the longest-standing member takes over, and the last person out deletes the list. Invite links work once and expire after 7 days, since a forwarded link is the main abuse risk. The owner row says "List owner," not "Created this list," because ownership can move.
- **2026-09-30** — Shared lists require sign-in for everyone in them, because "Added by" needs to know who each person is. Notes, read checkmarks, and streaks stay private; only which talks are on the list, who added them, and each member's chosen display name (never email) are shared.
- **2026-09-30** — Leaving a shared list can keep the talks (per user request): the last person out chooses "Stop Sharing" (keeps it as their own list) or "Delete List," and anyone leaving a list others are still in can "Leave & Keep a Copy." Keeping the talks is the highlighted choice. The app leaves first and only then saves the personal copy, so a failed leave never leaves a duplicate behind.
- **2026-10-01** — 1.7.7 (both platforms, including shared lists) is built from a `release-1.7.7` branch and kept off `main`, because pushing `main` publishes the website immediately. iOS 1.7.4 was pulled from App Review (the five tip products were never attached to it) and 1.7.7 goes to Apple in its place; the Android release and the website update wait for Apple's approval so all three go out close together and nobody gets a shared-list invite their app can't open.
- **2026-10-02** — Added "most read" and "most favorited" talk to the ledger Stats tab as a trial run for the "Loved by the community" feature (idea 77). Counted by distinct signed-in members, not total reads, and hidden until 5+ people share a top talk, so no individual is identifiable. Computed in the daily stats function; takes effect after `firebase deploy`.
- **2026-10-02** — Extended the ledger "Loved by the community" block with most-read speaker, most-read topic, most-cited scripture book, most-added-to-lists talk, and total community study days. Same rule: distinct signed-in members, hidden below 5 people, aggregates only; takes effect after `firebase deploy`.
- **2026-10-02** — Ledger topic/scripture stats now include a "popularity vs. supply" version (how much more of members' reading goes to a topic or scripture chapter than its share of the library), because the raw "most-read topic" mostly reflects which tags the Gospel Library applies, not what members seek out. Scripture is shown by chapter, not book or verse (verses are too sparse at this size). Searches and filters are not tracked, so this is still inferred from reads.
- **2026-10-04** — Dropped the once-a-week cap on the streak salvage (reverses part of the 2026-09-22 entry): any single missed day can now be saved by reading 2 talks the day it's noticed. The streak exists to build a habit, not to cause anxiety, and a weekly limit punished exactly the people trying to get back on track. Accepted trade-off: a streak can now survive on every-other-day reading; "days studied" still only counts real days, so that number stays honest. Still one missed day only, never two or more.
- **2026-10-04** — Added a private Admin tab to the ledger (open `ledger.html#admin`, Google sign-in) for looking up one account's streak by email and forgiving missed days. It writes forgiven days to `streak.bridgedDays` rather than adding fake reading days, for the same reason the salvage does — the streak continues but "days studied" isn't inflated. The catch: app builds from before the salvage-sync fix ignore `bridgedDays`, so a forgiven streak only shows on the website until that person updates. The ledger's "aggregate-only, no per-user data" rule still applies to everything public; the admin functions check the caller server-side and log each change to `adminActions`.
- **2026-10-04** — General Conference weekend (idea 87): on conference Saturday and Sunday the Talk of the Day is replaced by an "Are you participating in General Conference today?" card, and **no Talk of the Day is assigned or recorded for those days at all**. Brad's reasoning: most people will earn the day by watching conference, the community should stay unified, and nobody should feel they have to go back through the calendar to catch up on a talk they "missed". "No" therefore draws a plain random talk, not a hidden Talk of the Day.
- **2026-10-04** — Conference days are worked out from the calendar (first Sunday of April and October, plus the Saturday before) rather than kept as a list of dates, so nothing has to be updated twice a year. If the Church ever moves a conference off that weekend, the rule has to change in four places (see ENGINEERING_NOTES.md).
- **2026-10-04** — The conference card's "Yes" counts as a study day for the streak (and as one of the two credits a streak salvage needs) but is not a "read": no talk is marked read and read counts, pace and journey totals don't move. "No" is not remembered — the question stays on the card all day so someone who watches a later session can still say Yes.
- **2026-10-04** — On the small iPhone widget the "GENERAL CONFERENCE" eyebrow is left off on conference days: at that size it wraps to two lines and the question gets cut off. The question itself names General Conference, so nothing is lost. The medium widget and Android keep the eyebrow.
- **2026-10-04** — The daily reminder's conference wording is done by temporarily swapping the single repeating reminder for a weekday-repeating set plus individually dated weekend reminders, starting 28 days before conference. Someone who doesn't open the app at all in those 28 days gets the ordinary wording on conference weekend; accepted, since the only alternatives were dropping the reminder on those days or a server push.
- **2026-10-04** — Reversed the 2026-10-01 hold: 1.7.8 (shared lists plus everything built since) goes to Android and `main`/findatalk.com now, without waiting for Apple to approve 1.7.7; iOS 1.7.8 gets queued behind it. Brad preferred getting the work live over keeping the three platforms in lockstep.
- **2026-10-08** — Held the October 2026 conference talks out of the Talk of the Day pool until 2027-01-08 (`TOTD_HELD_BACK` in `docs/index.html`, mirrored in `functions/totd.js`). Installed widgets only know their bundled talk list and iOS review is slow, and adding talks re-partitions the daily cycle, so the app and widgets disagreed. Remove the hold once builds with the talk-list mirror are live.
