# Idea 90 — "Keep your progress safe" sign-in nudge (build spec)

Status: ready to build. Written 2026-10-23 from the brainstorm
conversation; every product decision below was made by Brad.
Mockup: https://claude.ai/artifact/Aoo9YavqEHC22W5KJHaruL (screens
**M1–M4**). Keep this file out of `docs/` (the public site).

---

## 1. What it is

People who aren't signed in keep their favorites, notes, lists, badges
and streak on one device only. This adds a rare, friendly invitation to
sign in, shown at moments when they have something worth keeping, plus a
quiet reminder row they can find later, and a way to say "no thanks" for
good. The app stays fully usable without an account (MISSION: Open to
all). The tone is positive and specific, never "you could lose
everything".

## 2. Decisions (all made — don't re-open)

| Topic | Decision |
|---|---|
| Triggers | (a) every **Talks Read badge** (the `kind:'reading'` entries in `BADGE_DEFS`: 10, 50, 100, 250, 500, 1,000, 2,000, 3,000, The Whole Library); (b) the person's **first list**; (c) their **first note**. Streak is *not* a trigger. |
| Badge trigger form | The pitch is **attached inside the badge celebration pop-up** that's already open. It never adds a pop-up of its own (reading badges already chain into the support ask at 10/100/250/1,000). |
| List/note trigger form | Its own pop-up, same chrome as the rating ask. |
| Benefits | Backup, every device, **and shared lists** ("Share lists with family, friends, or your ward"). |
| Frequency | At least **30 days** between asks; **3 asks for life**, then never again. |
| Opt-out | **"Don't ask again" appears from the second ask on** (first ask: "Not now" only — they may still be exploring). |
| Reminder row | A quiet "Back up your progress · Sign in ›" row at the top of Your FindATalk, shown only **after the first ask**, with an **×** that equals "Don't ask again". |
| After opting out | Toast: "Got it. You can sign in anytime from Settings." No more asks, no row. The existing Settings account row stays. |
| Where | App **and** website. |
| Sign In destination | The existing sign-in modal, opened on **Create Account**. On this path only, Apple and Google buttons sit **above** the email form. |

## 3. Where it lives in the code today

All `docs/index.html`. Line numbers are approximate (taken 2026-10-23 from the `study-plans` checkout; search by name).

- **Auth**: `currentUser` (~5386, `null` when signed out), `authMode`
  `'signin'|'signup'`, `renderSignInMode()` (~5416), `openSignInModal()`
  (~5437, always resets to `'signin'`), `closeSignInModal()`. Modal
  markup `#signInModalOverlay` (~4030): email form first, then "or",
  then `#authAppleBtn` / `#authGoogleBtn`. Auth state changes land in
  the handler around ~5477.
- **Pop-up gating**: `POPUP_SHOWN_DAY_KEY` / `notePopupShownToday()` /
  `popupShownToday()` (~7115), `celebrationSurfaceBusy()` (~7707). The
  rating ask `maybeShowRatingAsk()` (~7745) is the pattern to copy (state
  object in localStorage with count/last, cooldown, lifetime cap,
  celebration markup `#ratingAskModalOverlay` ~4390 with
  `.secret-modal-glyph`, `.btn-primary`, `.secret-modal-later`).
- **Badge celebration**: `#badgeCelebrationModalOverlay` (~4332:
  title, desc, `#badgeCelebrationOkBtn` "Nice!"), driven by
  `badgeCelebrationQueue` + `showNextBadgeCelebration()` (~7583), which
  calls `maybeShowSupportMilestoneAsk()` once the queue drains;
  `dismissBadgeCelebration()`; `BADGE_DEFS` (~7543).
- **First list** — user-initiated creation happens in two handlers:
  `#collectionsIndexNewBtn` (~15590) and `#newCollectionBtn` in the
  add-to-list modal (~16930). `createCollection()` itself (~8402) is also
  called by import/merge/"Leave & Keep a Copy" (~17398), so **don't**
  hook it there.
- **First note** — the note modal's Save handler (~17641) calls
  `setNote()`; sync merges write `noteMap` directly. Hook the Save
  handler, not `setNote()`.
- **Your FindATalk**: `#trophyModalOverlay` (~4143), opened by
  `openTrophyModal()` (~5307); stats start at `.stat-grid`.
- **Settings account row**: `#accountRowTitle` "Not signed in" +
  `#accountSignInBtn` (~3898–3910), and the backup hint "Favorites,
  notes, and lists live only on this device unless you're signed in."
