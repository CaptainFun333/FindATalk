# Idea 89 — Build plan: progress sharing + children's privacy

Written 2026-10-23. Companion to `specs/89-progress-sharing.md` (the
product spec and age model) and `specs/89-privacy-children-draft.md` (the
privacy-policy wording). This file is the order of work, the research
behind it, and how it becomes a store build. **Not legal advice** — see
stage 0.

Keep this file out of `docs/` (that folder is the public site).

**Study plans ship in two parts** (decided 2026-10-23):
- **Part 1 — study plans (idea 88), already built.** My order, personal
  plans, finish badge, reminders, shared plans with the combined Together
  number. Currently switched off (`STUDY_PLANS_ENABLED = false` in
  `docs/index.html`). Does not depend on the age questions, so it ships
  first: see section 2.
- **Part 2 — opt-in oversight (idea 89).** Watching someone else's
  progress, with the age model. Ships in a later build once the age
  permissions plan is settled: see section 3.

---

## 1. Research behind the plan (2026-10-23)

- **COPPA** (FTC): a general-audience app is covered once it has *actual
  knowledge* a user is under 13 — e.g. a parent tells you
  ([FTC FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions),
  H.1/H.6). It must then get verifiable parental consent or delete the
  child's data. Consent is required before a child's information is
  disclosed to third parties (I.4). The amended rule
  ([Federal Register](https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule))
  has been in force since 2026-04-22: written security program, disclosure
  of third-party recipients, separate consent for targeted ads (we run no
  ads).
- **Apple** ([Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)):
  stay out of the Kids Category; no child-directed wording in name,
  subtitle, icon, screenshots, description (2.3.8, 5.1.4(b)); any app that
  can collect/share a minor's personal information needs a privacy policy
  and COPPA-type compliance; a parental gate is *not* parental consent;
  in-app account deletion (5.1.1(v), already done); age-rating answers
  must be honest (2.3.6); UGC/social features need report/block/contact
  info (1.2 — shared lists already considered).
- **Google Play** ([Families policy](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)):
  declare the target audience honestly; if it includes under-13s the app is
  mixed audience → neutral age screen, SDKs must be approved for
  child-directed services (or sit behind the age screen / collect nothing
  from children), social features need an in-app safety reminder, adult
  management, and adult action before children exchange personal
  information; Data safety form and privacy policy must match.
