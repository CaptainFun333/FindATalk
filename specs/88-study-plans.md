# Idea 88 — Study plans (build spec)

Status: ready to build on a new branch (suggested: `study-plans`). Written
2026-10-19 from the brainstorm conversation; every product decision below
was made by Brad. Mockup:
https://claude.ai/artifact/Q3SgCFkNB39FqxbdQpZmdr (screens 1–9 are
referenced as **M1–M9** below).

Keep this file out of `docs/` (that folder is the public site).

---

## 1. What it is

Any list can become a **study plan**: the talks in an order you choose, a
goal (a finish date or a pace), progress you can see, a slender card on
Home, and a daily reminder that names the next talk. Plans can be
**shared** (family, ward) on top of the existing shared lists. Finishing
a plan earns a **badge on that list's page**, shareable as a square card.

Mission check: no guilt and no comparison. Never show "behind", never red.
Shared plans show your own progress plus one combined group number,
never who is ahead.

## 2. Decisions (all made — don't re-open)

| # | Decision |
|---|---|
| Goal | Offer **both** "Finish by a date" and "Set a pace". Finish date is selected first. |
| Progress | "Read ×N" stays exactly as is. A **separate** brass **Plan** chip marks talks finished *as part of this plan* — only reads made after the talk was in the plan (and after the plan started) count. |
| Home | A **slender card** per plan under Talk of the Day, with a brass **check** when today's plan reading is done (same idea as finishing Talk of the Day). |
| Plans | **Several** at once, built that way from the start. |
| Reminder | The plan reminder **replaces** the Talk of the Day reminder. Still one notification a day. |
| Shared | Shared study plans are part of this build. The owner sets order and pace; progress is personal; the group sees one combined number. |
| Leaving | Leaving a shared plan **keeps the list** — "Leave & Keep a Copy" carries the order, the date/pace, and your Plan chips into a personal plan. |
| Added talks | **Ask** (date plans only): "You added 3 talks to this plan. Keep your finish date, or keep your pace?" |
| Finishing | A **badge on the list's page**, *not* in the trophy drawer, **shareable** as a square card. |

Smaller calls made in the mockup that Brad saw and didn't object to (treat
as defaults): "Start it again" on a finished plan; when a shared plan's
owner leaves, control passes the way list ownership already passes
(earliest-joined member); two plan cards max on Home with "See all".

## 3. Where it lives in the code today

All in `docs/index.html` unless noted. Line numbers are approximate
(2026-10-19, main at `7da2ff7`).

- **Lists**: `collections` `[{id, name, updatedAt}]`,
  `collectionMembers {id: [talkKey…]}` (already an **ordered** array, add
  order), sync maps `collectionUpdatedAt`, `collectionMemberUpdatedAt`,
  `deletedCollections` (block comment ~8114). Mutators
  `addTalkToCollection` / `removeTalkFromCollection` (~8250),
  `touchCollection` (~8238). These are **top-level**, not inside
  `initApp()`.
- **List page**: `renderCollectionPage(id)` (~14100). Sort via
  `collectionSortToggle` (`createSortToggle()`, ~12794: `mode` = `'default'|'conference'`, `dir` = `'desc'|'asc'`). Shared
  lists come from `liveListsById` and are ordered by
  `liveTalkKeysInOrder(list)` (~15672, sorts by `talks[key].addedAt`).
- **Reads**: `checkPendingRead()` (~6879) is the only credited-read path:
  `markRead()` → `incrementVisitCount(talk, creditDate)` (writes idea 80's
  `readLog`) → badge refresh → streak. Top-level. The Read badge HTML is
  `readBadgeHtml(count)` (~9942), refreshed by `refreshReadBadgesFor()`.
- **Sync**: `exportBackupData()` (~14369) / `mergeBackupData()` (~14606),
  pushed whole-doc to `users/{uid}` by `scheduleCloudPush()`. Note the
  member merge (~14756) unions into a `Set` and re-spreads it, so **order
  from another device is not merged today**.
