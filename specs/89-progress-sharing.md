# Idea 89 — Progress sharing / accountability buddy (spec, not built)

Status: **spec only — not started.** Written 2026-10-23 from a conversation
with Brad. This is **Part 2** of study plans. Part 1 (idea 88) is built
and ships first, on its own (see `specs/89-build-plan.md` section 2); it is
currently switched off (`STUDY_PLANS_ENABLED = false` in `docs/index.html`).
This spec builds on it and waits for the age-permissions plan to be settled.

Keep this file out of `docs/` (that folder is the public site).

---

## 1. What it is

A person in a study plan can choose to let **one other person** see how
they're doing, as a "help me stay on course" or **accountability buddy**
relationship. Two real situations drove it:

- **Parents** who want to see their children's progress.
- **Seminary teachers and church leaders** who want to see their class's
  progress.

It is **not** a group leaderboard. Idea 88 deliberately shows each member
only their own progress plus one combined "Together" number; that stays
true for the group view. This feature is a separate, consented, one-way
sharing relationship layered on top.

Mission check: no guilt, no comparison, no pressure. Sharing is always the
sharer's choice, and a leader never sees who has *not* shared.

## 2. Decisions made (don't re-open without Brad)

| # | Decision |
|---|---|
| Consent | Opt-in by the person being watched, per viewer. Never on by default, never all-or-nothing for a whole group. |
| Direction | Either side can start: a member can offer ("Share my progress with…"), or a viewer can ask ("Would you like to share your progress with me?"). The member must accept. |
| Declines | A decline (or ignoring a request) looks identical to not having been asked. No "declined" or "pending" status is shown to the requester beyond "Requested". |
| Stopping | The sharer can stop at any time; the viewer's access ends immediately and the viewer is not notified with anything accusatory (just removed from their list). |
| What a viewer sees | Only: done / total for the plan, and the last day the person finished a plan talk. Never which talks, notes, reading times, streaks, or Read counts. |
| No ranking | Rosters are in join order or alphabetical. No sort-by-progress, no "behind" / "needs encouragement" label, no red, for leaders too. |
| Framing | Wording is "accountability buddy" / "help me stay on course". The control lives in the plan's own settings, so it reads as the member's own choice. |

## 3. Age model (decided 2026-10-23 after the children's-privacy research)

Research summary (full sources in `specs/89-build-plan.md` section 1): COPPA
applies to us for any user we have *actual knowledge* is under 13 (Brad's
own two children count); disclosing a child's data to anyone other than the
parent needs verifiable parental consent; Apple (not Kids Category,
guideline 5.1.4(b)) and Google Play (Families policy, if the declared
audience includes under-13s) both require an accurate privacy policy and
honest store forms, and Play adds a neutral age screen and adult controls
for social features.

| Group | What's allowed |
|---|---|
| **13+ (teens and adults)** | Full feature: opt-in buddy sharing with any member of the same shared list, including seminary teachers and church leaders. |
| **Under 13, with a parent** | Parent-initiated only. The parent invites the child; the parent's own signed-in account is the consent record. The parent sees only done / total and the last-read day. The child's account is *supervised*: no leader sharing, no joining shared lists unless the parent allows it. |
| **Under 13, with a leader** | **Not in v1.** It is a disclosure to a third party and needs real verifiable parental consent per child. Revisit only with legal advice. |

Rules that follow from this:
- A **neutral age screen** (a plain birth-year/month question, no hint of
  the "right" answer, shown once when someone first signs in) records
  `ageBand: 'under13' | '13plus'` on the account. Under-13 answers create a
  supervised account only through a parent (see build plan stage 2); a child
  who answers under 13 alone is told a parent needs to help and gets the
  no-account experience (the app works fully without an account).
- We keep **no analytics, ads or tracking** (already true; keep it true).
- Children's data is **never used for anything but running the app**, and a
  parent can see and delete it (Settings → Delete My Account already
  deletes; add "delete my child's data" for the parent).
- The privacy policy's children's section is rewritten before any release
  (draft in `specs/89-privacy-children-draft.md`).