- **Google Family Link**: supervised kids can sign in to third-party apps
  with parent approval
  ([2021 report](https://www.androidpolice.com/2021/06/10/google-accounts-for-kids-can-now-finally-sign-into-third-party-apps/));
  Google's current help page for this was not reachable — confirm.
- **Not found / unverified:** Firebase's own stance on child users
  (Authentication, Firestore); Apple's newer age-assurance APIs;
  EU/UK age rules.
- **Our position:** no analytics, no ads, no tracking, data used only to
  run the app (stated in `docs/privacy.html`). That is a strong starting
  point and must stay true.
- **Gap today:** the privacy policy says we do not knowingly collect
  children's information — untrue now that Brad's two under-13 children
  have accounts.

---

## 2. Part 1 release — study plans (idea 88)

Everything is built and merged on `main`. What's left is testing, the
privacy text, and the switch.

1. **Test shared plans with two real accounts** (Brad's account plus an
   adult or teen test account — **not** the under-13 children's). Cover:
   owner sets order/pace and a member sees the lock line; a member's
   progress updates the Together number and nobody sees a per-person
   number (check devtools/Firestore directly too); leave & keep a copy
   carries plan settings, chips and order; owner leaves → the earliest-
   joined member gets control; Start it again (owner only) bumps the
   round. These were not run in the original build.
2. **Re-test the device-to-device order merge** (reorder on one device, add
   a talk on the website, both end with the same order + the new talk at
   the end). Only read-checked so far.
3. **Privacy text (small, Part 1 only)** in `docs/privacy.html`: your
   account also stores study-plan settings, which talks you finished as
   part of a plan, and finished-plan badges; and, for shared plans, each
   member's finished count is stored on our servers and only the combined
   total is shown to the group. Do **not** include the children's section
   or the progress-sharing section (Part 2). The existing "Children's
   privacy" sentence stays as it is (accurate while no child has an
   account — Brad's two have deleted theirs).
4. **Switch on:** set `STUDY_PLANS_ENABLED = true`. Pushing `main`
   publishes the website immediately, so either flip it for everyone on
   release day, or gate it to the native apps first
   (`Capacitor.isNativePlatform()`) and open the web later.
5. **Functions/rules:** the study-plan callables and `sharedListProgress`
   rules are already deployed; confirm with `firebase deploy --only
   functions,firestore:rules` if anything in `functions/` or
   `firestore.rules` changed since.
6. **Changelog:** the Added bullets already exist; remove the "Study plans
   are hidden for now" Changed bullet when the switch goes on. Add
   a DECISIONS line if anything about the plan changes.
7. **Build:** bump versions (Android `versionCode`/`versionName`, iOS
   build), sync Capacitor, build, upload to Play Console and App Store
   Connect. Store forms for Part 1: no new data types beyond what the
   Data safety / App Privacy answers already cover for accounts and
   shared lists — add "app activity: reading progress" if not already
   declared. Rename `## [Unreleased]` → the version in `CHANGELOG.md`.
8. **Keep the audience honest:** do not market the app or plans as for
   children (Apple 5.1.4(b), Play target-audience declaration).

## 3. Part 2 build — opt-in oversight and age permissions (idea 89), in this order

Targets the build after Part 1. Part 2 builds on the Part 1 code, which is
already live behind the same switch.

Versions: Android `versionCode` 28 / `versionName "1.7.9"` were current
when this was written; Part 1 takes the next version and Part 2 the one
after.

### Stage 0 — decisions and checks (Brad; blocks stage 5 only)
1. Book a short consult with a privacy lawyer. Questions: (a) is a parent's
   own signed-in approval enough as verifiable parental consent for a
   parent-initiated child account, or is a listed method needed; (b)
   anything extra for Family Link children signing in with Google; (c)
   state/EU rules to worry about; (d) wording of the draft policy.
2. In Play Console, check whether Firebase Authentication/Firestore are
   fine under the Families policy; ask Play support if unclear. Decide the
   declared target audience (recommendation: **13+/adults only**; this
   avoids Families-program obligations, and under-13 use stays a
   parent-set-up exception handled by COPPA, not by declaring children as
   an audience — confirm with the lawyer).
3. Record decisions in `DECISIONS.md`.
Stages 1–4 proceed in parallel and only cover 13+.

### Stage 1 — neutral age screen + account age band
- On first sign-in (and for existing accounts at next sign-in), show a
  neutral question: birth month and year (no "you must be 13" hint, no
  default that reveals the threshold). Store `ageBand` (`'under13'` or
  `'13plus'`) — **never the birthdate**.
- Where: `openSignInModal()` flow in `docs/index.html`; band is written by
  a new callable `setAccountAgeBand` into a server-only doc
  `accountProfiles/{uid}` (rules: read by owner, write false) — **not** the
  client-writable `users/{uid}` doc, which the user could edit.
- Under-13 answer on a self-created account: do not create/keep a cloud
  account; tell them a parent can set one up from the parent's account
  (stage 5), and that the app works fully without an account. Existing
  under-13 accounts (Brad's two) are linked to Brad by stage 5 and treated
  as supervised in the meantime.
- Tests: age screen shows once; no threshold hint; under-13 blocked
  cleanly; `ageBand` unreadable/unwritable by other users.

### Stage 2 — privacy policy and store forms (Part 2)
- Apply `specs/89-privacy-children-draft.md` to `docs/privacy.html` after
  lawyer review, **in the same release as the build** (decided 2026-10-23).
  Until then the current policy stays accurate because Brad's two
  under-13 children have deleted their accounts and will not sign in again
  until the age screen and parent flow exist. Do not publish the draft
  early: it says under-13s can have a parent-approved account, which
  would raise Play audience / Data safety questions before stage 5 exists.
- Update `docs/delete-account.html` if the parent "delete my child's data"
  path is added (stage 5).
- Prepare answers for Play Data safety / target audience and App Store
  Connect App Privacy + age rating (listed at the end of the privacy
  draft). Submit with the build in stage 7.

### Stage 3 — server: grants, requests, progress (functions + rules)
In `functions/index.js` (see spec section 5 for shapes):
- `sharedListWatchers/{listId}` doc (`grants`, `requests`), rules
  `allow read, write: if false` added explicitly in `firestore.rules`.
- `sharedListProgress` also records `lastDay` (extend
  `setSharedPlanProgress`).
- Callables: `requestPlanProgress`, `setPlanProgressShare`,
  `getPlanProgress` (returns only members who granted the caller; never
  an under-13 member to a non-parent viewer), `clearPlanProgressGrants`
  (used by `removeMemberInTx` and account deletion).
- Enforce server-side: a viewer must be a member of the list; an
  `under13` member can only grant to a verified linked parent (stage 5),
  never to other members.
- Tests with the Firebase emulator if available, else careful manual test
  with two real accounts. `node --check` is not enough here.
- **Deploy order:** `firebase deploy --only functions,firestore:rules`
  *before* any app build that calls these (existing rule from idea 88).

### Stage 4 — client UI (13+), behind the switch
In `docs/index.html`, inside the same `STUDY_PLANS_ENABLED` gating:
- Member side: "Help me stay on course" row in plan settings; incoming
  request card with [Share] / [Not now]; list of current viewers with
  Stop sharing.
- Viewer side: "People I'm following" on the shared plan page (join-order
  roster, "6 of 12 · Last read Oct 21", no bars, no sorting by progress,
  no colour); Request button → "Requested".
- Copy review pass: no "behind", no red, nothing implying obligation.
- Add to `ENGINEERING_NOTES.md`: why a callable and not a readable field.
- Browser-pane tests with two accounts/simulated lists, plus the checklist
  in the spec section 7.

### Stage 5 — supervised under-13 accounts (only after stage 0 answer)
- A parent invites a child from the parent's signed-in account
  (`inviteSupervisedChild`); the child's account links to the parent
  (`supervisorUid`), stored server-side only (`accountProfiles/{childUid}`).
- Existing children (Brad's two): a one-time "link to a parent" flow run
  from the parent's account while the child's account exists.
- Supervised account rules (enforced in functions, not just the UI): no
  joining shared lists unless the parent allows; no leader viewers; the
  only viewer is the linked parent; parent sees done/total + last-read
  day only.
- Parent controls: view what's stored, stop sharing, **delete my child's
  data** (callable that wipes the child's Firestore data and Auth user),
  matched by the new privacy text.
- Play: if under-13s are declared as audience, add the in-app safety
  reminder and adult-management requirement from the Families policy.
- If the lawyer says a listed consent method is required, add it here
  (e.g. a small card transaction or signed form) — this may push stage 5
  to a later release; stages 1–4 ship without it, and under-13 sharing
  then stays off.

### Stage 6 — paperwork and verification
- `CHANGELOG.md` Added/Changed bullets (plain language; mention new builds
  needed and that functions deploy comes first).
- `DECISIONS.md`: age split; parent-initiated model; no leaders for
  under-13; `ageBand` stored not birthdate; why callables.
- `docs/privacy.html` live before the build (stage 2).
- Walk the spec's test checklist (section 7) with real accounts, including
  a teen account and a supervised account.

### Stage 7 — release into a build (Part 2)
1. Merge to `main` only after tests pass (pushing `main` publishes the
   website immediately; the Part 2 UI sits behind the same
   `STUDY_PLANS_ENABLED` switch, which is already on by then — consider a
   separate `PROGRESS_SHARING_ENABLED` flag so the website can lag the
   build).
2. Brad: `firebase deploy --only functions,firestore:rules`.
3. Bump versions (Android `build.gradle`, iOS project/`Info.plist`), sync
   Capacitor, build the Android bundle, build iOS.
4. Rename `## [Unreleased]` → the version in `CHANGELOG.md` and add a new
   empty Unreleased section, per `CLAUDE.md`.
5. Brad uploads to Play Console / App Store Connect with updated Data
   safety, target audience, App Privacy and age rating answers (privacy
   draft, "Store forms").
6. Turn on the Part 2 flag in the shipped build (and on the web when
   ready). Do not market the app or feature as for children.

## 4. What is deliberately not in Part 2
- Under-13 sharing with teachers/leaders (needs verifiable parental
  consent per child).
- "Send encouragement" nudges.
- Non-US supervised accounts until the international question is answered.