- **Daily reminder**: `dailyReminderPlan(now)` / `scheduleDailyReminder()`
  / `refreshDailyReminderPlan()` (~10865–11030). Normally one recurring
  `schedule.on {hour, minute}` trigger with a fixed body; idea 87 swaps
  in weekday weekly triggers + dated weekend reminders around conference.
  Ids: `DAILY_REMINDER_ID = 1`, weekday `21–27`, dated `200–239`. Other
  ids in use: 2, 3, 4, 5, 100+ (`~7823`).
- **Shared lists**: Firestore `sharedLists/{id}` =
  `{name, ownerUid, memberUids, members{uid:{name, joinedAt}}, talks{key:{addedBy, addedByName, addedAt}}, createdAt, updatedAt}`.
  Clients **never write** it — every change goes through callables in
  `functions/index.js` (`createSharedList`, `setSharedListTalk`,
  `renameSharedList`, `leaveSharedList`, …, ~640–850; helper
  `readMemberList(tx, listId, uid)`). Leaving with a copy:
  `leaveLiveList(list, keepCopy)` (~16052).
- **Share cards**: `buildAchievementShareCardBlob({title, desc, dateLine, centerpiece})`
  (~12154) and `openShareComposeModal({...})` (~12384), placeholder-style
  suggested message (commit `7da2ff7`).

## 4. Data model

### Personal (synced through `users/{uid}` like everything else)

```js
// Plan settings, one per list id that is a plan. LWW by updatedAt.
collectionPlans = {
  [listId]: {
    mode: 'date' | 'pace',
    finishBy: 'yyyy-mm-dd',          // date mode
    pace: { count: 2, per: 'day' | 'week' }, // pace mode
    startedAt: 'yyyy-mm-dd',
    anchor: { date: 'yyyy-mm-dd', done: 8, total: 20 }, // see §6
    reminder: true,
    round: 1,                        // bumps on "Start it again"
    updatedAt: 1760000000000,
  }
}
// Which talks count for the plan, per round. Union on merge, earliest date wins.
planCredits = { [planId]: { round: 1, talks: { [talkKey]: 'yyyy-mm-dd' } } }
// Finish badges. Union on merge by (planId, round).
planBadges = { [planId]: [{ round, name, talkCount, startedAt, finishedAt }] }
// Personal order sync — see §5.
collectionOrderUpdatedAt = { [listId]: ms }
```

`planId` is the collection id for a personal plan and `live:<listId>`
(the existing `LIVE_LIST_PREFIX`) for a shared one, so credits and badges
for shared plans also live in the member's own private user doc.