### Still open (needs Brad / a lawyer)
1. Is "the parent signs in with their own account and approves" enough as
   verifiable parental consent, or does it need one of the FTC's listed
   methods (card transaction, signed form, ID check)? **Ask a privacy
   lawyer before building the under-13 parent flow (stage 5).** Stages 1–4
   (13+ only) do not depend on the answer.
2. Are Firebase Authentication and Cloud Firestore acceptable for a
   mixed-audience app under Google Play's Families policy? Firebase's own
   pages say nothing on children; check Google's approved-SDK list in Play
   Console / ask Play support before declaring under-13s as part of the
   audience.
3. International: the EU/UK treat children under 13–16 differently. Until
   decided, supervised under-13 accounts are US-only or off for other
   regions.
4. Nudges ("send encouragement") stay out of v1.

## 4. User experience

### Member (the person being watched)
- In a plan's settings (and on a shared plan's page): **Accountability
  buddy** row. Tap → choose from the list's members, or accept a pending
  request. Shows who currently sees your progress, with **Stop sharing**
  next to each.
- Incoming request: a quiet card on the plan page, "{Name} would like to
  follow your progress in "{plan}". [Share] [Not now]". "Not now" removes
  the card and tells the requester nothing.
- Copy never says "accountable to" in a heavy way; headline is **"Help me
  stay on course"**.

### Viewer (parent, teacher, buddy)
- On the shared plan's page, a **People I'm following** section listing
  only members who currently share with them: name, "6 of 12", "Last read
  Oct 21". Roster order = join order. No bars comparing people, no
  highlighting.
- A **Request** button next to a member who isn't sharing; after tapping it
  shows "Requested" and nothing further.

## 5. Data and security

Today per-member counts live in `sharedListProgress/{listId}`
(`{round, counts:{uid:n}}`, rules `read, write: if false`) and clients only
see the combined `planTogether.reads`. Keep that rule.

Add (all written only by callables, rules stay deny-all for clients):

```js
// sharedListWatchers/{listId}  — who may see whom
{ grants: { [memberUid]: { [viewerUid]: { grantedAt } } },
  requests: { [memberUid]: { [viewerUid]: { requestedAt } } } }
// sharedListProgress/{listId} extends counts with the last day:
{ round, counts: { [uid]: n }, lastDay: { [uid]: 'yyyy-mm-dd' } }
```

New callables in `functions/index.js`:
- `requestPlanProgress {listId, memberUid}` — viewer asks; both must be
  members; writes `requests`.
- `setPlanProgressShare {listId, viewerUid, share}` — the **member**
  grants or revokes (and clears the matching request). A member can only
  change their own grants.
- `getPlanProgress {listId}` — returns, for the caller as viewer, only the
  members who have granted *them*: `{uid, name, done, total, lastDay}`.
  Never returns anyone who hasn't granted. Never returns requests of
  others.
- `setSharedPlanProgress` (exists) also records `lastDay`.
- `removeMemberInTx` clears grants and requests involving the leaver, in
  either direction.

Why not a client-readable field: a field on the list doc would be readable
by every member in devtools, defeating per-viewer consent. A callable that
filters on the grant is the only way to keep it private.

## 6. Release and paperwork

- Needs `firebase deploy` (functions + any rules) **before** an app build
  that calls them, and a new app build for the UI.
- `docs/privacy.html` must be updated: opt-in sharing of plan progress
  (done/total and last-read day) with a chosen member.
- DECISIONS: reverses idea 88's "combined number only" for opted-in,
  consented viewers (record why: parents and class leaders). ENGINEERING_NOTES:
  why a callable and not a readable field.
- CHANGELOG (Added) when it ships.
- Do not re-enable `STUDY_PLANS_ENABLED` for release until this and the
  rest of plans development are ready.

## 7. Test checklist

- A member who never opts in is invisible to every viewer, including the
  list owner, including via devtools / direct Firestore reads.
- Grant → viewer sees done/total and last day, nothing else. Revoke →
  gone immediately.
- Viewer request → member sees card; "Not now" leaves the viewer seeing
  only "Requested" (no declined state).
- Leaving the list clears all grants and requests both ways.
- A leader's roster has no progress-based ordering, colour or label.
- Two real accounts end to end (idea 88's shared plans have not yet been
  tested with two accounts either).