- **First-use day**: `firstReadDay(streak)` (~5003).
- **Clear Data**: `clearAllLocalDataAndSignOut()` (~16511).

## 4. State

One localStorage key, per device (there's no account to sync it to):

```js
const SIGN_IN_ASK_KEY = 'findATalkSignInAsk';
// { count: 0..3, last: ms, optedOut: false }
```

- `count` and `last` update whenever an ask is **shown** (either form).
- `optedOut` set by "Don't ask again" or the row's ×.
- Survives sign-in and sign-out. Reset only by Clear Data (add a
  `localStorage.removeItem(SIGN_IN_ASK_KEY)` there).

```js
function signInAskEligible(){
  if (currentUser) return false;
  const s = loadSignInAsk();
  if (s.optedOut || s.count >= 3) return false;
  if (s.last && Date.now() - s.last < 30 * DAY_MS) return false;
  const first = firstReadDay(loadStreak());   // no reads yet, or today = first day → not yet
  if (!first || first === localDateSeed()) return false;
  return true;
}
```

Constants: `SIGN_IN_ASK_MAX = 3`, `SIGN_IN_ASK_COOLDOWN_MS = 30 days`.

## 5. Form A — attached to a Talks Read badge (M1, "Talks Read badge")

Markup: add a hidden block inside `#badgeCelebrationModalOverlay`'s
`.modal`, **between** `#badgeCelebrationDesc` and the "Nice!" button:

```
┌ tinted box (--tint), left-aligned
│ 🔐 Keep this badge safe            (13px, bold)
│ ✓ Your badges, streak, notes, and lists, backed up
│ ✓ Pick up on your phone, tablet, or computer
│ ✓ Share lists with family, friends, or your ward
│ [ Sign In · it's free ]            (.btn-ghost, full width, paper-raised bg)
└ Don't ask again                    (small, only when count ≥ 1 before this ask)
[ Nice! ]                            (unchanged, still the primary)
```

Logic, in `showNextBadgeCelebration()` when rendering a badge:
- Show the box only if `badge.kind === 'reading'` **and**
  `signInAskEligible()` **and** it hasn't already been shown during this
  queue run (so binge-crossing two tiers shows it once). When shown,
  record the ask (`count+1`, `last=now`). Hide it for every other badge.
- **Sign In** → hide the celebration overlay, open the sign-in modal in
  Create Account mode (§7), and set a one-shot flag so the queue-drain
  step **skips `maybeShowSupportMilestoneAsk()` this time** and can't
  stack it on the sign-in modal. Any badges still queued can show after
  the sign-in modal closes. The support ask is
  only recorded when shown, so it simply comes at a later milestone.
- **Don't ask again** → `optedOut=true`, hide the box, show the toast
  (§8). The celebration stays open.
- "Nice!" behaves exactly as today.

This form is part of a pop-up that's already showing, so it does not
call `notePopupShownToday()` itself and is not blocked by
`popupShownToday()`.

## 6. Form B — first list / first note (M1, "First list" / "First note")

New overlay `#signInAskModalOverlay`, same chrome as
`#ratingAskModalOverlay`:

- Glyph 🔐, title **Keep your progress safe**.
- First sentence by trigger:
  - list: "You just made your first list, **“{name}.”** Sign in to back it
    up and open it on any device."
  - note: "You just wrote your first note. Sign in to back up your notes
    and read them on any device."
- Perks (tinted box): "Your streak, favorites, notes, and lists, backed
  up" · "Phone, tablet, and computer stay in sync" · "Share lists with
  family, friends, or your ward".
- Fine print: "It's free, and your notes and reading stay private."
- **[Sign In]** (primary) → close, open sign-in in Create Account mode.
- **Not now** (`.secret-modal-later`) → close.
- **Don't ask again** (smaller, below) only when `count ≥ 1` before this
  ask → `optedOut=true`, close, toast.

Trigger:
- In the two list-creation handlers: if `collections.length === 1` after
  creating (it's their first list ever on this device), call
  `maybeShowSignInAsk('list', name)` — after the existing UI work
  (re-render, modal close) so it lands on top cleanly.
- In the note Save handler: if the note is non-empty and
  `Object.keys(noteMap).length === 1` after saving, call
  `maybeShowSignInAsk('note')`.
- `maybeShowSignInAsk()` requires `signInAskEligible()`, `!popupShownToday()`
  and `!celebrationSurfaceBusy()`; on show, record the ask and call
  `notePopupShownToday()`. If blocked, it simply doesn't show (no
  queueing) — later badges are the backstop.
- Add `#signInAskModalOverlay` to `celebrationSurfaceBusy()`.

## 7. Sign-in modal on Create Account (M2)

- Change `openSignInModal(opts)` to accept `{ mode: 'signup', socialFirst: true }`
  (default unchanged: signin, email first). Settings' Sign In button keeps
  today's behavior.
- `socialFirst` adds a class on the modal that reorders with CSS
  (`display:flex; flex-direction:column` + `order`) so Apple/Google and an
  "or use email" divider come before the email form. Remove the class on
  close. Don't duplicate the buttons.
- Signing in merges local data into the account as it does today; nothing
  new there.

## 8. Reminder row and toast (M3, M4)

- Row at the top of the Your FindATalk panel, above `.stat-grid`:
  cloud-upload icon, **Back up your progress**, sub "Free · on every
  device", **Sign in ›** link (→ sign-in, Create Account, social first),
  and an **×** with `aria-label="Don't show this again"`.
- Visible when `!currentUser && s.count >= 1 && !s.optedOut`. No cap,
  no cooldown (it's not a pop-up). Re-evaluate in `openTrophyModal()` and
  on auth state change.
- × → `optedOut=true`, hide row, toast.
- Toast copy: **Got it. You can sign in anytime from Settings.** Reuse
  the app's existing toast/flash helper if there is one; otherwise a
  small fixed bottom toast with the safe-area inset, ~3s.
- The Stats share card (`buildStatsShareCardBlob`) must not include the row.

## 9. Edge cases

- Signed in on another device but not this one: still "signed out" here,
  so asks apply. Fine.
- Signs in, later signs out: state persists; if they'd used up asks or
  opted out, nothing returns.
- Existing users who already have lists/notes never get the first-list /
  first-note ask (the counts aren't 1); they'll see the badge form at
  their next reading badge.
- Badge celebration markup: confirm it exists on the website build too
  (`showNextBadgeCelebration()` has an early `return` comment about the
  web build). If badges don't celebrate on web, web users get Form B
  only — note this in the changelog wording rather than adding a new
  web pop-up.
- `prefers-reduced-motion`: no animation needed beyond what the modals
  already do.

## 10. Copy reference (exact strings)

- Badge box heading: `🔐 Keep this badge safe`
- Badge box button: `Sign In · it's free`
- Form B title: `Keep your progress safe`
- Perks (badge box): `Your badges, streak, notes, and lists, backed up` /
  `Pick up on your phone, tablet, or computer` /
  `Share lists with family, friends, or your ward`
- Perks (Form B): `Your streak, favorites, notes, and lists, backed up` /
  `Phone, tablet, and computer stay in sync` /
  `Share lists with family, friends, or your ward`
- Fine print: `It's free, and your notes and reading stay private.`
- Dismiss: `Not now` · Opt-out: `Don't ask again`
- Row: `Back up your progress` / `Free · on every device` / `Sign in ›`
- Toast: `Got it. You can sign in anytime from Settings.`

## 11. Release + paperwork

- `docs/index.html` only. Website gets it immediately; apps need new
  builds (say so in the changelog entry).
- **CHANGELOG** (Added): a friendly, occasional invitation to sign in and
  back up your progress, with a way to turn it off.
- **DECISIONS**: badge-attached form instead of a separate pop-up (avoids
  stacking with the badge celebration and support ask); "Don't ask again"
  only from the second ask; lifetime cap of 3; reminder row only after the
  first ask.
- **IDEAS.md**: add 90 (or move it) to In progress, then Done.
- No backend, rules or privacy changes.

## 12. Test checklist

- Signed out, day 1, read 10 talks → badge shows **without** the box (day-one rule).
- Day 2+, reach a reading badge → box shows, no "Don't ask again"; count=1.
- Tap Sign In in the box → celebration closes, Create Account opens with
  Apple/Google on top, **no** support ask stacks.
- Within 30 days, another reading badge → no box.
- Second ask (after 30 days) → "Don't ask again" visible; tap it → toast;
  row gone; no further asks.
- First list via My Lists and via the add-to-list modal → Form B with the
  list's name (respecting one-pop-up-a-day); first note → Form B.
- Import/merge/Leave & Keep a Copy creating a first list → **no** ask.
- Fourth eligible moment after three asks → nothing.
- Row: hidden before first ask; visible after; × opts out; hidden when signed in.
- Signed in → nothing anywhere. Clear Data → state resets.
- Light/dark in all palettes; phone width; website and app.