Add all four to `exportBackupData()`, `mergeBackupData()`, and Clear Data.
Deleting a list deletes its plan, credits and badges (they belong to the
list — that's the "not in the trophy drawer" decision).

### Shared (Firestore, written only by callables)

On `sharedLists/{id}`:
```js
plan:  { mode, finishBy, pace, startedAt, anchor, round, updatedAt } // owner only
order: [talkKey, …]   // owner only; keys not in it fall back to addedAt order, appended
planTogether: { round: 1, reads: 13 } // the ONLY progress number members can see
```
Per-member counts go in a new doc `sharedListProgress/{listId}` =
`{ round, counts: { [uid]: n } }`, **rules `allow read, write: if false`**,
so nobody can read another member's number even from devtools. The
callable recomputes `planTogether.reads` from it in the same transaction.

## 5. Reordering ("My order")

- New sort chip **My order** on the list page, beside the existing ones
  (M2). It's the default for any list that is a plan; for other lists it's
  just another option. It shows `collectionMembers[id]` as stored (the
  array is already oldest-added first).
- Drag by a grip handle (pointer events, works with touch; lift on
  long-press of the grip only so scrolling still works). Also provide
  Move up / Move down in the row's long-press menu for accessibility.
- Rows show their position number in My order.
- **Sync**: on reorder, set `collectionOrderUpdatedAt[id] = Date.now()`.
  In `mergeBackupData()`, after the member union: if the incoming order
  timestamp is newer, rebuild the array in the incoming order, then append
  any local-only members in their local order. Otherwise keep local order
  and append incoming-only members. New adds always append to the end.
- **Shared lists**: only the owner sees the grip. Members see "Order and
  pace set by the list owner" (M5). New callable `setSharedListOrder
  {listId, order}` (owner only, validates keys ⊆ talks).
  `liveTalkKeysInOrder()` uses `list.order` first, then the rest by
  `addedAt`.

## 6. Plans, pace, and progress

### Setup (M3)
Opened from the list's ⋯ menu: **Make this a study plan**. Segmented
control **Finish by a date** (selected) | **Set a pace**.
- Date: date picker (default: 4 weeks out, never before tomorrow). Shows
  the computed pace "About 2 a week" and "20 talks over 9 weeks".
- Pace: stepper "N talks a day / a week". Shows "Done around Jan 10".
- Toggle **Use this plan for my daily reminder** (on by default for the
  first plan with reminders; off for later ones; hidden when
  notifications aren't available, e.g. the website).
- **Start plan**. Edit later from the same menu (**Edit plan**, **Stop
  plan** — stopping keeps the list, drops the plan settings and chips).

### The math (pure functions — unit-test these)
All days are local `localDateSeed()` dates.

- `planDone(planId)` = number of `planCredits[planId].talks` whose key is
  still in the list.
- `planTotal` = talks currently in the list.
- **Anchor**: `{date, done, total}` captured whenever the goal changes
  (start, edit, answering the added-talks question). Lets talks be added
  and goals change without retroactively making someone "behind".
- **Expected through a day `d`**:
  - date mode: `anchor.done + ceil((total − anchor.done) × daysBetween(anchor.date, d) / daysBetween(anchor.date, finishBy))`, capped at `total`. (daysBetween is inclusive of `d`.)
  - pace/day: `anchor.done + count × daysBetween(anchor.date, d)`, capped.
  - pace/week: the target is `count` credits within each calendar week.
    Week start isn't decided — suggest Sunday (matches the Sabbath-week
    feel of Come Follow Me) and log the choice in DECISIONS.
- **Needs a read today** = `done < expected(today)` (pace/week: this
  week's credits `< count`).
- **On pace** = `done ≥ expected(yesterday)`. If not on pace, the header
  shows **Adjust your pace?** (opens Edit plan) instead — never "behind",
  never red.
- **Pace label**: idea 82's wording and number format — `formatPace(n)`
  (~4852) with "About N a day / a week / a month" as in
  `renderReadsCycle()`. Pick the smallest unit where N ≥ 1 (a day, else a
  week, else a month). Finish-date projection for
  pace plans: "Done around Jan 10".

### Credit (the Plan chip)
In `checkPendingRead()`, right after `incrementVisitCount(...)`, call a new
top-level `creditPlansForRead(talk, creditDate)`:
for every plan (personal and shared) whose list contains the talk, if the
talk isn't already credited this round, and `creditDate ≥ startedAt`, set
`planCredits[planId].talks[key] = creditDay`. Then save, refresh chips,
update Home cards, `scheduleCloudPush()`, reschedule the reminder (§8),
check for a finish (§9), and for shared plans call
`setSharedPlanProgress` (§10). Talks read before being added, or before
the plan started, simply aren't credited until they're read again — that
is the decided rule.

### Display
- **Plan chip** (M2): brass outline pill with a check, text "Plan",
  next to the existing Read badge in rows on **that plan's list page**
  only. Read ×N is unchanged.
- **Plan header** (M2), replacing nothing — it sits above the sort chips:
  "8 of 20 in this plan", progress bar, "On pace", "Finish by Dec 24 ·
  About 2 a week".
- **Up next** = first talk in plan order without a credit this round.
  Tinted row with an "UP NEXT" eyebrow.
- Plan lists get a small "Plan" marker in My Lists.

## 7. Home (M1)

Under the Talk of the Day zone: eyebrow **Your study plans** + **See all**.
Up to two slender cards (most recently credited plans first; ties by
soonest finish), each: progress ring `done/total`, plan name (+ "Shared"
tag), "Next: <title>", and on the right:
- brass **check** when a plan credit was logged today, or (pace/week)
  this week's target is met;
- otherwise for pace/week, "1 of 3 this week"; otherwise nothing.
Tap → the plan's list page with Up next scrolled into view. A finished
plan's card shows "Finished ✓" for the rest of that day, then leaves Home.
Hidden entirely when there are no active plans.

## 8. Reminders (M4) — app only

Replaces the Talk of the Day reminder whenever any plan with
`reminder: true` needs a read; same time, same Settings switch, same
quiet hours. If no reminder plan needs a read that day, the normal Talk of
the Day text goes out. Conference days (idea 87) keep the conference text.

Body:
- One plan: **Up next in {plan name}** / “{title}” · {speaker}
- Several due: name the plan **furthest from its pace** (largest
  `expected − done`; tie → soonest finish), then "Plus N more plan(s) with
  a talk waiting."

**Mechanics.** A notification's text can't be chosen at delivery time, so
this reuses idea 87's dated-reminder approach: while any reminder plan is
active, `dailyReminderPlan()` returns **dated** reminders for each of the
next days (one per day, ids in a new block, e.g. `300–339`), each body
computed assuming no further reads (the next talk can't change unless
they read, and a read reschedules). Fold this into `dailyReminderPlan()`'s
`signature` (include each plan's done/total/next/finishBy) so
`refreshDailyReminderPlan()` reschedules on foreground; also reschedule
after every plan credit, plan edit, and sync merge that touches plans.
`cancelDailyReminder()` / `isDailyReminderId()` must include the new
block.

**Known trade-off — builder to verify.** Dated reminders run out after
the window (40 days) if the app is never opened. Check whether Capacitor
LocalNotifications can keep a generic daily fallback without double-firing;
if not, accept the trade (same one idea 87 made) and record the finding
in `ENGINEERING_NOTES.md`.

## 9. Added talks mid-plan (M6)

Only for **date** plans; pace plans just move their projected finish date
quietly. Removing talks recalculates quietly.
- Don't interrupt the add (it stays one tap). The question appears as a
  banner inside the plan header the next time the plan's page is opened,
  so several adds produce one question.
- Show it only if `total > anchor.total` **and** the rounded pace label
  would change. Otherwise re-anchor silently.
- Copy: **You added 3 talks to this plan.** / Keep your finish date, or
  keep your pace? / [**Keep Dec 24** · About 2 a week] (primary)
  [**Keep my pace** · Done around Jan 10].
  - Keep date → re-anchor with the same `finishBy`.
  - Keep pace → compute the date that keeps the pace before the add,
    set `finishBy`, re-anchor.
- New talks show a small "New" tag until the question is answered.
- Shared plans: only the owner sees the banner (members just see the new
  total).

## 10. Shared plans (M5, M9)

Built on shared lists (idea 57). Requires sign-in, as shared lists do.
- **Owner** makes it a plan, sets order and pace (new callables
  `setSharedListPlan {listId, plan|null}` and `setSharedListOrder`, owner
  only via `list.ownerUid === uid`). Owner can't be bypassed client-side
  because clients never write the doc.
- **Members** follow the owner's order and goal; their **progress is
  personal** (their own `planCredits['live:<id>']`).
- **Together number**: callable `setSharedPlanProgress {listId, round, count}`
  writes the caller's count into `sharedListProgress/{listId}` and
  recomputes `planTogether.reads` on the list doc in one transaction.
  The list page shows **You: 4 of 12 · On pace** and **Together: 13 reads
  this plan so far**, plus "Studying together · 4 people · 3 talks a week".
  Never a per-person breakdown or ranking.
- **Leaving** (M9): extend the existing confirm copy:
  "Leave “{name}”? You can keep your own copy as a study plan, with the
  same order and finish date, and the {n} talks you've already finished."
  Buttons unchanged (Leave / Leave & Keep a Copy). `leaveLiveList(list,
  true)` must also copy the plan settings (as a personal plan, reminder
  kept as it was) and move `planCredits['live:<id>']` and badges to the
  new collection id. The owner's **Stop Sharing** path does the same.
  `removeMemberInTx` should drop the leaver from `sharedListProgress`
  and recompute `planTogether`.
- **Owner leaves**: the existing hand-over makes the earliest-joined
  member owner; plan/order fields stay on the doc, so they inherit control.
- **Start it again** in a shared plan is owner-only and bumps the shared
  `round` for everyone (members' earlier badges stay — they're in each
  member's own data).

## 11. Finishing (M7, M8)

When `done === total` (total > 0) after a credit:
- Push `{round, name, talkCount, startedAt, finishedAt}` to
  `planBadges[planId]`. No celebratory modal (avoid stacking with other
  modals); the plan's Home card shows "Finished ✓" today.
- The **plan header becomes the badge**: brass medal (open-book icon),
  eyebrow "Study plan finished", plan name, "23 talks · Oct 19 to Dec 20",
  buttons **Share** and **Start it again** (resets only this plan's chips
  by bumping `round`; Read ×N untouched).
- If a plan was finished more than once, show "Finished 2 times" under
  the latest.
- **Not** added to the trophy drawer / `BADGE_DEFS`; not counted in the
  stats card.
- **Share**: `buildAchievementShareCardBlob({ title: name, desc: '23 General Conference talks in 9 weeks', dateLine: 'Finished Dec 20, 2026', centerpiece: <medal> })`
  in the sender's palette, then `openShareComposeModal` with suggestion
  “I just finished my study plan, “{name}”: {n} General Conference talks
  in {duration}.” and `linkUrl` = findatalk.com. The list itself is never
  attached. Duration: "in N days" under 14 days, else weeks.
- Shared plans: each member earns their own badge when *they* finish.

## 12. Suggested build order (one branch, separate commits)

1. **My order** + reorder + order sync (personal), shared `order` + callable.
2. **Personal plans**: data, setup sheet, math, credits, Plan chip, plan
   header, Up next, Home cards, added-talks banner.
3. **Finish badge** + share card + Start it again.
4. **Reminders** (dated plan reminders inside `dailyReminderPlan()`).
5. **Shared plans**: callables, `sharedListProgress`, Together number,
   leave/keep-copy carry-over.

## 13. Release + paperwork

- `docs/index.html` → website immediately; apps need new builds.
- `functions/index.js` (+ `firestore.rules` for `sharedListProgress`
  read/write false — technically already denied by default, but add it
  explicitly next to the other shared-list rules) → Brad runs
  `firebase deploy`. Ship functions **before** the app build that calls them.
- **CHANGELOG** (Added): study plans, reorder lists, shared plans, plan
  reminders, finish badge. Note new builds needed.
- **DECISIONS**: plan reminder replaces TOTD reminder (one ping a day);
  Plan chip separate from Read ×N and only counts reads after joining the
  plan; finish badge stays out of the trophy drawer; shared plans show a
  combined number only (MISSION: no comparison); added-talk question asked
  on the plan page, not at add time.
- **ENGINEERING_NOTES**: the order-merge gotcha (member union loses
  order) and whatever the reminder-fallback check finds.
- **IDEAS.md**: move 88 to In progress / Done as it lands.
- `docs/privacy.html` is already stale (account sync, shared lists); shared
  plans add per-member progress counts stored server-side. Flag to Brad.

## 14. Test checklist

- Reorder on phone; add a talk on the website; both devices end with the
  phone's order plus the new talk at the end.
- Talk read before it was added → no Plan chip; read again after → chip.
- Date plan math: start, mid-plan add (banner shows only when the label
  changes), Keep date vs Keep my pace, remove a talk.
- Pace/week: "1 of 3 this week" → check at 3; week rollover.
- Home: 0, 1, 2, 3 plans; check appears on a credited read; finished-day
  state.
- Reminder: one plan due; two due (furthest-from-pace named, "+1 more");
  nothing due → TOTD text; conference day → conference text; read clears
  today's plan text; reminder switch off → nothing.
- Shared: owner edits order/pace, member sees lock line; member progress
  updates Together; leave & keep copy carries plan, chips, order; owner
  leaves → next member can edit.
- Finish: badge replaces header, share card renders in each palette,
  Start it again resets chips only.
- Clear Data and Import/Export round-trip all new maps.
