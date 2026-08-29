# General Conference Random Talk Picker — Handoff to Claude Code

## What this is
A single-file HTML app (`conference-draw.html`) that picks a random General
Conference talk from The Church of Jesus Christ of Latter-day Saints. It has
four **multi-select** filters — Speaker, Calling at the Time of the Talk,
General Conference, Topic — each a custom checkbox-panel dropdown (see
"Multi-select filters" section below), and a styled "ticket" card reveal
when you draw a talk. The ticket shows title, speaker + calling, the talk's
own one-sentence official "kicker" summary (see "kicker summaries" section
below), the conference date, and up to 5 topic chips. Drawing a talk only
*previews* it — it does **not** auto-open a tab. The talk only opens when
the person clicks the ticket's "Open This Talk" link. (This was changed
from an earlier version that did auto-open on every draw — don't
reintroduce that without being asked.)

Open `conference-draw.html` directly in a browser to see current behavior.

**Location note:** the project folder was renamed from `files` to
`FindATalk files` (still under `~/Downloads/`). Full path is now
`/Users/smoothop/Downloads/FindATalk files/conference-draw.html` — if a
path with the old `files` folder name shows up anywhere (old scratch
scripts, memory, etc.), it's stale.

**⚠️ As of the mobile-packaging Phase 1 refactor (see the dedicated section
below), `conference-draw.html` is no longer the live app.** It's kept
unmodified as a legacy/reference standalone copy (still fully working if
opened directly). **The current app lives in `docs/`** —
`docs/index.html` (shell + logic, same UI) and `docs/data.json` (all six
data structures, fetched at runtime). Any future feature work or data
edits should target `docs/`, not `conference-draw.html`, unless
specifically doing a one-off legacy-file fix.

## Current data state
**⚠️ The numbers below are stale — kept for historical color only.** For
the real, current totals, see the most recent `## ✅ Done:` section
further down this file (search for "the standing gap is FULLY CLOSED"
for the latest milestone). As of that session: **3762 real, verified
talks** across **104 conferences**, pulled directly from the Church's
own session listing pages (not invented/hallucinated — each talk's
title, speaker, and URL slug was read off the actual
`churchofjesuschrist.org` contents page for that conference), spanning
**every single conference from October 1974 through April 2026 with no
gaps and no standalone entries left** — this was the original state at
the time this "Current data state" section was first written:
- **2052 real, verified talks** across **57 conferences**, pulled directly
  from the Church's own session listing pages (not invented/hallucinated —
  each talk's title, speaker, and URL slug was read off the actual
  `churchofjesuschrist.org` contents page for that conference).
- Conferences covered: October 1974, April 1987, October 1995, then a
  **continuous run from October 1999 through April 2026** (54 conferences
  in a row, no gaps — October 2002 used to be the start of the continuous
  run before this session's additions pushed it back to October 1999; a
  gap between October 1995 and October 1999, 1996–1999, still remains).
- Administrative agenda items were deliberately excluded from the talk pool:
  "Sustaining of Church Officers/General Authorities," "Church Auditing
  Department Report," and "Statistical Report." These aren't really talks.
  Note: opening/closing addresses with real titles (e.g. "Welcome to
  Conference," "Until We Meet Again," "As We Close This Conference") ARE
  kept as real talks — only the three admin-report titles above are
  excluded.
- Topics use the Church's **official topic taxonomy** (317 topics with ≥1
  matching talk, out of 335 total), not keyword-guessing — see
  `TOPIC_LOOKUP`/`TOPIC_LABELS` in the file. 4 talks (all from the Oct 2010
  women's session) matched zero official topics — that's expected, not a
  bug; `talkTopics()` defaults to `[]`. Built by fetching every
  official topic page (`/study/general-conference/topics/{slug}`) and
  matching its linked talk URLs against `TALKS` by year/month/url-slug.
  Every `TOPIC_LABELS` value is capitalized on its first letter (e.g.
  "Abortion" not "abortion") — keep that convention for any new topic added.

## File structure (inside `conference-draw.html`)
Everything is in one `<script>` block, roughly in this order:

1. **`const TALKS = [...]`** — array of `[title, speaker, year, month, urlSlug]`
   tuples. `month` is the string `"04"` or `"10"`. The full talk URL is
   built as:
   ```
   https://www.churchofjesuschrist.org/study/general-conference/{year}/{month}/{urlSlug}?lang=eng
   ```
   Note: conferences from ~2020 onward use short numeric-code slugs (e.g.
   `57nelson`), while older conferences (pre-~2018) use full title-slugs
   (e.g. `the-lengthened-shadow-of-the-hand-of-god`). Both are valid, real
   URLs — just fetched at different points and copied verbatim from the
   Church's own listing pages, so don't try to "normalize" the slug format.

2. **`const ROLE_LOOKUP = {...}`** — object keyed `"Speaker Name|Year|Month"`
   → one of ten role strings: `president`, `first-presidency`, `apostle`,
   `relief-society`, `primary`, `young-women`, `young-men`,
   `presiding-bishopric`, `seventy`, `other`. This is **role at the time of
   that specific talk**, not "who they are broadly" — e.g. Gordon B.
   Hinckley is `apostle` for his 1974/1987 talks but `president` for
   1995/2005, because that's what he actually held on those dates.
   `first-presidency` means *Counselor* in the First Presidency
   specifically — the President himself always gets `president`, never
   `first-presidency` (so a First Presidency member is one or the other,
   never both, for a given talk); a First Presidency counselor is also
   technically still an ordained apostle, but gets `first-presidency`
   instead of `apostle` while serving in that calling. `seventy` covers the
   modern General Authority/Area Seventy offices and their pre-1976
   equivalents (Assistant to the Twelve, First Council of the Seventy) —
   see "Seventy role backfill" below for exactly how it was assigned and
   its known limitations. `other` is for a real, identifiable calling that
   doesn't fit any of the other nine (currently just Eldred G. Smith,
   Patriarch to the Church, 1974) — it is *not* a catch-all for "unknown";
   leaving a talk untagged is still what "unknown/not researched" means.
   Every entry was manually
   researched/verified (ordination dates, succession dates, etc.), including
   live web searches for recent transitions (Oaks becoming President Oct 14
   2025 with Eyring/Christofferson as counselors, Caussé moving from
   Presiding Bishop to the Twelve Nov 2025, First Presidency composition
   across every era in the dataset back to 1974).
   `const ROLE_LABELS = {...}` maps role keys to display strings.
   `function talkRole(talk)` looks up a talk's role.

3. **`const TOPIC_LOOKUP = {...}` / `const TOPIC_LABELS = {...}` /
   `function talkTopics(talk)`** — official Church topic tags, see "Current
   data state" above. (The old keyword-guessing `TOPICS`/`talkTopics(title)`
   system this replaced is gone; if you see references to it anywhere
   that's stale.)

4. **Filter-building/cascading logic** — `filterState` (each dim an array,
   multi-select), `DIM_CONFIG`, `rebuildFilterOptions()`, `renderOptions()`,
   `poolExcept()`, `matchesDim()`, `currentPool()`, `refreshCount()`. Each
   filter is a custom checkbox panel (see "multi-select filters" below),
   rebuilt on every change to only show checkboxes for values that remain
   reachable given the other three filters (omitted, not just disabled),
   while always preserving whatever the user currently has checked so it
   never disappears out from under them.

5. **Draw logic** — `draw()` picks a random talk from the current filtered
   pool, avoids immediate repeats, and renders the ticket card (title,
   speaker + role, meta, up to 5 topic chips — any active topic filter(s)
   the talk actually has are always kept among those 5 rather than risking
   truncation). It does **not** open any tab itself; `openLink.href` is set
   to the real talk URL and the tab only opens if the person clicks "Open
   This Talk".

## Design notes
- Palette/typography follows a "conference program bulletin" aesthetic:
  ivory paper background, deep indigo ink, brass/gold accents, Fraunces
  (display serif) + Source Serif 4 (body). Deliberately avoided the
  generic cream+terracotta AI-cliché look.
- Single HTML file, no build step, no external JS dependencies except
  Google Fonts.

## ✅ Done: official topic taxonomy
Verified that each topic page (`/study/general-conference/topics/{slug}`)
links directly to every talk tagged with it — real hrefs, going back to
1971, no pagination. Fetched all 335 official topic pages via `curl` and
matched their linked talk URLs against `TALKS` by exact
`year|month|url-slug`. Result: `TOPIC_LOOKUP` (one entry per talk, real
tags) and `TOPIC_LABELS` (Title Case, first letter always capitalized)
replaced the old keyword-guessing system entirely.

## ✅ Done: backward coverage to April 2015 (no gaps)
Added April/Oct 2016, April/Oct 2017 (143 talks), then October 2015 (39
talks), so the continuous run now goes **April 2015 → April 2026**, plus
the older standalone conferences (Oct 1974, Apr 1987, Oct 1995, Oct 2005).
Role tags were hand-verified against Wikipedia/news sources rather than
assumed from memory — Presiding Bishopric composition per era, YM/RS/YW
presidency succession dates, the exact conference at which 2015's three
new apostles (Rasband/Stevenson/Renlund, sustained Sat Oct 3 2015) gave
their first talks as apostles the very next day.

## ✅ Done: "Member of the First Presidency" role
Added `first-presidency` as its own role, distinct from `apostle` — a
Counselor in the First Presidency is still an ordained apostle, but this
app now tags the more specific office. Retagged every First Presidency
counselor across the whole dataset (52 talk-entries) by researching the
exact counselor lineup for every era present: N. Eldon Tanner/Marion G.
Romney under Kimball (1974) → Hinckley/Monson under Benson (1987) →
Monson/Faust under Hinckley (1995, 2005) → Eyring/Uchtdorf under Monson
(2015–2017) → Oaks/Eyring under Nelson (2018–Oct 2025) → Eyring/
Christofferson under Oaks (2026). The President himself always keeps
`president`, never `first-presidency`.

**While auditing this, found and fixed 5 pre-existing gaps** — real talks
by known permanent-role holders (Jeffrey R. Holland, Ronald A. Rasband ×2,
Russell M. Nelson, Gérald Caussé) that had simply never been tagged. Caught
by an automated check: any untagged talk whose speaker has the *same* role
tagged both before and after it chronologically is almost certainly a
missed tag, not a real transition — worth re-running that check
(`sandwiched gaps` logic) after any future bulk edit.

## ✅ Done: "Member of the Seventy" role backfill
Added `seventy` as a role and default-tagged 298 previously-untagged talks
with it, per an explicit user decision to prioritize speed over exhaustive
per-person verification (231 distinct untagged speakers was too many to
fully research). **Methodology — read this before adding more talks or
re-running this kind of pass:**
- Every untagged speaker from **1995 onward** was tagged `seventy` by
  default (this is genuinely how the vast majority of general-conference
  speaking slots not otherwise covered are filled).
- **28 talk-entries by clearly-female speakers were deliberately left
  untagged**, not tagged `seventy` (Seventy is a male priesthood office).
  These are Relief Society/Primary/Young Women general-presidency
  *counselors* (not the president, who already gets tagged) — the app's
  role categories don't currently track counselor-level auxiliary callings,
  so these stay untagged by design, matching how it already worked before
  this pass. Full list of the 18 names is reconstructable from `git`-free
  diffing, or just search ROLE_LOOKUP for `seventy` gaps among women's-
  session-adjacent talk titles.
- **October 1974 and April 1987** used different, pre-1976-reorganization
  office titles (Assistant to the Quorum of the Twelve, First Council of
  the Seventy) rather than the modern "Seventy" terminology. These were
  researched individually rather than defaulted. One exception found:
  **Eldred G. Smith (1974)** was Patriarch to the Church — a unique
  non-Seventy office — and was correctly left untagged.
- **Known judgment call, not fully verified**: several Sunday School
  General Presidency members (Devin G. Durrant, Brian K. Ashton, Tad R.
  Callister, Mark L. Pace, Milton Camargo, Jan E. Newman, Chad H Webb) were
  tagged `seventy` by the same default rule. Some Sunday School presidents
  concurrently hold General Authority Seventy status (confirmed for Paul V.
  Johnson and Mark L. Pace) but it's *not* confirmed for the lay/CES-career
  counselors like Chad H Webb — he may not actually be a Seventy. If a user
  flags this, the fix is a targeted correction, not a full re-audit.
- One more pre-existing gap fixed in passing: Gérald Caussé's April 2020
  talk was missing its `presiding-bishopric` tag (sandwiched between two
  correctly-tagged conferences during his known 2015–2025 tenure).

## ✅ Done: `other` role, for callings that don't fit any tracked category
Added a 10th role, `other`, for speakers whose calling is real and
identifiable but doesn't match any of the nine tracked categories (not an
"I don't know" bucket — that's still what leaving a talk untagged means).
Applied it to the one confirmed case already flagged in the "Seventy
backfill" section above: **Eldred G. Smith (Oct 1974) — Patriarch to the
Church**, a distinct, non-Seventy priesthood office (emeritus since 1979,
never refilled, so he's the only possible case in this dataset). He had
been deliberately left untagged before; now he's `other` instead.

**Not an exhaustive audit** — two other candidates were checked and
deliberately left as `seventy` rather than moved to `other`, so don't
re-research them: **Joseph Anderson (1974)** was "Assistant to the Twelve"
at that exact date (a direct historical predecessor of General Authority
Seventy, formally merged into the First Quorum of the Seventy in 1976) —
close enough to keep as `seventy`. **F. Michael Watson (2009)** was
already a sustained General Authority Seventy (called April 2008) by the
time of his one talk in this dataset, even though he'd spent 1972–2008 as
a non-General-Authority Secretary to the First Presidency before that —
so `seventy` is correct for the talk that's actually here. If a future
pass finds a mission president, temple president, or similar one-off
speaker who was never sustained a General Authority at all, that's the
kind of case `other` is for — reclassify from `seventy` (or add fresh if
untagged), don't leave it as-is.

## ✅ Done: role/UI label renames (role *keys* in the code are unchanged)
Several user-facing labels were renamed — these are cosmetic (`ROLE_LABELS`
values and static HTML text only); the underlying `ROLE_LOOKUP` keys
(`apostle`, `first-presidency`, etc.) and all matching logic are untouched,
so don't be confused if older sections above still say the old names:
- Filter label "Church Role at the Time" → **"Calling at the Time of the
  Talk"**; its "Any role" default option → **"Any Calling"**.
- Role label `apostle`: "Apostle" → **"Quorum of the Twelve Apostles"**.
- Role label `first-presidency`: "Member of the First Presidency" →
  **"Counselor in the First Presidency"**.
- Year filter label "Year / Decade" → **"General Conference"**; its "Any
  year" default → **"Any Conference"**.
- A "Reset filters" button was added below the filter grid (`#resetBtn`) —
  disabled when no filter is active. (Originally cleared four native
  `<select>` elements; superseded by the multi-select rewrite below, but
  the button and its disabled-when-empty behavior are unchanged.)
- Speaker options are alphabetized **by last name** and displayed
  "Last, First" (e.g. "Hinckley, Gordon B.") via `speakerDisplayName()` /
  `parseSpeakerName()` — handles suffixes (Jr./Sr./II/III), lowercase
  surname particles (de/da/von/van/…), and parenthetical nicknames. The
  underlying value used for matching is still the plain "First Last" name;
  only display text and sort order changed. (See "What this is" at the top
  for the no-auto-open-tab behavior — that's a separate, earlier change,
  still in effect.)

## ✅ Done: multi-select filters (checkbox panels, OR within a dim, AND across dims)
All four filters were rewritten from native single-value `<select>`
elements to **custom multi-select checkbox panels** — you can now check
multiple Topics, Speakers, Callings, or Conferences at once. Semantics:
values *within* one dim are OR'd (Topic = "Faith" OR "Family"); the four
dims are still AND'd together, same as before. Cross-checked against a
brute-force reference filter over `TALKS`/`ROLE_LOOKUP`/`TOPIC_LOOKUP`
directly — exact match.

**Architecture** — for each dim (`year`/`speaker`/`topic`/`role`):
- `filterState[dim]` is now an **array** (was a single string; empty
  string → empty array is the "no filter" sentinel change to watch for if
  you touch this code).
- HTML: a `<button class="ms-trigger">` (shows "Any X" / one label / "N
  things selected") that toggles a `<div class="ms-panel" hidden>`
  containing real `<input type="checkbox">` + `<label>` pairs (native
  semantics, no ARIA listbox pattern needed) — plus a `.ms-search` text
  input for the two long lists (**Speaker** 364 options, **Topic** 306
  options; **Calling** and **Conference** don't get search, short enough
  to just scroll).
- `DIM_CONFIG` now carries DOM refs (`trigger`/`triggerText`/`panel`/
  `options`/`search`/`clearBtn`) alongside `allValues`/`labelFor`/
  `anyLabel`, plus a new `noun` (plural, for the "N speakers selected"
  summary) and `searchable` flag.
- Cascading pruning logic is conceptually unchanged (`valuesForDim(
  poolExcept(dim), dim)` computes what's still reachable given the *other*
  three dims) — it now populates `availableSets[dim]`, a `Set` consumed by
  `renderOptions(dim)` to decide which checkboxes exist. A currently-
  checked value is always rendered even if no longer "available," same
  never-vanish-a-selection rule as the old dropdown had.
- Only one panel open at a time (`openDim` tracks it); opening one closes
  any other. Closes on outside click, `Escape` (returns focus to the
  trigger), or re-clicking the trigger. A per-panel "Clear" button resets
  just that one dim; the existing global "Reset filters" button still
  clears all four.
- `draw()`'s "keep the filtered-by topic(s) visible among the ticket's
  chips" logic now surfaces *every* selected topic the drawn talk actually
  has (not just one), first in the chip row, before the slice-to-5 cap.

**Bug hit and fixed during this build, worth remembering**: giving
`.ms-panel` an explicit `display:flex` in the author stylesheet silently
**overrides the browser's default `[hidden]{display:none}` rule**, because
author-origin CSS always wins over user-agent-origin CSS regardless of
selector specificity. Result: all four panels rendered permanently open.
Fix is `.ms-panel[hidden]{ display:none; }` alongside the `display:flex`
rule. **Any future custom dropdown/panel/modal in this file needs the same
`[hidden]` override if it sets its own `display` value** — don't rely on
the bare `hidden` attribute once a class sets `display`.

## ✅ Done: backward coverage to April 2012 (no gaps)
Added April/Oct 2012, April/Oct 2013, April/Oct 2014 (225 talks). The
continuous run now goes **April 2012 → April 2026** (29 conferences back
to back), plus the same 4 older standalone conferences. Role research for
this era: Presiding Bishopric transitioned Stevenson/Caussé/Davies ← Burton
/Edgley/McMullin *at* the April 2012 conference itself (same-conference
outgoing officer, tagged with the outgoing role — Edgley → presiding-
bishopric, matching how Julie B. Beck's farewell RS-president talk that
same conference was tagged `relief-society`); Relief Society Beck→Burton
transitioned the same day; Young Women Dalton→Oscarson transitioned at
April 2013; Primary was a stable Wixom/Stevens/Esplin presidency April
2010–April 2016 (all three tagged `primary` whenever they speak in that
window — this also caught and fixed a **pre-existing gap**: Cheryl A.
Esplin's April 2016 talk had been left untagged during the Seventy-role
backfill pass since she's female, but she was still a sitting Primary
counselor at that specific conference and should have gotten `primary`).
Ronald A. Rasband and Gary E. Stevenson both appear as `seventy` /
`presiding-bishopric` respectively in 2012–2014 talks — neither was an
apostle yet (both called Oct 2015); don't retag their pre-2015 talks to
`apostle`.

## ✅ Done: backward coverage to April 2009 (no gaps)
Added April/Oct 2009, April/Oct 2010, April/Oct 2011 (224 talks). The
continuous run now goes **April 2009 → April 2026** (35 conferences back
to back). Role notes for this era: Monson/Eyring/Uchtdorf First Presidency
already stable since Feb 2008, so no FP transition to research here. Two
corrections worth remembering — **Gary E. Stevenson was a plain General
Authority Seventy from April 2008 until April 2012** (Presiding Bishop
only from April 2012 on — don't tag his 2009–2011 talks
`presiding-bishopric`), and **Neil L. Andersen was sustained apostle on
the Saturday of the April 2009 conference itself** (same-day-sustaining
pattern, same as Oaks/Rasband/Stevenson/Renlund elsewhere — tag his April
2009 talk `apostle`, not `seventy`). Auxiliary presidencies confirmed for
this window: Relief Society = Beck/Allred/Thompson (Mar 2007–2012);
Primary = Lant/Lifferth/Matsumori (Apr 2005–Apr 2010) handing off to
Wixom/Stevens/Esplin (from Apr 2010); Young Women = Dalton/Cook/Dibb
(2008–2013). 4 talks (Oct 2010 women's session) matched no official
topic — left as `[]`, not a bug.

## ✅ Done: backward coverage to April 2006 (no gaps; Oct 2005 no longer standalone)
Added April/Oct 2006, April/Oct 2007, April/Oct 2008 (232 talks). The
continuous run now goes **October 2005 → April 2026** (42 conferences back
to back) — Oct 2005 stopped being a lone standalone entry once April 2006
was added right after it. This window crossed **two real First Presidency
transitions**, both researched and both landed correctly:
- **James E. Faust died Aug 10, 2007.** Henry B. Eyring succeeded him as
  Second Counselor *at* the October 2007 conference itself (same-day
  pattern) — his Oct 2007 talks are `first-presidency`; his April 2006/Oct
  2006/April 2007 talks are plain `apostle` (he wasn't in the FP yet).
  Quentin L. Cook was called to the Twelve that same Oct 6 2007 to backfill
  Eyring's vacated seat, but didn't have a talk that conference.
- **Gordon B. Hinckley died Jan 27, 2008.** Thomas S. Monson became
  President Feb 3, 2008 — before the April 2008 conference, so no
  mid-conference edge case there; he's simply `president` for Apr/Oct 2008.
  Same day, Monson set apart Eyring (1st) and Uchtdorf (2nd) as his new
  counselors; both were *sustained by the membership* at the April 2008
  solemn assembly, so both get `first-presidency` starting April 2008 (Uchtdorf's
  first FP tag — he was plain `apostle` for every 2005–2007 conference
  before this). **D. Todd Christofferson was also called and sustained
  apostle that same April 2008 conference** (from the Presidency of the
  Seventy) — his April 2008 talk is `apostle`; every earlier talk of his in
  the dataset is `seventy`.
- Auxiliary transition also researched: Julie B. Beck moved from Young
  Women counselor to Relief Society General President at the March 31 2007
  conference (same-day pattern again) — her Apr 2006/Oct 2006 talks are
  `young-women`, her Apr 2007 talk onward is `relief-society`. Susan W.
  Tanner (YW president 2002–Apr 2008) and Bonnie D. Parkin (RS president
  until Mar 2007) both confirmed via search, not assumed.

## ✅ Done: backward coverage to October 2002 (no gaps)
Added April/Oct 2005 (well, Apr 2005 — Oct 2005 was already in), Apr/Oct
2004, Apr/Oct 2003, and Oct 2002 (215 talks). The continuous run now goes
**October 2002 → April 2026** (48 conferences back to back), plus Oct
1995, Apr 1987, Oct 1974 standalone (gap 1996–2001 still exists before Oct
2002). Confirmed the Hinckley/Monson/Faust First Presidency (Mar 1995–Aug
2007) needed no new research — stable across this whole window. Two real
transition cases researched and correctly split by conference:
- **Dieter F. Uchtdorf** was a Presidency of the Seventy member (plain
  `seventy`) through his one talk in this batch at **Oct 2002**; he and
  **David A. Bednar** were both sustained apostle in the *opening minutes*
  of the **Oct 2004** conference (filling vacancies left by Neal A.
  Maxwell's and David B. Haight's deaths that same summer) — both tagged
  `apostle` from Oct 2004 on, no same-day ambiguity since the sustaining
  came before any talks that conference.
- **Julie B. Beck and Elaine S. Dalton were Young Women presidency members
  (1st and 2nd counselor) for this entire batch**, not Relief Society —
  Beck doesn't become RS president until March 2007 (already correctly
  handled in the 2006–2008 batch). Don't retag their 2002–2005 talks
  `relief-society` by pattern-matching from later batches. Relief Society
  for this window was **Bonnie D. Parkin** (president, Apr 2002–2007) with
  **Kathleen H. Hughes** (1st) and **Anne C. Pingree** (2nd). Primary was
  **Coleen K. Menlove** (president, Oct 1999–Apr 2005) with **Sydney S.
  Reynolds** (1st) and **Gayle M. Clegg** (2nd), handing off to
  Lant/Lifferth/Matsumori exactly at April 2005 (already in the dataset).

## ✅ Done: Share button on every result (ticket + each list row)
Added a Share affordance to both result surfaces:
- **Ticket**: a third button in `.ticket-actions`, `#shareBtn` (text
  "Share", styled `.btn.btn-ghost` like "Find Another"), between "Open
  This Talk" and "Find Another". Shares `lastPicked` (the same variable
  `draw()` already tracks for its no-immediate-repeat logic).
- **List rows**: a small round icon-only button (`.share-btn-icon`, the
  `SHARE_ICON_SVG` inline three-node share glyph) at the top-right of each
  row's new `.list-item-head` wrapper (title link + share button side by
  side). Each row's button closes over its own `pick` from the `forEach`
  in `showList()`.

**Behavior** (`shareTalk(pick, btnEl)`): tries `navigator.share()` first
(native OS share sheet — best on mobile/supporting browsers) with the
talk's title, "title — speaker" text, and real URL. If the person cancels
that sheet (`AbortError`), it does nothing further — that's a normal
outcome, not a failure. If `navigator.share` isn't available, or throws
anything other than a cancel, it falls back to `copyText()`, a two-tier
clipboard helper: async `navigator.clipboard.writeText()` first, then a
legacy hidden-textarea + `document.execCommand('copy')` fallback if that
fails. **The legacy fallback matters a lot here**: this app is normally
opened as a local `file://` page, and several browsers only grant
`navigator.clipboard.writeText` on secure/HTTPS origins — the
`execCommand('copy')` path has much broader `file://` support and is why
it's there, not just defensive padding.

After a successful or failed copy, `flashShareButton()` briefly swaps the
button's content to "Link copied!" / "Copy failed" (reading the original
content once into `dataset.defaultHtml` so repeated clicks don't stomp
it), then restores the original label/icon after 1.6s. The icon button
also gets an `.is-flashed` class while showing the message so its normal
30px circle can widen enough to fit the text without clipping.

**⚠️ Verification gap, same as the last two features**: the Browser-pane
tool has now been unavailable for the Claude session's entire remaining
duration — every `file://` navigation attempt, including a one-line test
file, silently returns an inert placeholder instead of loading real
content, across many retries in fresh tabs. This was **not** visually
tested in a real browser. What was checked instead: full JS bracket/
string-syntax balance (clean), and a complete cross-check of every
`getElementById` call in the file against every HTML `id=` attribute (all
matched — the only unmatched entries were `roleLabel`/`speakerLabel`/
`topicLabel`/`yearLabel`, which are intentionally referenced via
`aria-labelledby` rather than JS, not a bug). The share logic was traced
by hand line-by-line rather than executed. **If the Browser-pane tool
recovers in a future session, or the user tests it themselves, both share
buttons (ticket and at least one list row) should get a real click-through
— including confirming the "Link copied!" flash actually reverts after
~1.6s and that a pasted link is the correct real talk URL.**

## ✅ Done: "Show a List" — up to 10 matching talks at once
Added a second button next to "Find a Talk": **"Show a List"** (`#listBtn`,
in a new `.draw-buttons` flex row alongside `#drawBtn`). Instead of one
random talk, it shows up to `LIST_SIZE` (currently 10) — or every matching
talk if fewer than that remain after filters — as a scannable list, each
row showing: title (a real link, opens in a new tab, same as "Open This
Talk"), speaker + calling, conference date, and the kicker summary if the
talk has one. The user explicitly framed this as turning the app into "a
search and study tool," not just a randomizer, so the list is meant to be
*browsed*, not just one more random draw.

- **Selection**: a Fisher-Yates `shuffled()` of the current filtered pool,
  sliced to `LIST_SIZE` — still random/serendipitous like the rest of the
  app, just showing several at once instead of one. Clicking "Show a List"
  again re-shuffles; so does the "Show a different list" link at the
  bottom of the list itself (`#listAgainBtn`, reuses the `.reset-link`
  style).
- **Header text** adapts: "Showing 10 random talks of 340 that match right
  now" when the pool is bigger than `LIST_SIZE`, vs. "Showing all 6 talks
  that match right now" when the whole pool fits.
- **Mutual exclusivity with the single-ticket view**: `draw()` hides
  `#listZone`; `showList()` hides `#resultZone` (the ticket) — only one
  result view is visible at a time, matching how the app already only
  shows one thing at once elsewhere. Neither auto-hides when filters
  change (consistent with the ticket's pre-existing behavior of staying
  put until you draw/list again).
- `listBtn.disabled` is wired into `refreshCount()` exactly like
  `drawBtn.disabled` — both disable together when the filtered pool is
  empty.
- New CSS: `.draw-buttons`, `#listBtn`, `#listZone`, `.list-header`,
  `.list-items`, `.list-item` (+ `-title`/`-speaker`/`-meta`/`-summary`
  child classes), `.list-footer` — all namespaced separately from the
  ticket's classes so nothing bled into the single-draw styling.

**Verification note**: this was built and cross-checked the same session
the file crossed the Browser-pane's local-file size ceiling (see "kicker
summaries" below) — and this time the Browser-pane tool itself was down
for the *entire* session (every `file://` navigation, including a
one-line test file, silently fell back to an inert placeholder; retrying
across multiple fresh tabs didn't help). So this feature has **not** been
visually confirmed in a real browser by Claude — only: full bracket/string
JS-syntax balance check (clean), and a from-scratch cross-check of every
`getElementById` call in the whole file against every `id=` in the HTML
(all matched, no typos). The DOM-construction pattern
(`createElement`/`appendChild`/`className`/`textContent`) and the
`talkRole`/`talkKicker`/`talkUrl`/`monthName`/`ROLE_LABELS[role]` lookups
it reuses are all identical to code already proven working in `draw()` —
only the Fisher-Yates shuffle and the list-item DOM assembly are actually
new logic. **Recommend the user (or a future session once the Browser
pane tool recovers) does one real click-through of both buttons before
trusting this fully.**

## ✅ Done: kicker summaries (the one-sentence teaser under speaker/calling)
Every General Conference talk page on the real site has a short official
"kicker" — a one-sentence summary in `<p class="kicker">`, sitting right
after the `<div class="byline">` (speaker name + calling) and before the
talk body. The ticket now shows it too, styled as small italic serif text
between the speaker line and the conference-date line.

- **Data**: `KICKER_LOOKUP`, keyed `"year|month|slug"` → the sentence
  (plain string, not an array — one summary per talk, not a list). Sits
  right after `talkTopics()`/`TOPIC_LOOKUP` in the script, with its own
  `talkKicker(talk)` accessor that returns `null` when a talk has none —
  same `|| null` fallback pattern as `talkRole()`.
- **Coverage**: 1940 of 1946 eligible talks (99.7%) — fetched by
  `curl`-ing every individual talk page (not just conference listing or
  topic-index pages this time) and regex-extracting the kicker paragraph,
  same pattern as everything else in this file. The 6 gaps were checked
  individually and are genuinely kicker-less on the real page (not a
  parsing miss): two ceremonial talks with no natural summary sentence
  (Solemn Assembly 2018, the Hosanna Shout 2020) and four older women's-
  session talks from April 2003 that the Church's site never retroactively
  added one to.
- **The three standalone pre-1999 conferences (Oct 1974, Apr 1987, Oct
  1995) have NO kickers at all** — verified by testing several talks from
  each; the Church's site apparently didn't start adding these until
  sometime between 1995 and 1999 (Oct 1999 is the earliest conference
  confirmed to have them). Don't bother fetching kickers for those three
  conferences if they're ever backfilled with data from other conferences
  — there's nothing there to get. If backward coverage is ever extended
  *before* Oct 1999 (see the "keep expanding backward" task elsewhere in
  this doc), re-check a sample talk from the new era first to see whether
  it has a kicker before assuming either way.
- **UI**: `#ticketSummary` div between `#ticketSpeaker` and `#ticketMeta`
  in the HTML, `.ticket .summary` CSS rule (italic, `Source Serif 4`,
  `--ink-soft` color). In `draw()`, the element's `textContent` and
  `style.display` (`'block'`/`'none'`) are both set based on
  `talkKicker(pick)` — hidden entirely rather than shown empty when a talk
  has none, so there's no dangling gap in the ticket layout.

**Operational note for future large data additions**: the file is now
~793KB. This session discovered the Browser-pane preview tool has a hard
size ceiling for local `file://` URLs somewhere between 512KB and 700KB —
above that it silently fails to load real content (falls back to an inert
CSP-blocked placeholder) instead of erroring clearly. **You cannot load
this file directly in the Browser-pane preview once it crosses that
threshold.** Two workarounds used this session: (1) all *data*-only
validation (integrity/dedup/orphan checks, JS bracket-balance checks) can
still be done directly against the real file via `python3`/`Bash`, no
browser needed — that covers most of what matters; (2) for testing actual
*UI/JS behavior* (like the kicker show/hide logic here), copy the exact
relevant HTML/CSS/JS verbatim into a small standalone test harness in the
scratchpad with a tiny fake dataset, and drive *that* in the browser
instead — it's a faithful test of the real code, just not the real file.
If you copy the real file itself for any reason, note that `cp` preserves
the source's restrictive `600` permissions (inherited from the Downloads
folder) which also blocks the browser tool — `chmod 644` the copy first.

## ✅ Done: backward coverage to October 1999 (no gaps; standing gap shrunk)
Added Apr/Oct 2001, Apr/Oct 2000, Apr 2002 (already had Oct 2002), and Oct
1999 (219 talks). The continuous run now goes **October 1999 → April
2026** (54 conferences back to back). The standing gap before that is now
just **April 1996 through April 1999** (7 conferences), down from the
1996–2001 gap noted previously. No new First Presidency research needed —
Hinckley/Monson/Faust still stable throughout. Auxiliary-presidency
transitions researched and confirmed via search, not assumed:
- **Relief Society**: Mary Ellen W. Smoot (president, Apr 5 1997–Apr 2002)
  with **Virginia U. Jensen** (1st) and **Sheri L. Dew** (2nd), handing off
  to Parkin/Hughes/Pingree exactly at April 2002 (already in the dataset
  from the previous batch) — both outgoing Smoot and incoming Parkin
  tagged `relief-society` for that same transition conference.
- **Young Women**: Margaret D. Nadauld (president, Oct 4 1997–Oct 6 2002)
  with **Sharon G. Larsen** and **Carol B. Thomas** as counselors —
  covers this entire batch with no transition to handle.
- **Primary**: Patricia P. Pinegar (president, 1994–Oct 1999) handed off
  to Coleen K. Menlove *at* the October 1999 conference — Pinegar's only
  talk in this batch (Oct 1999) is her outgoing farewell, tagged `primary`
  same as every other same-conference transition in this project.
- One new pre-1976-era-style figure worth remembering for the next batch:
  **Neil L. Andersen appears as a plain General Authority Seventy in Oct
  1999** (`seventy`, not `apostle` — he wasn't called to the Twelve until
  April 2009). Don't retag his older talks by pattern-matching from his
  later apostolic ones.

## ✅ Done: Phase 1 of mobile packaging — fetch-at-runtime data architecture
The user wants to (a) eventually catalog every conference/talk ever, (b)
keep adding *future* conferences after the app ships, and (c) package this
as an Apple App Store / Google Play app (planned via **Capacitor**). Before
any mobile work, the open question was "how do new talks reach people who
already installed the app?" — the user explicitly chose **"fetch data at
runtime"** over baking all data into each store build. This section is
that architecture.

**New folder: `docs/`** (chosen over Capacitor's default `www/` name so it
doubles as a GitHub Pages source — GitHub Pages has a built-in "serve from
`/docs`" option needing no GitHub Actions — and Capacitor's `webDir` is
configurable, so the same folder can later serve as its web root too):
- **`docs/data.json`** (745,308 bytes) — the six data structures
  (`talks`, `roleLookup`, `roleLabels`, `topicLookup`, `topicLabels`,
  `kickerLookup`) that used to be inline `const` blocks in
  `conference-draw.html`, now as one JSON object plus a `generatedAt`
  timestamp. Extracted via a Python script that parsed the original file's
  `const` blocks and re-serialized them; verified **byte-for-byte
  equivalent** (as parsed structures, via Python `==`) to what was in
  `conference-draw.html` — zero data loss.
- **`docs/index.html`** (44,619 bytes) — same HTML/CSS as
  `conference-draw.html`. The six `const TALKS = {...}` etc. blocks became
  bare `let TALKS;` declarations (assigned later at runtime); every
  function that reads them (`talkRole`, `talkTopics`, `talkKicker`,
  `talkUrl`, `draw`, `showList`, `shareTalk`, etc.) is **byte-for-byte
  unchanged** — they still work via closures once the `let`s are assigned.
  Everything from building the filter panels through the final event
  listener wiring got wrapped in a new `function initApp(){...}` (called
  only after data is ready, instead of running at parse time).

**Bootstrap logic** (appended after `initApp()`, drives the whole load):
`LOCAL_DATA_URL` = `'./data.json'` (bundled copy, always available —
including fully offline in a packaged app, since it reads from the app's
own bundle rather than the network); `REMOTE_DATA_URL` (currently `''`,
**a pending placeholder** — needs the real GitHub Pages URl once that repo
exists, see "Pending before Phase 1 is fully live" below); `DATA_CACHE_KEY
= 'findATalkData'` (the `localStorage` key). Flow, in `loadData()`:
1. Check `localStorage` for a cached copy. If present, use it immediately
   (`applyData()`) — instant load on every relaunch, no network wait.
2. If no cache (first-ever launch), `fetch(LOCAL_DATA_URL)`. On success,
   apply it and cache it. On failure (offline + never launched before, or
   — expected and correct — opened directly via `file://`, which browsers
   block local fetches from), show a plain-text fatal error
   (`showFatalLoadError()`) instead of a broken blank page.
3. Call `initApp()` (only reached once data — cached or fetched — is
   actually ready).
4. If `REMOTE_DATA_URL` is set, kick off a **background** fetch of it.
   Deliberately does **not** hot-swap the running session's data or
   re-wire the UI — it just silently updates the `localStorage` cache, so
   a fresher copy (new conferences, fixes) is picked up on the **next**
   app launch/reload, not mid-session. This avoids needing idempotent
   UI-rewiring logic.

**Verification** (no visual browser pass was possible/needed — see
below): a Node.js test harness
(`/private/tmp/.../scratchpad/bootstrap-test.js`, scratch-only, not part
of the repo) extracted this exact bootstrap block from `docs/index.html`
via regex (verbatim, unmodified) and ran it inside a Node `vm` sandbox
with mocked `fetch`/`localStorage`/`document`, covering 4 scenarios — all
passed: fresh install (fetch succeeds → data applied, `initApp()` called
once, cached), returning visit (cache short-circuits the fetch, still
calls `initApp()` once), fetch failure (fatal error shown, `initApp()`
never called — separately also confirmed **live** via the Browser pane by
opening `docs/index.html` directly as `file://`, which correctly hits
this exact path since local fetches are blocked under `file://`), and
cache-present-plus-remote-configured (renders old cached data this
session, silently refreshes the cache in the background for next time).
**Node is now installed in this environment** (confirmed `v24.19.0` this
session) — prefer it over the old `python3`-based checks below for any
future JS-behavior testing; the file-size-ceiling problem that forced the
verbatim-harness-in-a-browser workaround for earlier features doesn't
apply to Node-based tests at all.

**Git**: local repo, real identity `CaptainFun333` /
`b.christensen333@gmail.com` (replaced the temporary placeholder used to
unblock the very first local commit). No credential helper / `gh` CLI /
Homebrew were available in this environment, so **SSH** was set up
instead of HTTPS+token: generated a fresh `ed25519` keypair
(`~/.ssh/id_ed25519`), the user added the public key at
github.com/settings/keys, confirmed with `ssh -T git@github.com`, then
`git remote set-url origin git@github.com:CaptainFun333/find-a-talk.git`.
(GitHub's "don't add a README" checkbox didn't take — the new repo showed
up with a one-line `README.md` already committed; fixed with `git pull
--rebase` before pushing, no data lost.)

**✅ Phase 1 is now fully live, as of this session:**
1. ✅ Real git identity set (see above).
2. ✅ Repo created: **github.com/CaptainFun333/find-a-talk** (public).
3. ✅ Local commits pushed to `main`.
4. ✅ GitHub Pages enabled, serving from `/docs` — live at
   **https://captainfun333.github.io/find-a-talk/**.
5. ✅ `REMOTE_DATA_URL` in `docs/index.html` filled in with the real Pages
   URL (`https://captainfun333.github.io/find-a-talk/data.json`),
   committed and pushed.

**End-to-end live verification** (real browser, real hosted site, not a
mock/harness): navigated to the live Pages URL, confirmed
`GET /find-a-talk/data.json → 200`, "2052 talks match right now," the
full real 364-speaker list rendered in the Speaker filter, and a real
`drawBtn.click()` produced a correct ticket (title, speaker, and a role
tag matching the hand-researched data in this doc — D. Todd Christofferson's
Oct 2006 talk correctly showed "Member of the Seventy," pre-dating his
2008 apostle call). **This confirms the entire fetch-at-runtime
architecture works for real, hosted over HTTPS, not just in the Node/
browser-harness tests described above.**

**To publish future data updates** (new conferences, fixes) without a new
app-store build: edit `docs/data.json` in the repo (or wherever it's
regenerated from), commit, push to `main` — GitHub Pages redeploys
automatically. Already-installed users pick it up automatically the
*next* time they relaunch the app (see the background-refresh-then-cache
design above — it deliberately doesn't hot-swap mid-session).

A local HTTP server for more realistic fetch testing (`.claude/launch.json`
+ `.claude/serve.sh`, `python3 -m http.server` on port 8934) was attempted
but hit a `PermissionError`/`getcwd()`-related sandbox issue in the
Browser-pane's `preview_start` process launcher — left in place
unused in case it's transient in a future session, but don't rely on it;
the Node-`vm`-harness and direct `file://` techniques above are the
proven fallbacks (and, as of this session, so is just testing directly
against the real live Pages URL — no local server needed at all).

## ✅ Done: Phase 2 of mobile packaging — Capacitor scaffold, iOS verified live
Scaffolded the actual native app shells with Capacitor, on top of the
Phase 1 `docs/` architecture above. New root-level files: `package.json`
(name `find-a-talk`), `package-lock.json`, `capacitor.config.json`
(`appId: com.captainfun333.findatalk`, `appName: "Find A Talk"`, `webDir:
"docs"` — **this app ID can't change after the first store submission**,
chosen since the user doesn't own a registered domain yet), plus the
generated **`ios/`** and **`android/`** native project folders (committed
to git per Capacitor's own guidance — see the `.gitignore` note in the
Phase 1 section above).

**iOS — fully built, launched, and verified working, end-to-end, in the
Simulator** (not just a static check this time):
- Environment: Xcode 26.6, already fully installed and selected
  (`xcode-select -p` → `/Applications/Xcode.app/Contents/Developer` — the
  user ran `sudo xcode-select -s ...` themselves, since that needs a
  password Claude doesn't have).
- CocoaPods could **not** be installed (`gem install cocoapods
  --user-install` fails — the system Ruby is 2.6.10 from 2022, too old
  for `ffi`'s current native-extension requirements, and there's no
  Homebrew here to get a newer Ruby). **Turned out not to matter** — this
  Capacitor/Xcode version uses **Swift Package Manager**
  (`ios/App/CapApp-SPM/Package.swift`) instead of CocoaPods, so `npx cap
  add ios` and the build both succeeded with zero CocoaPods involvement.
  If a future Capacitor plugin specifically requires CocoaPods, this gap
  will need revisiting then (get Homebrew + a modern Ruby, or a Ruby
  version manager).
- Built via `xcodebuild` (through this environment's iOS Simulator
  tooling) for the iPhone 17 simulator — **`BUILD SUCCEEDED`**, one
  harmless warning (`AppIntentsMetadataProcessor` skip, unrelated to this
  app's code).
- Launched on-device in the Simulator and **visually confirmed working**:
  the real bundled `docs/data.json` loaded inside the WKWebView ("2052
  talks match right now" — same real dataset as the live Pages site,
  bundled into the app instead of fetched, per the offline-capable design
  from Phase 1), the Speaker filter's real 364-name list rendered, and a
  live "Find a Talk" tap produced a fully correct ticket (title, speaker +
  role, kicker summary, conference date, topic chips, and working "Open
  This Talk"/Share/Find Another buttons).
- **Simulator tap-coordinate gotcha, worth remembering for any future
  simulator UI testing in this project**: the simulator control tool's
  `tap`/`swipe` coordinates are in **device points** (e.g. 402×874 for an
  iPhone 17), *not* the pixel dimensions of the screenshot image you see
  — screenshots come back at a 3x pixel scale (1206×2622 for that same
  device; confirmed via `xcrun simctl io booted screenshot` +
  `sips -g pixelWidth -g pixelHeight`). Eyeballing a fraction-of-the-image
  estimate and multiplying by 402/874 is unreliable and can be off by
  100+ points. Also, **multiple taps landing close together in a short
  time can trigger the WKWebView's default double-tap-to-zoom gesture**,
  silently pinch-zooming the page and making every subsequent coordinate
  wrong until the app is relaunched — this is exactly what happened and
  wasted several tap attempts before being caught. **The reliable fix**:
  grab a raw screenshot via `xcrun simctl io booted screenshot`, load it
  with Python/Pillow (`pip3 install --user Pillow` if missing — no
  Homebrew/ImageMagick here), scan for the target element's fill color
  (e.g. the ticket-navy `#1c2c42` button background) using a
  long-contiguous-horizontal-run heuristic (not bare per-pixel color
  matching, which also catches thin anti-aliased text strokes and gives a
  bogus, oversized bounding box) to get an exact pixel bounding box, then
  divide by the pixel/point scale factor (3, for this device) to get the
  real tap coordinates. Single, well-spaced taps only — no rapid repeats.

**Android — scaffolded, SDK now installed, command-line build blocked by
a real ecosystem gap, GUI build recommended instead:**
- The user installed Android Studio and ran its first-launch setup
  wizard themselves (a GUI flow Claude has no tool to drive) — this
  installed the SDK (`~/Library/Android/sdk`: `platform-tools`,
  `platforms/android-37.0`, `build-tools/36.0.0`) and accepted the SDK
  license. `npx cap add android` succeeded and auto-generated
  `android/local.properties` pointing at the right SDK path.
- **`./gradlew assembleDebug` originally failed** with `Unsupported class
  file major version 69` — that's Java 25's class-file version. Android
  Studio's *only* bundled JDK (`/Applications/Android Studio.app/Contents
  /jbr`) is OpenJDK 25.0.2, and at the time this was hit, no released
  Gradle (checked via [gradle/gradle issue
  #35111](https://github.com/gradle/gradle/issues/35111)) fully supported
  JDK 25 yet. **Resolved as of this session**: opening the project in
  Android Studio's own GUI (see below) auto-upgraded `android/build.gradle`
  (AGP 8.13.0 → **9.3.1**) and `android/gradle/wrapper/gradle-wrapper.
  properties` (Gradle 8.14.3 → **9.5.0**), and Gradle 9.5.0 does support
  JDK 25 — command-line `./gradlew` builds should work now too, not just
  Android Studio's GUI. Also picked up `android/settings.gradle` gaining
  the `org.gradle.toolchains.foojay-resolver-convention` plugin and
  several new flags in `android/gradle.properties` — all Android Studio's
  own doing, not manual edits.
- **Path used to get Android fully working: opened `android/` directly in
  Android Studio's GUI** rather than the command line — this is also the
  path needed regardless to run the Android emulator, since Claude has no
  Android-emulator automation tool (unlike the iOS Simulator tool used
  above for iOS). The user then hit "No target device found" on first
  Run — expected, since no emulator existed yet — fixed by creating one
  via Android Studio's own Device Manager (there's no `avdmanager` in
  this machine's SDK install to do this from the command line; only
  `platform-tools`/`platforms`/`build-tools` got installed, not
  `cmdline-tools`). One more real bug hit and fixed along the way:
  `android/app/build.gradle` used `getDefaultProguardFile('proguard-
  android.txt')`, which the newer AGP rejects (needs
  `'proguard-android-optimize.txt'` instead, since the old file implies
  `-dontoptimize` and blocks R8 optimizations) — one-line fix applied.
  **Android is now confirmed building and running** via Android Studio.

**Update, same Phase 2 (Android confirmed working via Android Studio's
GUI, as recommended above):** two more real issues surfaced and got
fixed:
- `android/app/build.gradle` used `getDefaultProguardFile('proguard-
  android.txt')`, which a newer Android Gradle Plugin rejects (it now
  requires `'proguard-android-optimize.txt'` instead — the old file
  implies `-dontoptimize`, which blocks R8 optimizations). One-line fix
  applied directly to that generated file.
- Android Studio's Run button failed with "No target device found" —
  expected the first time, since no emulator existed yet. Fixed by the
  user creating a virtual device via Android Studio's own Device Manager
  (Claude has no `avdmanager`/emulator-creation tool here — the SDK
  install didn't include `cmdline-tools`, only `platform-tools`/
  `platforms`/`build-tools`, so this really did need the GUI).

## ✅ Done: Recently Viewed, Favorites, and a "Show" filter for both
Three related features, all purely local to the device (`localStorage`,
no accounts/sync):
- **Recently Viewed** — a new page listing talks the person actually
  *opened*, most-recent-first. Recording happens **only** on a real open:
  the ticket's "Open This Talk" link, or a title link in "Show a List" /
  Recently Viewed / Favorites itself — deliberately **not** on draw or
  share, per how the feature was scoped.
- **Favorites** — a star toggle (next to Share, everywhere a talk is
  shown: the ticket, every list row, and both new pages) that saves/
  unsaves a talk to its own page. Unfavoriting live-removes the row from
  the Favorites page immediately, no refresh needed.
- **A 5th filter, "Show"** — alongside Speaker/Calling/Conference/Topic,
  with two checkbox values ("Recently Viewed"/"Favorites") that plug into
  the exact same multi-select architecture as the other four (OR'd within
  the dim, AND'd across dims, cascading-availability rules included) —
  checking "Favorites" narrows the pool to just favorited talks, checking
  both shows talks that are either.

**Architecture notes:**
- `talkKey(talk)` (`"year|month|slug"`, same format `TOPIC_LOOKUP`/
  `KICKER_LOOKUP` already used) is the shared identity used to store
  recents/favorites as plain string arrays in `localStorage`
  (`findATalkRecent`, `findATalkFavorites`) and look them back up via a
  new `TALKS_BY_KEY` map built once real data loads.
- Adding a 5th filter dim was the trigger for a small refactor: the
  dim-iteration logic in `poolExcept()`/`currentPool()`/the reset-button
  handler/`refreshCount()`'s disabled-check was hardcoded to the four
  original dim names — replaced with `Object.keys(DIM_CONFIG)` everywhere
  so a future 6th dim (if one's ever added) is a pure `DIM_CONFIG`/HTML
  addition, no hunting for hardcoded dim lists elsewhere.
- The "Recently Viewed"/"Favorites" pages reuse `buildListItemRow(pick)`
  and `createFavoriteButton(pick)` — the exact same row-rendering code
  "Show a List" already used, refactored out into shared functions rather
  than copy-pasted three times.
- New page-nav (top of the page, "Recently Viewed · Favorites") and a
  `homeZone` wrapper `<div>` around everything that used to be the whole
  page (divider through `listZone`) so `showZone('home'|'recent'|
  'favorites')` can just toggle which one section is visible — same
  "only one thing visible at a time" pattern the app already used for
  the ticket vs. the list.

**A real bug found and fixed during live iOS Simulator testing** (not
just a static check this time — see verification below): favoriting/
unfavoriting a talk from a *different* surface than the ticket (e.g. its
own list row on the Favorites page) didn't update the ticket's own
"☆ Favorite"/"★ Favorited" button if that same talk happened to still be
showing on the ticket — each favorite button only synced itself, not
every other instance of the same talk elsewhere on the page. Fixed by
having `createFavoriteButton`'s click handler also call the ticket's
`syncFavoriteBtn()` whenever the toggled talk matches `lastPicked`.

**Verification — fully live, not just static checks this time:** built
and ran in the iOS Simulator (same iPhone 17 sim as Phase 2's iOS
verification), covering: drawing a talk → tapping "Open This Talk" →
confirming it shows up on the Recently Viewed page; favoriting from the
ticket → confirming it appears on the Favorites page with a filled star;
unfavoriting from the Favorites page → confirming it live-disappears from
that page immediately; the "Show" filter panel opening, "Recently
Viewed" being checkable, and the pool count narrowing correctly; and the
ticket-sync bug above, both before (caught the bug) and after (confirmed
the fix) the patch. Android wasn't re-verified live for this feature
(no Android-emulator automation tool available), but `npx cap sync` was
re-run so the same updated `docs/` content is bundled into `android/`
too — the user can confirm via Android Studio's Run button same as before.

**Tap-coordinate technique refined further this session, worth keeping
for future simulator UI testing:** for *outlined* elements (ghost
buttons, filter trigger boxes) rather than solid-fill ones, scanning for
the border color (`var(--line)`, `#c9bfa2`) and grouping matching rows
into "bands" (consecutive border-color rows collapsed into one, filtering
by a **near-full-width run length** — roughly 1000+ px out of a 1206px-
wide screenshot at this device's 3x scale) reliably finds each field
box's real top/bottom edges. A single mis-scan (too-strict tolerance, or
an isolated short border-colored run like a `.reset-link`'s underline)
can produce a wrong box pairing that looks *plausible* — this cost
several missed taps against the new "Show" filter in this session before
switching to the full-width-run-length + row-grouping approach above,
which then worked on the first try.

**Renamed right after this**: the 5th filter's label went from "Show" to
**"Recent/Favorites"** per explicit user request — one-line change
(`<label id="mineLabel">`), no logic touched.

## ✅ Done: Speaker/Calling/Conference/Topic filters on Recently Viewed and Favorites
The user's own framing: once someone has a large collection of saved
talks, they need a way to narrow *that* collection, not just the whole
2052-talk pool. Both pages now get their own copy of the four content
filters (Speaker, Calling, Conference, Topic — **not** the 5th
"Recent/Favorites" dim, which wouldn't make sense on a page that already
*is* exactly that subset).

**Architecture — reused rather than duplicated by hand:**
- `matchesDim(t, dim, values)` and `valuesForDim(pool, dim)` (defined for
  the home page's filters) turned out to already be pure functions of
  whatever pool you pass them — no changes needed, both are reused as-is
  by the new subset filters.
- `subsetPoolExcept(pool, filterState, excludeDim)` / `subsetCurrentPool
  (pool, filterState)` mirror `poolExcept()`/`currentPool()` exactly, just
  parameterized over an arbitrary pool + filterState instead of always
  `TALKS`/the home page's single global `filterState`.
- `createSubsetFilterPanel(prefix, containerEl)` builds one complete,
  independent set of 4 ms-trigger/ms-panel controls **in JS** (not
  hand-written HTML — there'd have been 3 near-identical copies of ~90
  lines of markup otherwise) inside a given container, and returns
  `{filterState, setBasePool(pool), currentPool(), baseCount(),
  hasActiveFilters(), reset(), onChange}`. Called once for Recently
  Viewed, once for Favorites — fully independent instances, independent
  of the home page's own filters and of each other (filtering Speaker on
  one doesn't touch the other).
- Each instance's "all values"/"available values" are recomputed from
  its **own current subset** every time `setBasePool()` runs (i.e. every
  time the page is opened or a talk is added/removed) — so the Speaker
  dropdown on Recently Viewed only ever lists speakers actually among
  your recently-viewed talks, not all 364 in the app. Confirmed live: a
  3-talk Recently Viewed list showed exactly its 3 speakers in the
  dropdown, selecting one narrowed "Showing all 3 talks" to "Showing 1 of
  3 talks" and the list to just that talk.
- `renderSubsetList(...)` is the one shared render function both pages'
  `onChange` callbacks call — handles three states cleanly: nothing saved
  at all (original empty-state message, filters hidden), talks saved but
  none match the active filters (a different "no matches" message,
  filters still visible so it's obvious why), and the normal case
  ("Showing all N talks" / "Showing N of M talks").
- **A bug caught and fixed before this ever ran**: the factory originally
  tried to expose an `onChange` callback via a plain closure variable
  (`let onChangeCb`) that the *caller* would set via `panel.onChange =
  fn` — but the internal `recompute()` still referenced the old
  now-stale `onChangeCb` variable, so the caller's assignment never
  actually reached it (classic "assigning a property on the returned
  object doesn't rebind an internal closure variable" mistake). Fixed by
  making the returned object itself (`api`) the single source of truth —
  `recompute()` calls `api.onChange()`, and the object is mutated (not
  reassigned) by the setter, so both sides see the same reference. Caught
  by re-reading the code rather than by a failed live test this time —
  worth remembering as a pattern to watch for in any future "return an
  object with a settable callback" code.

## ✅ Done: Filter reorder (Calling, Topic, Speaker, Conference, Recent/Favorites)
User-reported friction: the Speaker list had gotten long enough (364
names) that it was pushing Calling out of easy reach, and Calling gets
used more. Reordered both the home page's `.filters` grid (plain HTML
reorder) and the Recently Viewed/Favorites pages' own copies
(`SUBSET_DIM_ORDER = ['role','topic','speaker','year']`, one shared
constant driving both pages via `createSubsetFilterPanel`'s dim-iteration
loop). Purely a display-order change — `DIM_CONFIG`'s object-key order
was left alone since nothing about the AND/cascading logic depends on it.

## ✅ Done: Talk of the Day, keyword search, adjustable list size
Three independent features added together this session:

- **Talk of the Day** — a card at the top of the home page (always
  visible, unaffected by whatever filters are set) showing one
  deterministic pick, seeded by the device's local calendar date so it's
  the same for everyone on a given day and changes at midnight. Reuses
  `buildListItemRow()` (same star/share/open behavior as every other talk
  row). `talkOfTheDay()` sorts a copy of `TALKS` by `talkKey()` first,
  then picks `hashString(dateSeed) % sorted.length` — sorting first means
  today's pick stays reasonably stable even as `data.json` gets new
  conferences appended later, rather than shifting for every talk if the
  raw array order ever changed.
- **Keyword search** (`SEARCH TITLES & SUMMARIES`, above the four
  filters) — free-text, matches substring (case-insensitive) against a
  talk's title OR its kicker sentence. Implemented as `filterState.query`
  (a plain string, not an array like the other dims) with its own
  `matchesSearch(t)` predicate ANDed into `currentPool()`/`poolExcept()`
  alongside the `Object.keys(DIM_CONFIG)` dim loop — deliberately kept
  separate from `DIM_CONFIG` rather than shoehorned in, since it has no
  checkbox panel/"available values" concept. Catches talks a Topic filter
  would miss entirely — e.g. searching "gratitude" surfaces talks whose
  *kicker* mentions it even when the title doesn't and it's not the
  talk's tagged Topic (confirmed live: 18 real matches, including "The
  Divine Gift of Gratitude" by title and "Reverence For Sacred Things" by
  kicker text alone).
- **Adjustable "Show a List" size** — 5/10/25/50 pill buttons under the
  draw buttons (was a hardcoded `LIST_SIZE = 10`, now `let LIST_SIZE`).
  Persists across relaunches via `localStorage` (`findATalkListSize`). If
  a list is already showing when the size changes, it re-rolls
  immediately at the new size rather than waiting for another "Show a
  List" click.

**A real bug found and fixed before shipping — same "temporal dead zone"
family as the earlier `onChange`-callback bug, worth watching for
specifically whenever a new feature's setup code is added near the very
top of `initApp()` rather than the bottom**: the first version called
`renderTalkOfTheDay()` immediately, right where the function was defined
— which is *before* `initApp()` had reached the Share section further
down where `SHARE_ICON_SVG`/`STAR_ICON_SVG` are declared. Since
`buildListItemRow()` → `createFavoriteButton()` reads `STAR_ICON_SVG`,
calling it that early threw an uncaught `ReferenceError`, which silently
halted **all** of `initApp()`'s remaining top-to-bottom execution —
including the `listBtn` click-handler registration. Symptom in the
Simulator: "Show a List" visually responded to taps (hover/focus CSS
still worked, since that's browser-native) but nothing ever rendered,
and the Talk of the Day card stayed empty. Fixed by moving just the
`renderTalkOfTheDay();` *call* (not the function definitions, which are
hoisted and were never the problem) to the very end of `initApp()`, after
everything it transitively depends on. Caught via the same
Simulator-log-stream + bisection process used earlier in this project,
not a static check — **a good argument for always testing a genuinely
fresh app launch after adding any new top-level (not just
inside-a-function) code**, since eager top-level statements are exactly
where this class of bug hides and a static syntax check (`node --check`)
cannot catch it.

**Verification**: all three fully live-tested in the iOS Simulator after
the fix — Talk of the Day rendering real content with working
star/share/open-and-record-recent; typed "gratitude" into the search box
and confirmed the pool count narrowed 2052 → 18, "Reset filters"
correctly became enabled, and "Show a List" honored the narrowed pool
("Showing all 18 talks"); list-size buttons switching and the choice
surviving an app relaunch. One tooling note for future sessions: locating
a plain `<input>` box's tap coordinates by scanning for its border color
needs care about which border is being measured — a `box-shadow`-casting
card sitting directly above an input can produce a color band in the gap
between them that looks like a plausible box edge but is actually just
shadow bleed; cropping the actual screenshot region and reading it
visually (not just color-scanning) resolved several minutes of
mis-tapping in this session and is the more reliable technique going
forward for any element that isn't a solid-fill button.

## ✅ Done: header/layout refinements, Normal/Condensed list view
Follow-up polish requested right after the Talk of the Day/search/list-
size session:

- **List size → List view (Normal/Condensed)**: replaced the 5/10/25/50
  count picker with just two buttons. `LIST_SIZE` is a plain `const = 10`
  again (the original, pre-adjustable-size count); what's adjustable now
  is row density, not count. "Condensed" drops the conference-date and
  kicker lines from `buildListItemRow()` (new optional `condensed` param)
  and tightens padding — roughly half a Normal row's height, confirmed
  visually (6 condensed rows fit the same viewport as ~3.5 normal ones).
  Toggling the mode **re-renders the same already-drawn picks**
  (`lastListPicks`, `renderListItems()`) rather than re-shuffling — a
  pure style toggle shouldn't change which talks are showing. Persisted
  via `localStorage` (`findATalkListMode`).
- **Header simplified**: `<h1>` is now plain "Find a Talk" (was "Find
  random *inspiration*"); the intro paragraph's first sentence
  ("Randomize a talk from General Conference.") was removed entirely,
  and its second sentence ("You may narrow the search by using the
  filters below.") moved down to sit directly above the keyword-search
  field as its own `.search-intro` paragraph, rather than living under
  the H1 alongside filter-agnostic branding copy.
- **Talk of the Day ⇄ page-nav swap**: Talk of the Day moved from inside
  `homeZone` to right after the H1 (a new `.divider` was added there too,
  matching the one that already existed between the old positions) — it
  and the H1 now form a fixed top section, outside `homeZone`, so **Talk
  of the Day stays visible even on the Recently Viewed/Favorites pages**
  (confirmed live). The "Recently Viewed · Favorites" `.page-nav` moved
  the opposite direction, into `homeZone` right after the divider — it's
  now hidden on those two pages (each already has its own "← Back"
  button, so this doesn't remove any navigation capability, just means
  jumping directly between Recently Viewed and Favorites now goes via
  Home first rather than a persistent top-level link).

**Verification**: fully live in the Simulator — confirmed the swap (Talk
of the Day visible from the Recently Viewed page, page-nav gone from
it), the new divider's placement, and the Normal/Condensed toggle (same
10 talks preserved across a toggle, condensed rows visibly ~half height,
selection persisting across a fresh app relaunch). One relaunch during
this session produced a stale, previously-selected filter state
immediately after `xcrun simctl terminate` — the terminate call likely
returned before the process had actually finished exiting; adding a
short pause (or confirming via `xcrun simctl list`) before the next
`launch` avoided it on retry. Worth remembering for future sessions: a
screenshot taken immediately after `terminate`+`launch` isn't guaranteed
to be from a truly fresh process.

## ✅ Done: Talk of the Day scoped back to home-only; self-defined "My Lists" collections
Two follow-ups requested right after the header/layout refinements above.

**Talk of the Day, home-only again**: the previous session's swap had
moved `totd-zone` *outside* `homeZone` so it stayed visible on Recently
Viewed/Favorites too — turned out that wasn't wanted. Fix was a pure
structural move, no visibility-toggling code needed: `<div
id="homeZone">`'s opening tag now wraps `totd-zone` again (right after
the divider that follows the H1), so it's back to hiding automatically
whenever `showZone()` switches away from `'home'`. Visual position on
the home page itself is unchanged.

**Self-defined collections ("My Lists")** — the bigger ask: generalizing
the single hardcoded Favorites bucket into as many named lists as
someone wants ("Sunday lesson ideas," "For my talk in June," etc.),
kept as a fully separate feature from Favorites rather than merged into
it (Favorites still works exactly as before — one star, one page).

**Data layer** (`COLLECTIONS_KEY`/`COLLECTION_MEMBERS_KEY` in
`localStorage`, same load-once/save-after-every-mutation pattern as
recents/favorites): `collections` is `[{id, name}]` in creation order;
`collectionMembers` is `{id: [talkKey, ...]}`. IDs are
`'col_' + timestamp + random suffix`, not sequential — fine since
nothing ever needs to sort or diff them.

**UI, three new pieces:**
- A "+" icon button next to the star/share on every talk row (ticket,
  list rows, Talk of the Day, Recently Viewed/Favorites/My Lists rows —
  it's part of the shared `buildListItemRow()`/ticket-actions, so it
  appears everywhere those already do) opens an **"Add to a List"
  modal** — checkboxes for every existing collection plus an inline
  "New list name…" + Create field. Unlike the favorite star, this button
  has no on/off visual state (a talk can be in 0, 1, or many lists at
  once), so it's a plain action button, not a toggle.
- **"My Lists"** added as a third nav link (`Recently Viewed · Favorites
  · My Lists`) — an index page listing every collection with its talk
  count, a row click to open it, an × to delete (behind a native
  `confirm()`, "This can't be undone"), and its own "New list name…" +
  Create row for creating without going through a specific talk first.
- **Single collection view** reuses the exact same `createSubsetFilterPanel`
  /`renderSubsetList` machinery Recently Viewed and Favorites already
  established — one filter-panel instance (`collectionFilterPanel`,
  dims Calling/Topic/Speaker/Conference) whose base pool gets swapped via
  `setBasePool()` each time a different collection is opened, rather than
  building a new instance per collection. `currentCollectionId` tracks
  which one is open so a membership change made via the modal while that
  same collection's page happens to be open refreshes it live, same
  pattern as Favorites' own live-sync.

**A real, user-facing bug found and fixed during this session's live
testing, not specific to this feature but newly visible because of it**:
every text `<input>` in the file (search box, filter search boxes, the
two new "list name" inputs) had `font-size` under 16px. iOS/WKWebView
auto-zooms the whole page when a text input smaller than 16px is
focused, and — at least in this Capacitor WebView — doesn't reliably
zoom back out on blur, leaving the page stuck zoomed in with content
cut off at the right edge (several minutes of subsequent mis-taps in
this session traced back to exactly this, not coordinate-math error).
Fixed by bumping every text-input `font-size` to 16px; noted inline
in the CSS so it doesn't quietly regress if someone "cleans up" the
sizing later.

**Verification**: fully live in the Simulator — created two collections
("Test" via the modal from the Talk of the Day card, "Sunday lesson
ideas" also via the modal, auto-checked on creation as designed),
confirmed both appear correctly on the My Lists index with accurate
counts, opened one and confirmed its own filter panel correctly scoped
to just that collection's talk (Speaker dropdown showed only that one
talk's speaker), and deleted a collection via the confirm() dialog and
confirmed it disappeared from the index. Also confirmed Talk of the Day
no longer appears on the Recently Viewed or My Lists pages.

## ✅ Done: backward coverage to April 1996 (gap closed; Oct 1995 no longer standalone)
Added Apr 1996, Oct 1996, Apr 1997, Oct 1997, Apr 1998, Oct 1998, Apr 1999
(250 talks — one entry, "Faith in Every Footstep: The Epic Pioneer
Journey" [Video Presentation] from Apr 1997, was deliberately excluded:
no byline/speaker of record, unlike the kept ceremonial addresses which
always have a real speaker). **The continuous run now goes October 1995 →
April 2026 (61 conferences back to back)**, plus the two remaining older
standalones, April 1987 and October 1974. **64 conferences, 2302 talks
total.**
- **Kickers**: confirmed the Church's site didn't add these until
  somewhere between April 1996 and April 1997 — Apr 1996 and Oct 1996
  have **zero** kickers (matches the pre-1999 standalone conferences'
  behavior), Apr 1997 has partial coverage (33/37 — the missing 4 are a
  video presentation plus 3 real talks that apparently never got one),
  and Oct 1997 onward has full coverage. Don't bother re-checking Apr/Oct
  1996 if backward coverage ever continues past this point — there's
  nothing there to get, same as the three pre-1999 standalones.
- **Topics**: this batch is what confirmed the topic-page fetching
  pattern still works this far back — all 335 official topic pages were
  refetched (not reused from the cached `TOPIC_LABELS` built in an
  earlier session) and every one of the 250 kept talks matched at least
  one topic. 4 previously-zero-match topic slugs picked up a first real
  match from this batch and were added to `topicLabels`.
- **Roles researched, all confirmed via web search, not assumed:**
  - First Presidency: Hinckley/Monson/Faust, stable and already
    researched (no change) — confirmed no new research needed for this
    window.
  - **Relief Society**: Elaine L. Jack (president) with **Chieko N.
    Okazaki** (1st) and **Aileen H. Clyde** (2nd) — serving since March 31
    1990 — covers Apr 1996, Oct 1996, Apr 1997 (Jack's last talk in the
    dataset, "A Small Stone," is that same April 1997 conference). Mary
    Ellen W. Smoot's presidency (Jensen/Dew, already known from a later
    session) was called that same April 1997 conference per a
    contemporary Deseret News article, but their first talks in the
    dataset don't appear until **Oct 1997** — a clean conference-boundary
    handoff with no same-conference overlap needed (unlike some other
    transitions in this project), since Jack/Okazaki/Clyde simply have no
    talks after Apr 1997 and Smoot/Jensen/Dew have none before Oct 1997.
  - **Young Women**: Janette Hales Beckham (president, Apr 1992–Oct 1997)
    with **Virginia H. Pearce** (1st counselor throughout) and **Bonnie D.
    Parkin** (2nd counselor, 1994–1997) — covers Apr 1996, Oct 1996, Apr
    1997. Hales Beckham gives a same-conference farewell talk at **Oct
    1997** (the exact conference the new Nadauld/Larsen/Thomas presidency
    was sustained, Oct 4 1997) even though the new presidency's own first
    talks in the dataset don't start until **Apr 1998** — a real
    same-conference-transition case, same pattern as several others
    already documented in this file, just with the incoming side's first
    talk landing a full conference later than the outgoing side's last
    one.
  - **Primary**: confirmed via search — Patricia P. Pinegar (president)
    served with **Anne G. Wirthlin** (1st counselor) and **Susan L.
    Warner** (2nd counselor), all three sustained Oct 1 1994 and released
    together in 1999. All three tagged `primary` wherever they speak in
    this batch (Pinegar Apr 1997; Wirthlin Apr 1998; Warner Apr 1996 and
    Oct 1998).
  - **Presiding Bishopric**: confirmed via search — Merrill J. Bateman
    left to become BYU president Jan 1 1996 (before this batch's first
    conference); **H. David Burton** was called the 13th Presiding
    Bishop Dec 27 1995, with **Richard C. Edgley** (1st) and **Keith B.
    McMullin** (2nd) — all three stable and already tagged
    `presiding-bishopric` in the existing Oct 1995 data, so no
    conference-boundary edge case in this window; they simply continue
    across all 7 new conferences.
  - **Seventy default rule reapplied** (same explicit speed-over-
    exhaustive-verification methodology as the original Seventy backfill
    documented above): every otherwise-untagged speaker across this batch
    got `seventy`, **except** 7 names deliberately left untagged:
    **Anne Marie Rose, Kirstin Boyer, Anne Prescott** (Apr 1996) and
    **Kristin Banner, Fono Lavatai, Alejandra Hernández** (Apr 1997) —
    all personal-testimony talks bundled into an identifiable
    non-officeholder youth segment (the Apr 1997 trio sits right after
    the "Faith in Every Footstep" pioneer-sesquicentennial video, matching
    that year's 150th-anniversary Pioneer Trek theme; the Apr 1996 trio
    reads the same way) — tagging any of these `seventy` would have been
    a real, identifiable error, not just an unverified guess, so this is
    a targeted exception to the default rule, not a case-by-case
    re-verification of the whole batch. Also excluded: **Richard E.
    Turley Sr.**, a known Assistant Church Historian (a professional
    employee, not a sustained General Authority) — left untagged rather
    than defaulted to `seventy`, matching the "one-off speaker never
    sustained a General Authority" carve-out already documented in the
    `other`-role section above (though `other` itself wasn't used here
    since Church Historian isn't one of the nine tracked categories
    either, and the existing precedent treats an unverified one-off
    employee the same as "not researched," not as `other`).
- **Fetching-pattern confirmation**: the same `curl` + regex technique
  used for every prior batch still works unchanged this far back — the
  session-listing page's `item-U_5Ca` markup, individual talk pages'
  `class="kicker"` paragraph, and topic-index pages' talk-link hrefs are
  all structurally identical for 1996–1999 as for every later conference
  already in this dataset. One small wrinkle worth remembering: on these
  older pages the topic-index talk-link hrefs have **no trailing
  `?lang=eng` query string** (`href="/study/general-conference/1996/04/
  slug"` vs. the newer `...slug?lang=eng"` used elsewhere) — a regex that
  assumes the `?` suffix will silently match zero topic links on this
  older content. Fixed by matching the closing `"` directly instead of
  requiring a literal `?` before it.
- **Validation**: full integrity pass run after merging — zero duplicate
  talk rows, zero orphaned `roleLookup`/`topicLookup`/`kickerLookup`
  entries (no orphan key without a matching talk), zero talks missing a
  `topicLookup` entry, and the "sandwiched gap" check (any untagged talk
  whose speaker has the same role both before and after it
  chronologically) came back clean — zero hits across the whole 2302-talk
  dataset, not just the new batch.
- **Footer copy and the `TALKS` block's leading code comment** in
  `docs/index.html` were updated to say "sixty-four conferences... every
  conference from October 1995 through April 2026, plus Apr 1987 and Oct
  1974" (was "fifty-seven conferences... October 1999... plus Oct 1995,
  Apr 1987, and Oct 1974") — **`conference-draw.html` was deliberately
  left unchanged**, per its standing "legacy/reference copy, don't touch
  unless doing a one-off legacy-file fix" status.
- **Verified live**: `npx cap sync` re-run (updates both `ios/App/App/
  public/data.json` and `android/app/src/main/assets/public/data.json`
  from the new `docs/data.json`); the local `python3 -m http.server 8934`
  workaround from the Phase 1 section above worked this session
  (previously flagged as blocked by a sandbox `getcwd()` error — that
  appears to have been transient, matching the "left in place unused in
  case it's transient" note) — confirmed live in the Browser pane:
  "2302 talks match right now," a fresh `localStorage.clear()` +
  reload correctly re-fetched the new `data.json` (the first load had
  been served the old cached 2052-talk copy, exactly per the
  deliberately-non-hot-swapping bootstrap design documented in Phase 1 —
  not a bug), and a direct console check confirmed an April 1999 talk
  ("The Work Moves Forward," Gordon B. Hinckley) resolves the correct
  `role` (`president`) and a real `TOPIC_LOOKUP` array via the live
  in-page `TALKS`/`ROLE_LOOKUP`/`TOPIC_LOOKUP` globals.

## ✅ Done: backward coverage to April 1994 (three real Presidency-level transitions researched)
Added Apr 1994, Oct 1994, Apr 1995 (114 talks). **The continuous run now
goes April 1994 → April 2026 (67 conferences back to back)**, plus the
remaining older standalone, October 1974, and April 1987 is no longer
standalone either (now bridged in). **2416 talks total.**
- **Kickers**: confirmed zero for all three conferences (114/114 talks
  checked, none had a `class="kicker"` paragraph) — consistent with the
  established pattern that kickers didn't start until sometime between
  April 1996 and April 1997. Don't re-check Apr 1994/Oct 1994/Apr 1995 if
  coverage is ever extended further back.
- **Topics**: all 335 official topic pages (already cached on disk from
  the previous batch this session) matched 112 of 114 talks; the 2
  without a topic are both "The Solemn Assembly (Sustaining of Church
  Officers)" — a real, distinctly-titled proceeding (not the generic
  excluded admin title), kept as a real talk per existing precedent
  (matches the already-documented Solemn Assembly 2018 case), just with
  no official topic tag, same as the 4 pre-existing Oct 2010 zero-topic
  talks.
- **Three real First-Presidency-level transitions researched and
  confirmed via web search, none assumed from memory:**
  1. **Howard W. Hunter presided between Benson and Hinckley** — a
     president this project hadn't encountered before. Ezra Taft Benson
     (president, Nov 11 1985 – d. May 30 1994) kept **Gordon B. Hinckley**
     (1st counselor) and **Thomas S. Monson** (2nd counselor) the whole
     time. Hunter (14th president, set apart June 5 1994) **kept the same
     two counselors** rather than calling new ones — confirmed via a
     contemporary 1994 First-Presidency photo caption. Hunter died March 3
     1995 after only nine months, the shortest presidency in Church
     history, presiding over exactly one conference (Oct 1994). Hinckley
     (15th president) was set apart March 12 1995 with **Monson (1st)**
     and **James E. Faust (2nd, newly added to the First Presidency —
     he'd been a plain apostle since 1978)** — already the pattern this
     project had documented for Oct 1995 onward, now confirmed to start
     cleanly at Apr 1995 with no mid-conference edge case (the calling
     came 3 weeks before the conference).
     - Role tags: **Benson = `president`** (Apr 1994 only, his last
       conference), **Hunter = `president`** (Oct 1994 only — also gets
       the tag on his "Solemn Assembly" talk that same conference, since
       he was sustained before any talks that conference), **Hinckley =
       `first-presidency`** for Apr 1994 and Oct 1994 (still just a
       counselor), **`president`** from Apr 1995 on. **Faust = `apostle`**
       for Apr 1994/Oct 1994 (not yet in the FP), **`first-presidency`**
       from Apr 1995 on.
  2. **Robert D. Hales moved from Presiding Bishop to the Quorum of the
     Twelve, same-day, at Apr 1994** — sustained to the Twelve April 2
     1994 (the Saturday of that conference), ordained April 7; **Merrill
     J. Bateman** (previously a Seventy) was sustained Presiding Bishop
     that same Saturday afternoon to fill the vacancy, with **H. David
     Burton** (1st) and **Richard C. Edgley** (2nd) continuing as his
     counselors (they'd already been counselors under Hales). Same-day-
     sustaining pattern already established elsewhere in this project:
     Hales's Apr 1994 talk is tagged `apostle` (the new role), not
     `presiding-bishopric`, since the sustaining came before any talks
     that conference. Bateman/Burton/Edgley = `presiding-bishopric`
     through Apr 1995 (Bateman leaves for BYU president Jan 1 1996,
     already documented in an earlier session).
  3. **The Primary General Presidency (Grassli → Pinegar) and a linked
     Young Women vacancy, both landing at Oct 1994**: **Michaelene P.
     Grassli** (president, Apr 1988 – Oct 1 1994) with **Betty Jo N.
     Jepsen** and **Ruth B. Wright** as counselors was released Oct 1
     1994, replaced same-day by **Patricia P. Pinegar** (president) with
     **Anne G. Wirthlin** (1st) and **Susan L. Warner** (2nd) — the same
     trio already documented as serving through 1999 in an earlier
     session, now confirmed to have started at this exact date. Grassli's
     Oct 1994 talk is her same-conference farewell (`primary`); Wright's
     Apr 1994 talk is also `primary` (before the transition); Jepsen has
     no talk in this batch. **Pinegar herself was Young Women's 2nd
     counselor immediately before this** (serving 1992–1994 under
     Janette Hales Beckham, alongside 1st counselor Virginia H. Pearce) —
     her Apr 1994 talk is tagged `young-women` (before her promotion),
     flipping to `primary` starting Oct 1994. Her Young Women vacancy was
     filled by **Bonnie D. Parkin** (2nd counselor, 1994–1997, already
     documented from a later session) — Parkin's first talk in the
     dataset doesn't appear until Apr 1995, skipping Oct 1994 entirely,
     which is fine (not every presidency member speaks every conference).
- **Seventy default rule applied** to the remaining 29 otherwise-untagged
  speakers (Carlos E. Asay, Hartman Rector Jr., L. Aldin Porter, Dieter F.
  Uchtdorf — called to the Second Quorum of the Seventy that same April
  1994 conference, confirmed via search — and 25 others with typical
  1990s-era Seventy naming patterns), **except 5 names left deliberately
  untagged**: Melanie Eaton, Andrea Allen, Hilarie Cole, Karen Maxwell
  (Apr 1995 — a female-testimony block immediately following Janette
  Hales Beckham's Young Women address, same identifiable
  non-officeholder pattern as the Apr 1996/1997 youth-testimony
  exclusions documented above) and Andrew W. Peterson ("Easter
  Reflections," Apr 1995 — sits between two General Authority talks but
  reads as a short devotional/musical program insert rather than a
  standard sermon; left untagged rather than guessed).
- **Validation clean** across the whole now-2416-talk dataset: zero
  duplicate talk rows, zero orphaned role/topic/kicker entries, zero
  talks missing a topic entry beyond the 2 expected Solemn Assembly
  proceedings, zero sandwiched role gaps.
- Footer copy and the `TALKS` block's code comment in `docs/index.html`
  updated again: "sixty-seven conferences... every conference from April
  1994 through April 2026, plus Apr 1987 and Oct 1974."
- **Verified live** the same way as the prior batch: `npx cap sync`
  re-run, a fresh local `python3 -m http.server` + Browser-pane check
  confirmed `TALKS.length` = 2416 and spot-checked `ROLE_LOOKUP` resolved
  exactly as researched for all three transition cases above (Hales →
  `apostle`, Bateman → `presiding-bishopric`, Pinegar Apr 1994 →
  `young-women` vs. Oct 1994 → `primary`, Grassli Oct 1994 → `primary`,
  Eyring Apr 1995 → `apostle`).

## ✅ Done: backward coverage to April 1992 (Kapp→Hales YW transition; Presiding Bishopric counselor history filled in)
Added Apr 1992, Oct 1992, Apr 1993, Oct 1993 (145 talks). **The
continuous run now goes April 1992 → April 2026 (69 conferences back to
back)**, plus the October 1974 standalone (Apr 1987 is now bridged in
too). **71 conferences, 2561 talks total.**
- **Kickers**: expected zero for this era, but 2 talks had a real
  `class="kicker"` paragraph anyway — **not** a one-sentence teaser like
  every other kicker in this dataset, but a short editorial/context note
  ("This address was given at the 1993 Parliament of the World's
  Religions..."; "Part of this address was filmed in Nauvoo, Illinois...
  Relief Society Sesquicentennial Satellite Broadcast"). Kept verbatim
  anyway, same as every other kicker — it's genuinely what's in that
  page's kicker element, just not the "summary sentence" style most
  kickers use. Worth knowing about if a future pass ever tries to
  validate "kicker text should read like a summary" — these two are
  legitimate exceptions, not scraping bugs.
- **Topics**: 144/145 matched; the one exception (Russell M. Nelson,
  "Combatting Spiritual Drift—Our Global Pandemic," Oct 1993 — the same
  talk with the Parliament-of-Religions kicker) has no official topic tag,
  plausible given its unusual origin as a repurposed interfaith address.
- **Presiding Bishopric counselor history filled in** (this project had
  only known Robert D. Hales was Presiding Bishop April 1985 – April 1994
  and that Burton/Edgley took over as his counselors Oct 3 1992; the
  counselors *before* that were unresearched until now): **Henry B.
  Eyring** was 1st counselor April 1, 1985 – October 3, 1992 (no talk of
  his falls in this batch, but tag `presiding-bishopric` if one from that
  window ever surfaces in an earlier batch), **Glenn L. Pace** was 2nd
  counselor the same span, released the same Oct 3 1992 day Eyring was —
  his one talk in this batch, at that same Oct 1992 conference, is his
  same-conference farewell (`presiding-bishopric`). **H. David Burton**
  (1st) and **Richard C. Edgley** (2nd) were sustained that same Oct 3
  1992 day (already documented in an earlier session as continuing under
  Bateman from Apr 1994 — now confirmed their tenure actually starts here,
  Oct 1992, under Hales). Robert D. Hales himself only has one talk in
  this batch (Apr 1992) — tagged `presiding-bishopric` (he doesn't become
  an apostle until Apr 1994, already documented).
- **Young Women: Ardeth G. Kapp → Janette Hales (Beckham) is a real
  same-conference-transition case**, confirmed via the 10th-president
  fact already on file ("April 4, 1992") plus this batch's own scraped
  data: Kapp's farewell talk ("A Mighty Force for Righteousness") and
  Hales Beckham's first-ever talk in the dataset ("You Are Not Alone")
  both fall at **Apr 1992** — unlike some other transitions in this
  project (which skip a conference between outgoing and incoming), this
  one has both sides tagged `young-women` at the identical conference,
  the same pattern as the RS Beck 2012 case. Virginia H. Pearce (1st
  counselor from this same date, already known) has no talk in this
  batch. Note: the real page byline already reads "Janette Hales
  Beckham" even for this 1992 talk — she didn't actually marry and take
  that surname until 1995, but the Church's site apparently updated the
  byline retroactively (same behavior already confirmed for her 1996–97
  talks in an earlier session) — use the byline exactly as scraped, don't
  "correct" it to "Janette C. Hales."
- **Apostle-roster correction, worth flagging for any future session
  reusing a "stable apostles" set from a prior batch**: **Jeffrey R.
  Holland was NOT yet an apostle** for any conference in this batch (he
  has one talk, Oct 1993 — tagged `seventy`, correct, since he wasn't
  sustained to the Twelve until June 23, 1994, a mid-year special
  sustaining with no conference attached). **Henry B. Eyring** also
  wasn't an apostle yet this era (still Presiding Bishopric 1st counselor
  through Oct 1992, then off the Presiding Bishopric with no other public
  calling change until his April 1995 apostle call, already documented —
  he has no talk in this batch at all). **Marvin J. Ashton** (apostle,
  d. Feb 25 1994) is added to the "stable apostles" set for this era —
  present at Apr 1992/Oct 1992 only, absent from Apr/Oct 1993 (consistent
  with declining health before his death).
- **Validation clean**: zero duplicate talk rows, zero orphaned role/
  topic/kicker entries, zero sandwiched role gaps, across the full
  2561-talk dataset.
- Footer copy and code comment in `docs/index.html` updated again:
  "seventy-one conferences... every conference from April 1992 through
  April 2026, plus Apr 1987 and Oct 1974."
- **Verified live**: same `npx cap sync` + local-server + Browser-pane
  spot-check pattern as the last two batches — `TALKS.length` = 2561,
  and `ROLE_LOOKUP` confirmed for Holland (`seventy`), Kapp/Hales Beckham
  same-conference transition (`young-women`/`young-women`), and
  Pace/Burton (`presiding-bishopric`/`presiding-bishopric`).

## ✅ Done: backward coverage to April 1990 (Winder→Jack RS transition confirmed same-conference)
Added Apr 1990, Oct 1990, Apr 1991, Oct 1991 (143 talks). **The
continuous run now goes April 1990 → April 2026 (73 conferences back to
back)**, plus the October 1974 standalone. **75 conferences, 2704 talks
total.**
- **Kickers**: zero, as expected for this era (all 143 talks checked).
- **Topics**: all 143 matched at least one official topic.
- **Relief Society: Barbara W. Winder → Elaine L. Jack confirmed as a
  real same-conference transition, at Apr 1990** — Winder (11th
  president, April 7 1984 – March 31 1990, counselors Joy F. Evans and
  Joanne B. Doxey, neither of whom have a talk in this batch) gives her
  farewell talk ("Instruments to Accomplish His Purposes") at the same
  Apr 1990 conference where Jack gives her first ("I Will Go and Do") —
  both tagged `relief-society`, same pattern as the Apr 1992 Kapp→Hales
  Young Women case documented in the previous session. This closes out
  the loose end left in the prior "Next task" note.
- Young Women (Kapp, `young-women`) and Primary (Jepsen/Wright,
  `primary`) continue unchanged through this whole batch — no transition
  in this window, matching what was already known (Kapp's presidency
  runs through Apr 1992; Grassli's Primary presidency, already
  documented, runs from Apr 1988).
- **Presiding Bishopric**: Robert D. Hales (Apr 1990), Glenn L. Pace (Oct
  1990), Henry B. Eyring (Apr 1991) all confirmed still active in their
  already-documented 1985–1992/1994 roles — no new research needed, this
  batch just fills in talk-level tags using facts already on file from
  the previous session.
- **One genuine pre-existing gap found and fixed, unrelated to this
  batch**: the "sandwiched gap" check flagged **Lynn A. Mickelsen's
  October 1995 talk** ("Eternal Laws of Happiness") as untagged despite
  `seventy` on both the conference before (Oct 1990, now added by this
  batch) and after (2003) — a real missed tag from an earlier session,
  now fixed to `seventy`. Worth re-running this check after every batch,
  same as the project has done since the original Seventy backfill.
- Footer copy and code comment in `docs/index.html` updated: "seventy-
  five conferences... every conference from April 1990 through April
  2026, plus Apr 1987 and Oct 1974."
- **Verified live**: same pattern as prior batches — `TALKS.length` =
  2704, `ROLE_LOOKUP` confirmed for Winder/Jack (`relief-society`/
  `relief-society`), Kapp (`young-women`), Eyring (`presiding-
  bishopric`), and the fixed Mickelsen entry (`seventy`).

## ✅ Done: backward coverage to October 1987 (gap fully closed — Apr 1987 no longer standalone)
Added Apr 1988, Oct 1988, Apr 1989, Oct 1989 (124 talks), then caught and
filled a one-conference hole this same session: **Oct 1987**, which had
been sitting unfilled between the old Apr 1987 standalone and the new Apr
1988 start (32 more talks). **The continuous run is now fully unbroken
from October 1987 through April 2026 (79 conferences back to back)**,
plus the October 1974 standalone. **80 conferences, 2860 talks total.**
Worth remembering for any future backward-expansion session: **always
check for a straddling single-conference hole** right where new work
connects to a previously-standalone conference — it's easy to fetch the
"next 4 back" and not notice the older standalone doesn't actually touch
them.
- **Kickers**: 2 more of the same non-summary "read by" parenthetical
  style seen in an earlier batch turned up — `(Read by President Thomas
  S. Monson, Second Counselor in the First Presidency)` and `(Read by
  President Gordon B. Hinckley, First Counselor in the First
  Presidency)`, both on Ezra Taft Benson talks (his declining health
  meant several of his messages were read by a counselor rather than
  delivered in person — the byline still credits Benson as the speaker
  of record, and that's what's tagged). Kept verbatim, same treatment as
  the Parliament-of-Religions/Nauvoo-broadcast notes from the previous
  session.
- **Topics**: all 124 + 32 = 156 talks in this round matched at least one
  official topic — no zero-topic exceptions this time.
- **Primary: Dwan J. Young → Michaelene P. Grassli confirmed**, but as a
  *gap-style* transition, not same-conference — Young (7th president,
  1980–1988, counselors **Virginia B. Cannon** [1st] and **Michaelene P.
  Grassli** [2nd, chosen to succeed her]) gives her farewell talk at
  **Apr 1988**; Grassli's first talk as president doesn't appear until
  **Oct 1988** (she has two that conference). Same pattern as the
  Nadauld/Hales-Beckham Young Women transition documented earlier in this
  file — outgoing and incoming don't necessarily share a conference.
  Cannon has no talk in this batch.
- **A genuinely unresolvable-for-now case, left untagged on purpose**:
  **Elaine L. Jack has a talk at Oct 1989** ("Identity of a Young
  Woman"), a full five months *before* her Relief Society presidency
  begins (March 31, 1990, already documented). She wasn't yet holding any
  of the nine tracked callings at that point — likely a Relief Society
  General Board member, a level this app doesn't track — so this one
  talk is deliberately left untagged even though her later talks (Apr
  1990 onward) are `relief-society`. This is *not* a "sandwiched gap":
  the conference immediately before it has no Jack talk at all, so the
  automated check won't (and shouldn't) flag it — noting it here so a
  future session doesn't "fix" it by mistake.
- **Confirmed Jeffrey R. Holland's earliest talk in the dataset (Oct
  1989) predates his June 1994 apostle call by nearly five years** — he
  was a General Authority Seventy from 1989, so `seventy` is correct
  here, consistent with the correction already documented for his Oct
  1993 talk.
- **Validation clean** across the whole 2860-talk dataset: zero duplicate
  talk rows, zero orphaned role/topic/kicker entries, zero sandwiched
  role gaps, and (new check added this session) **zero missing
  conferences** in the expected Oct 1987 → Apr 2026 continuous run —
  confirmed programmatically, not just by eyeballing a printed list.
- Footer copy and code comment in `docs/index.html` updated: "eighty
  conferences... every conference from October 1987 through April 2026"
  (Apr 1987 dropped from the "older standalones" list since it's no
  longer standalone — only Oct 1974 remains as one).
- **Verified live**: same pattern as every prior batch — `TALKS.length` =
  2860, `ROLE_LOOKUP` confirmed for the Young/Grassli Primary transition,
  Doxey (`relief-society`), Holland (`seventy`), and Jack's Oct 1989 key
  resolving to `undefined` (confirming the deliberate non-tag).

## ✅ Done: backward coverage to October 1984 (Kimball-era First Presidency researched; a double Presiding Bishopric transition)
Added Oct 1984, Apr 1985, Oct 1985, Apr 1986, then caught and filled
**another** one-conference hole this same session: **Oct 1986** (sitting
between Apr 1986 and the already-in-dataset Apr 1987), matching last
session's Oct 1987 catch. 127 + 32 = 159 talks total. **The continuous
run is now October 1984 → April 2026 (85 conferences back to back), plus
the October 1974 standalone** — 2 have been caught this way in a row now;
**always run the missing-conference check immediately after merging,
before considering a batch done**, not just at the very end of a session.
- **Kickers**: 4 more non-summary "context note" kickers this batch, same
  family as previous sessions' finds — two more "(Read by President
  ___, ___ Counselor in the First Presidency)" notes on Kimball/Benson
  talks (his declining-then-fatal health continuing the pattern from the
  1988–1989 batch), one for a priesthood-session talk "delivered in part"
  by Benson with the "complete text... printed here at his request," and
  one describing a videotape compilation of Kimball's past priesthood-
  session talks. All kept verbatim.
- **Topics**: 158/159 matched; the one exception ("Your Patriarchal
  Blessing: A Liahona of Light," Thomas S. Monson, Oct 1986) has no
  official topic tag — plausible, no red flag.
- **Fresh First Presidency research for the Kimball era, confirmed via
  web search**: Spencer W. Kimball's counselors were **N. Eldon Tanner**
  and **Marion G. Romney** from 1973 until Tanner's death in 1982; when
  Kimball/Tanner/Romney's health all declined, **Gordon B. Hinckley was
  added as a third counselor July 23, 1981**; after Tanner died, Romney
  became 1st counselor and Hinckley 2nd. **Kimball died Nov 5 1985** —
  Benson became president Nov 10/11 1985 (already documented). This
  means **Thomas S. Monson was still a plain apostle for Oct 1984/Apr
  1985/Oct 1985** — he wasn't added to the First Presidency until Benson
  called him Nov 1985 — a real correction from every prior batch's
  default of tagging him `first-presidency`, worth remembering if any
  earlier-era script or memory gets reused: **Monson = `apostle` for any
  talk before Nov 1985, `first-presidency` from Apr 1986 on.** Marion G.
  Romney has no talk in this batch (declining health).
- **A real double Presiding Bishopric transition at Apr 1985, same-day,
  confirmed via search**: **Victor L. Brown** (10th Presiding Bishop,
  1972–1985, with **H. Burke Peterson** as 1st counselor from 1972) was
  released April 6 1985 and succeeded by **Robert D. Hales**, who called
  **Henry B. Eyring** (1st) and **Glenn L. Pace** (2nd) as his own new
  counselors — all documented in an earlier session as continuing from
  this exact date. All five have talks at that same Apr 1985 conference
  (Brown's and Peterson's farewells; Hales's, Eyring's, and Pace's firsts
  — Hales's talk is literally titled "The Mantle of a Bishop") — all
  five tagged `presiding-bishopric`, the same-conference-transition
  pattern used throughout this project.
- **Three non-officeholder special-guest speakers left deliberately
  untagged**, a new category for this project (distinct from the
  youth-testimony blocks documented earlier): **Peter Vidmar** (Apr
  1985, "Pursuing Excellence" — the 1984 Olympic gymnastics gold
  medalist), **R. LaVell Edwards** (Oct 1984, "Prepare for a Mission" —
  the BYU football coach), and **Don Lind** (Oct 1985, "The Heavens
  Declare the Glory of God" — the NASA astronaut). All three are
  well-known LDS public figures invited to address a specific conference
  session without holding any Church office this app tracks — same
  "leave untagged rather than guess" principle as every other
  unconfirmed-calling case in this project.
- **Validation clean** across the whole 3019-talk dataset: zero
  duplicates, zero orphans, zero sandwiched gaps, zero missing
  conferences in the expected Oct 1984 → Apr 2026 run (confirmed only
  after adding the Oct 1986 catch-up batch).
- Footer copy and code comment in `docs/index.html` updated: "eighty-five
  conferences... every conference from October 1984 through April 2026,
  plus Oct 1974."
- **Verified live**: `TALKS.length` = 3019; `ROLE_LOOKUP` confirmed
  Monson flipping `apostle`→`first-presidency` exactly at the Apr 1986
  boundary, Kimball (`president`), the five-way Apr 1985 Presiding
  Bishopric transition, Richard G. Scott correctly still `seventy` at Apr
  1986 (pre-dates his 1988 apostle call), and Peter Vidmar resolving to
  `undefined` (confirming the deliberate non-tag).

## ✅ Done: backward coverage to October 1982 (a real cross-batch bug found and fixed)
Added Oct 1982, Apr 1983, Oct 1983, Apr 1984 (128 talks, after dropping
one admin-report title that slipped past the exclusion filter — see
below). **The continuous run now goes October 1982 → April 2026 (89
conferences back to back)**, plus the October 1974 standalone. **3147
talks total.**
- **Exclusion-filter gap found**: `"Church Audit Committee Report"` (no
  leading "The") slipped past `EXCLUDE_PREFIX`, which only had `"The
  Church Audit Committee Report"` — a different exact title used in a
  later era. Caught by the zero-topic check (an admin report obviously
  has no official topic), removed by hand for this batch. **Worth adding
  both title variants to the standing exclusion list for any future
  session** — the admin-report titles are not perfectly stable across
  decades, so a per-batch title scan for "Audit"/"Statistical"/
  "Sustaining" (not just the fixed exclusion set) is cheap insurance.
- **Kickers**: zero, as expected this far back.
- **Topics**: 128/128 (after dropping the admin report) matched.
- **A real bug from an earlier session's batch, found and fixed**: this
  session's fresh research turned up that **M. Russell Ballard wasn't
  called to the Quorum of the Twelve until October 6, 1985** (he was a
  Presidency of the Seventy member before that) — but the "Oct 1984 →
  Apr 1986" batch two sessions ago had defaulted him to `apostle` for
  **all four** of its conferences, incorrectly including Oct 1984 and Apr
  1985 (before his actual calling). **Fixed**: those two entries changed
  to `seventy`; Oct 1985 and Apr 1986 (his real apostle-era talks) were
  already correct. A cross-check for role "flip-flops" (a speaker's role
  changing and then changing back) was added to the validation pass
  specifically to catch this class of error — it came back clean after
  the fix. **Lesson for future batches, worth internalizing**: when
  extending a "stable apostles" set backward across a new session, don't
  assume last session's set is still accurate — a name in it may have
  been called to the Twelve mid-way through the *previous* batch's own
  date range. Verify each apostle's actual calling date against the
  batch's earliest conference, not just spot-check the newest one.
- **Two more real apostle-calling dates confirmed via search, both
  landing at Apr 1984 (the same conference, sustained together April 7
  1984)**: **Russell M. Nelson** (his talk that conference is literally
  titled "Call to the Holy Apostleship") and **Dallin H. Oaks** (no talk
  of his falls in this specific batch, but confirmed for future
  reference). Both tagged `apostle` starting exactly there — no earlier
  talk of either exists in the dataset, so there's no gap to manage.
- **Young Women: Elaine A. Cannon → Ardeth G. Kapp, and Relief Society:
  Barbara B. Smith → Barbara W. Winder, both real same-conference
  transitions landing at the identical Apr 1984 conference** — Cannon
  (8th YW president, 1978–1984) and Smith (RS president, 1974–1984,
  already partly known from Winder's own start date) both give farewell
  talks the same conference Kapp and Winder give their first, matching
  the established same-conference-transition pattern used throughout
  this project.
- **Four more non-officeholder speakers left deliberately untagged**,
  extending last session's new "special guest / no confirmed calling"
  category: **Jeffrey R. Holland** (Apr 1983 — five years before his
  1989 Seventy call, most likely speaking in his capacity as sitting BYU
  president rather than as a General Authority; his later talks already
  correctly resolve `seventy`/`apostle` per prior sessions), **Matthew
  S. Holland** and **Devin G. Durrant** (both youth-themed talks by men
  too young at the time to hold any tracked calling — Durrant was later
  a Sunday School general president, already documented, but not yet in
  1984), and **Michael Nicholas** (Oct 1982, part of an Aaronic
  Priesthood activation-themed cluster with no confirmable calling).
- **Validation clean**, including the new role-flip-flop check: zero
  duplicates, zero orphans, zero sandwiched gaps, zero missing
  conferences in the expected Oct 1982 → Apr 2026 run, zero suspicious
  role flip-flops across the whole 3147-talk dataset.
- Footer copy and code comment in `docs/index.html` updated: "eighty-nine
  conferences... every conference from October 1982 through April 2026,
  plus Oct 1974."
- **Verified live**: `TALKS.length` = 3147; `ROLE_LOOKUP` confirmed the
  Ballard fix (`seventy` at Oct 1984/Apr 1985, `apostle` from Oct 1985),
  Nelson's Apr 1984 apostle tag, the Cannon/Kapp and Smith/Winder
  same-conference transitions, and Holland's Apr 1983 key resolving to
  `undefined`.

## ✅ Done: backward coverage to October 1980 (Hinckley's apostle→First-Presidency boundary correctly split)
Added Oct 1980, Apr 1981, Oct 1981, Apr 1982 (156 talks, after dropping
one more admin-title variant — see below). **The continuous run now
goes October 1980 → April 2026 (93 conferences back to back)**, plus the
October 1974 standalone. **3303 talks total.**
- **Another exclusion-filter title variant caught**: `"Sustaining of
  Church Officers"` (missing both "The" and any distinguishing suffix)
  slipped past the filter at Apr 1982 — a third variant of the same
  generic admin item, after "The Sustaining of Church Officers" (already
  excluded) and last session's "Church Audit Committee Report" catch.
  Removed by hand. **The exclusion list is clearly not exhaustive across
  eras — scan every new batch's raw titles for "Audit"/"Statistical"/
  "Sustaining" before trusting the fixed `EXCLUDE_EXACT`/`EXCLUDE_PREFIX`
  sets**, same lesson as last session, now proven twice in a row.
- **Kickers**: zero, as expected.
- **Topics**: 155/156 matched (after dropping the admin item); one
  exception, no red flag.
- **A real correction caught before merging this time (not after, unlike
  the Ballard bug two sessions ago)**: **Gordon B. Hinckley was a plain
  apostle, not yet in the First Presidency, for Oct 1980 and Apr 1981** —
  he wasn't set apart as a third counselor to Kimball until **July 23,
  1981**, several months after Apr 1981's conference. His Oct 1980/Apr
  1981 talks are tagged `apostle`; Oct 1981 onward (his first conference
  after the July calling) is `first-presidency`, matching the pattern
  already used for every other apostle-to-FP transition in this project.
  Also confirmed **Victor L. Brown (Presiding Bishop, 1972–1985) and H.
  Burke Peterson (his 1st counselor from 1972)** — both were nearly
  missed for this same reason (an earlier draft of this batch's script
  defaulted both to `seventy` before a second pass caught it) — **worth
  re-checking this project's evolving Presiding Bishopric timeline
  explicitly every time a new batch reaches further back than the
  previous batch's earliest Presiding Bishop research**, the same lesson
  as the Ballard apostle-date issue, just for a different role.
- **Relief Society counselor identification, partly confirmed via
  search and partly by strong contextual inference**: **Janath R.
  Cannon** was Barbara B. Smith's 1st counselor 1974–1978, succeeded by
  **Marian R. Boyer** (confirmed via search) — Boyer's talks in this
  batch are tagged `relief-society`. **Shirley W. Thomas** appears
  paired with Boyer at both Oct 1980 and Oct 1981 (both RS-themed
  session talks) but her exact office wasn't independently confirmed —
  tagged `relief-society` on the strength of that repeated pairing,
  flagged here in case a future session finds a source that
  contradicts it. **Mary F. Foulger** and **Addie Fuhriman** appear only
  once each (Oct 1980) alongside Smith/Boyer/Thomas — left deliberately
  untagged, most likely Relief Society General Board members (a level
  this app doesn't track), same treatment as the Elaine L. Jack Oct 1989
  case from two sessions ago.
- **One more non-officeholder pair left untagged**: **JoAnn Randall**
  and **Nyle Randall** (Oct 1981) — a married couple giving a joint
  service-themed talk, no confirmable calling, same "leave untagged"
  treatment as the Vidmar/Edwards/Lind celebrity-guest cases and the
  Holland-brothers/Durrant youth cases from the last two sessions.
- **Validation clean**: zero duplicates, zero orphans, zero sandwiched
  gaps, zero missing conferences in the expected Oct 1980 → Apr 2026
  run, zero role flip-flops, across the full 3303-talk dataset.
- Footer copy and code comment in `docs/index.html` updated: "ninety-
  three conferences... every conference from October 1980 through April
  2026, plus Oct 1974."
- **Verified live**: `TALKS.length` = 3303; `ROLE_LOOKUP` confirmed
  Hinckley's exact `apostle`→`first-presidency` split at the July 1981
  boundary, Victor L. Brown and Marian R. Boyer resolving correctly, and
  JoAnn Randall resolving to `undefined`.

## ✅ Done: backward coverage to October 1978 (Funk→Cannon and Shumway→Young predecessors confirmed)
Added Apr 1979, Oct 1979, Apr 1980, plus **Oct 1978** (151 talks, after
dropping two more admin-title variants — see below). **The continuous
run now goes October 1978 → April 2026 (97 conferences back to back)**,
plus the October 1974 standalone. **3454 talks total.**
- **Yet another admin-title variant caught, this time before merging**:
  `"Church Finance Committee Report"` (Apr 1979, Apr 1980) — a fourth
  distinct admin-report title family, after "The Sustaining of Church
  Officers," "Church Audit Committee Report," and "Sustaining of Church
  Officers" (no "The") from the last two sessions. Confirms the standing
  advice to scan every new batch's raw titles rather than trust the
  fixed exclusion set — **this is now the third session in a row this
  check has caught a real miss.**
- **A same-conference miss caught mid-batch, not before**: the first
  draft of this batch's role script only covered the Apr 1979/Oct 1979/
  Apr 1980 conferences' visible pattern and missed that **Oct 1978**
  (also fetched this batch) contains **two real auxiliary transitions**
  — re-scanning that conference's full speaker list caught both before
  merging. **Worth remembering: when a batch spans more conferences than
  the ones most recently discussed, re-scan *every* conference's full
  list against the role sets, not just the ones already top-of-mind.**
- **Young Women: Ruth H. Funk → Elaine A. Cannon, a real same-conference
  transition at Oct 1978** — Funk (7th YW president, confirmed via this
  session's search results) gives her farewell ("Come, Listen to a
  Prophet's Voice") the same conference Cannon gives her first ("If We
  Want to Go Up, We Have to Get On"), both tagged `young-women`, the
  same pattern used throughout this project. This is the predecessor to
  the already-documented Cannon→Kapp transition (Apr 1984).
- **Primary: Naomi M. Shumway confirmed as Dwan J. Young's predecessor**
  (6th Primary general president, 1974–1980, counselor Colleen B. Lemmon
  who has no talk in this batch) — her one talk in this batch (Oct 1979)
  is tagged `primary`. **The exact transition conference to Young is
  still not pinned down**: neither Shumway nor Young has a talk at Apr
  1980 (this batch) or Oct 1980 (already in the dataset from an earlier
  session) — Shumway's last talk in the dataset is Oct 1979, Young's
  first is Apr 1982 (already known). The search confirms "succeeded...
  in 1980" but not which specific conference — leave this open rather
  than guessing if a future pass ever needs the exact boundary.
- **Presiding Bishopric (Brown/Peterson) confirmed active this whole
  window** — both already documented from the previous two sessions,
  just continuing here with no new transition.
- **Topics**: 150/153 fetched talks matched; 3 exceptions — the historic
  "Revelation on Priesthood Accepted, Church Officers Sustained" (Oct
  1978, a real distinctly-titled proceeding, correctly kept per the
  Solemn Assembly precedent) and the two Church Finance Committee
  Reports (already dropped as admin items before this count, so not
  actually a concern).
- **Kickers**: zero, as expected.
- **Validation clean**: zero duplicates, zero orphans, zero sandwiched
  gaps, zero missing conferences in the expected Oct 1978 → Apr 2026 run,
  zero role flip-flops, across the full 3454-talk dataset.
- Footer copy and code comment in `docs/index.html` updated: "ninety-
  seven conferences... every conference from October 1978 through April
  2026, plus Oct 1974."
- **Verified live**: `TALKS.length` = 3454; `ROLE_LOOKUP` confirmed the
  Funk/Cannon Oct 1978 transition, H. Burke Peterson
  (`presiding-bishopric`), Naomi M. Shumway (`primary`), and Hinckley
  still correctly `apostle` at Apr 1980 (pre-July 1981).

## ✅ Done: backward coverage to October 1976 (Harold B. Lee's presidency researched, no transition needed)
Added Oct 1976, Apr 1977, Oct 1977, Apr 1978 (165 talks). **The
continuous run now goes October 1976 → April 2026 (101 conferences back
to back)**, plus the October 1974 standalone. **3619 talks total.**
- **Harold B. Lee's presidency researched, confirmed via search**: Lee
  (11th president, July 7 1972 – Dec 26 1973, the shortest 20th-century
  presidency at 18 months) had the **same two counselors Kimball later
  kept** — N. Eldon Tanner (1st) and Marion G. Romney (2nd) — meaning
  **no First-Presidency-transition research was actually needed for this
  batch**: every one of these 4 conferences falls entirely within
  Kimball's presidency (started Dec 30 1973), so the already-established
  Kimball/Tanner/Romney pattern (Hinckley still a plain apostle
  throughout, pre-July 1981) just continues unchanged. Lee's own
  presidency itself (July 1972 – Dec 1973) still has no conferences in
  this dataset — that's the next task, see below.
- **A fifth admin-title variant matched an already-generalized pattern**
  (`"Church Finance Committee Report"`, already added to the exclusion
  set last session) — no new variant this time, the standing exclusion
  list held up for this batch.
- **Kickers**: 1 more of the "context note" family (not this project's
  usual one-sentence-teaser style) — a McConkie sermon originally given
  in Lima, Peru, printed at Kimball's request. Kept verbatim.
- **Topics**: 164/165 matched; the exception ("Presentation of Scouting
  Award," Apr 1977) has no official topic tag, unsurprising for a
  ceremonial award presentation rather than a doctrinal talk.
- **New apostle added to the stable set for this era**: **Delbert L.
  Stapley** (called 1950, active through this whole batch) — the first
  time this project has needed him, since he doesn't appear in any
  later batch already covered.
- **Eldred G. Smith, Patriarch to the Church, reappears** (Apr 1978,
  "Decision") — tagged `other`, consistent with the precedent already
  established from his Oct 1974 talk (the unique non-Seventy priesthood
  office documented in an earlier session's `other`-role work).
- **One more non-officeholder left untagged**: **Arch Monson** (Apr
  1977, "Presentation of Scouting Award") — presenting a civic honor
  rather than giving a doctrinal sermon, no confirmable Church calling,
  same treatment as every other unconfirmed-calling case this project
  has hit.
- **No Relief Society/Young Women/Primary talks at all appear in this
  batch** — not a bug, just means none of Barbara B. Smith (the only
  auxiliary president confirmed active this era)'s counterparts spoke at
  these 4 particular conferences; Smith herself has no talk in this
  batch either. Nothing to tag, nothing to flag.
- **Validation clean**: zero duplicates, zero orphans, zero sandwiched
  gaps, zero missing conferences in the expected Oct 1976 → Apr 2026
  run, zero role flip-flops, across the full 3619-talk dataset.
- Footer copy and code comment in `docs/index.html` updated: "one
  hundred and one conferences... every conference from October 1976
  through April 2026, plus Oct 1974."
- **Verified live**: `TALKS.length` = 3619; `ROLE_LOOKUP` confirmed
  Stapley (`apostle`), Eldred G. Smith (`other`), Victor L. Brown
  (`presiding-bishopric`), Hinckley still `apostle` at Apr 1978, and Arch
  Monson resolving to `undefined`.

## ✅ Done: the standing gap is FULLY CLOSED — October 1974 → April 2026, one unbroken chain, no more standalone entries
Added Apr 1975, Oct 1975, Apr 1976 (143 talks) — the last 3 conferences
needed to bridge the final hole between the Oct 1976 start and the old
Oct 1974 standalone entry. **This is a milestone for the project: there
are no more gaps or standalone conferences anywhere in the dataset.**
Every single General Conference from **October 1974 through April
2026 — 104 conferences in a row** — is now present, continuous, and
fully role/topic-tagged. **3762 talks total.**
- No new First Presidency research was needed — every conference in
  this batch falls under Kimball (Tanner/Romney counselors, already
  established), confirming last session's prediction.
- **Kickers**: zero, as expected.
- **Topics**: all 143 matched — zero exceptions this batch.
- One new name added to the stable-apostles set for completeness:
  none needed this batch (Delbert L. Stapley, added last session,
  covers it). One new Seventy-era name: **ElRay L. Christiansen**
  (Apr 1975 only).
- **Validation clean**, including the milestone confirmation: zero
  duplicates, zero orphans, zero sandwiched gaps, **zero missing
  conferences in the full October 1974 → April 2026 range** (the
  missing-conference check was run against `1974-10` as the floor for
  the first time — it came back completely empty), zero role
  flip-flops.
- **Footer copy and the code comment in `docs/index.html` were rewritten**,
  not just incremented — the old "Oct 1974 standalone, plus every
  conference from X onward" phrasing no longer applies since there's no
  standalone conference left at all. New wording: "every single General
  Conference from October 1974 through April 2026, one hundred and four
  conferences in a row with no gaps."
- **Verified live**: `TALKS.length` = 3762, spanning `min(year)` = 1974
  to `max(year)` = 2026; spot-checked Kimball (`president`), Romney
  (`first-presidency`), Eldred G. Smith (`other`), and Hinckley (still
  `apostle` at Oct 1975, correctly pre-dating his July 1981 First
  Presidency call) all resolving correctly at the very edge of the newly
  closed range.

## ✅ Done: backward coverage to April 1971 — THE ENTIRE GOSPEL LIBRARY RANGE IS NOW COMPLETE
Added April 1971 through April 1974 (7 conferences, 292 talks, after
excluding 13 admin-report-variant items and one more empty-speaker
ceremonial item — see below). **The dataset now spans every single
General Conference from April 1971 — the earliest one the Church's own
Gospel Library app makes available — through April 2026: 111
conferences in a row, zero gaps, zero standalone entries. 4054 talks
total.** At the user's explicit request to match Gospel Library's own
range, this is the natural stopping point for "keep going backward" —
there is nothing earlier to add without going beyond what the Church's
own app offers.
- **Two First-Presidency-era transitions researched, both confirmed via
  search**:
  1. **Joseph Fielding Smith (10th president, Jan 23 1970 – d. July 2
     1972)** — counselors **Harold B. Lee (1st)** and **N. Eldon Tanner
     (2nd)**. When Lee became the 11th president (set apart July 7
     1972), he kept Tanner but **promoted him to 1st counselor and added
     Marion G. Romney as 2nd** — meaning Romney, already a longtime
     apostle, wasn't part of the First Presidency at all until this
     point. Role tags: Smith = `president` (Apr 1971/Oct 1971/Apr 1972,
     his last conference before death), Lee = `first-presidency` for
     those same 3, then `president` from Oct 1972 (his own first
     conference) through Oct 1973 (his last — he died Dec 26 1973).
     Romney = `apostle` through Apr 1972, `first-presidency` from Oct
     1972 on. Tanner = `first-presidency` throughout, unchanged the
     whole time — the one constant across three different presidents.
     Kimball himself (already confirmed Dec 30 1973 – Nov 1985
     president, Tanner/Romney counselors) is `apostle` for every
     conference in this batch **except** Apr 1974, his first as
     president (the Solemn Assembly for his own sustaining, read by
     Tanner, falls at that exact conference).
  2. **The Presiding Bishopric before Victor L. Brown**: **John H.
     Vandenberg** (9th Presiding Bishop, 1961 – April 6 1972) with
     **Victor L. Brown as his 2nd counselor since 1961** (so Brown is
     `presiding-bishopric` for every conference in this entire batch,
     both before and after his own April 6 1972 promotion to bishop —
     same-day transition, already-established pattern). Vandenberg's
     farewell talk is at that same Apr 1972 conference
     (`presiding-bishopric`); from Oct 1972 on he's `seventy` (moved to
     Assistant to the Twelve, the pre-1976 equivalent this project
     already treats as `seventy`). **Vaughn J. Featherstone** was also
     sustained 2nd counselor in the Presiding Bishopric that identical
     Apr 1972 conference (a triple-transition conference — bishop,
     outgoing 1st counselor's replacement wasn't researched since no
     talk of theirs appears, and this new 2nd counselor, all landing the
     same day), serving until Oct 1 1976.
- **Five real cross-session bugs found and fixed, all through careful
  apostle-calling-date verification prompted by this batch's needs —
  this is the single most important lesson from this session, worth
  reading in full before ever reusing a "stable apostles" set again:**
  1. **David B. Haight** wasn't ordained an apostle until **January 8,
     1976** (he was "Assistant to the Twelve" from 1970) — his Apr
     1975/Oct 1975 entries (already merged from an earlier session) were
     wrongly `apostle`; fixed to `seventy`. Every entry from Apr 1976 on
     was already correct.
  2. **Neal A. Maxwell** wasn't ordained an apostle until **July 23,
     1981** (sustained Oct 3 1981) — he was only an "Assistant to the
     Twelve" from April 6 1974. Five already-merged entries (Apr 1975,
     Apr 1976, Oct 1976, Apr 1978, Oct 1980) were wrongly `apostle`;
     fixed to `seventy`.
  3. **James E. Faust** wasn't ordained an apostle until **October 1,
     1978** — Assistant to the Twelve from Oct 1972, First Quorum of the
     Seventy presidency from Oct 1976. Four already-merged entries (Apr
     1975, Oct 1975, Oct 1976, Oct 1977) were wrongly `apostle`; fixed to
     `seventy`.
  4. **LeGrand Richards** — the opposite kind of error — was actually an
     **apostle continuously from April 6 1952 to January 1983** (a
     previous Presiding Bishop, 1938–1952, before that). This project
     had been defaulting him to `seventy` almost everywhere all
     session — **21 already-merged entries**, spanning nearly every
     batch from Oct 1974 through Oct 1982, were wrong and are now fixed
     to `apostle`.
  5. **Vaughn J. Featherstone** — 7 already-merged entries (Apr/Oct 1972,
     Apr/Oct 1973, Apr/Oct 1975, Apr 1976) were wrongly `seventy` instead
     of `presiding-bishopric`, per the transition documented above.
  **All five were caught by the "role flip-flop" check** (a speaker's
  role changing and changing back to an earlier value) **run against the
  full merged dataset after this batch, not by manual review** — proof
  that check earns its keep every session it's run, not just the one
  where a bug was introduced. **Also caught, this time before merging
  rather than after**: Bruce R. McConkie (apostle only from Oct 12
  1972 — First Council of the Seventy before that) and Marvin J. Ashton
  (apostle only from Dec 2 1971) and L. Tom Perry (apostle only from
  Apr 6 1974, Assistant to the Twelve from Oct 6 1972) all needed
  per-conference splits within this single batch, verified via search
  before any data was written, not assumed from later-batch precedent.
- **The exclusion filter needed real generalization for this era, not
  just more literal variants**: titles like "Sustaining of General
  Authorities and Church Officers," "Sustaining of Church Authorities
  and Officers," "Audit Report," and "Audit Report 1971" (13 total admin
  items across the 7 conferences) don't match any previous session's
  literal exclusion strings. Switched to a **prefix/substring rule**
  (starts with "Sustaining of", "Statistical Report", "Audit Report", or
  "Church Finance Committee Report"; contains "Audit Committee Report"
  or "Auditing Department Report") instead of an ever-growing literal
  set — **this is the more durable fix future sessions should extend,
  rather than adding yet another exact string**. Also dropped one more
  empty-speaker ceremonial item ("The Annual Report of the Church," Apr
  1972, no byline), same treatment as the Apr 1997 video presentation
  from an earlier session.
- **Two more people left deliberately untagged**: **Wendell J. Ashton**
  (Apr 1971) was a Regional Representative and advertising executive —
  a real, identifiable, but untracked calling (like Richard E. Turley
  Sr. from an earlier session) — and **Dallin H. Oaks** (Oct 1971, over
  a decade before his 1984 apostle call) was BYU's president at the
  time, most likely a guest-address appearance rather than a General
  Authority calling. **No Relief Society/Young Women/Primary talks
  appear anywhere in this whole batch** — not a bug, just means none of
  that era's auxiliary presidents (whoever they were — this project has
  never researched them) had a talk captured in the main-session listing
  for these 7 conferences specifically.
- **Kickers**: 22 found, mostly the same "context note" family as prior
  sessions (talks delivered by proxy, welfare-session addresses, etc.),
  kept verbatim as always.
- **Validation clean** across the full 4054-talk dataset, **after** the
  5 retroactive fixes above: zero duplicates, zero orphans, zero
  sandwiched gaps, **zero missing conferences in the complete April 1971
  → April 2026 range**, zero role flip-flops.
- Footer copy and code comment in `docs/index.html` rewritten again:
  "one hundred and eleven conferences... every conference from April
  1971 through April 2026... matching the earliest conference the
  Church's Gospel Library app makes available."
- **Verified live**: `TALKS.length` = 4054, `min(year)` = 1971;
  spot-checked LeGrand Richards (`apostle`), Featherstone
  (`presiding-bishopric`), Faust (`seventy`, pre-1978), Haight
  (`seventy`, pre-1976), Joseph Fielding Smith (`president`), Lee
  (`president` at Oct 1972), and Kimball's exact `apostle`→`president`
  split at Apr 1974.

## ✅ Done: Backup export/import + OS-backup hardening (data-loss mitigation)
Favorites and My Lists (`findATalkFavorites`/`findATalkCollections`/
`findATalkCollectionMembers`) are `localStorage`-only, per-device, with no
accounts or server sync — so clearing site data, reinstalling, or
switching devices loses them with no recovery path. Added two
independent mitigations (discussed with the user as "option 1" and
"option 3" of four considered; a real backend sync was ruled out as too
big a lift for a no-accounts static app):
- **Manual export/import** (`docs/index.html`, in the My Lists page,
  `collectionsIndexZone`) — "Export Backup"/"Import Backup" buttons.
  `exportBackupData()` bundles favorites + collections +
  collectionMembers (deliberately **not** `recentKeys` — that's viewing
  history, not worth backing up) into a versioned JSON blob;
  `saveBackupToFile()` prefers `navigator.share({files})` (needed inside
  the wrapped mobile app, where a plain `<a download>` often can't save a
  file — same fallback pattern as `shareTalk()`) and falls back to a
  blob download link for the plain website. Import always **merges**,
  never replaces: favorite keys are unioned, and collections are unioned
  keyed by collection `id`, so re-importing the same file twice, or
  restoring onto a device that already has some of these lists, is safe
  and never duplicates or loses anything. Verified live: created a list
  + favorite, captured the exported JSON directly from the blob, cleared
  `localStorage`, reloaded, imported that JSON back in — favorite and
  list both restored exactly; re-importing the same file again correctly
  reported "Added 0 favorites" (already present, no dupes); a malformed
  file correctly surfaced "Import failed" without throwing.
- **OS-level passive backup, made explicit rather than left implicit** —
  neither platform had this feature (Android had `allowBackup="true"`
  but no rules file, so its scope was whatever the undocumented default
  happened to cover including this app's WebView data). Native pieces
  are correct by inspection (no `@capacitor/preferences` etc. needed —
  the WebView's storage was never excluded from OS backup, on either
  platform):
  - **Android**: `android/app/src/main/res/xml/data_extraction_rules.xml`
    (API 31+) and `backup_rules.xml` (API 23-30 fallback), wired into
    `AndroidManifest.xml` via `android:dataExtractionRules`/
    `android:fullBackupContent`. Both explicitly include
    `app_webview/` (where WebView localStorage lives) alongside every
    other domain (`sharedpref`/`database`/`file`/`external`/`root`), so
    this reaffirms — rather than narrows — today's default "back up
    everything" behavior, and guards against a future contributor adding
    a narrower rules file that unintentionally drops WebView data
    without realizing it lives outside the app's cache dirs.
  - **iOS**: no `NSURLIsExcludedFromBackupKey` exclusion existed or was
    added — a documenting comment was added at the top of
    `ios/App/App/Info.plist` instead, so a future change that excludes
    other files from backup doesn't accidentally sweep in the WebView's
    `WebKit/WebsiteData` directory.
  - This only covers same-platform device restores (new iPhone from an
    iCloud/iTunes backup of an old iPhone; new Android phone from a
    Google Account backup of an old one) — it does **not** sync live
    between two devices someone owns at once, and does **not** help
    anyone moving between iOS/Android/the plain website, which is what
    the export/import feature above is for. Not independently testable
    without an actual device restore, so this is correct-by-inspection
    of the manifest/plist wiring only, not verified end-to-end.
- `npx cap copy` was re-run after the `docs/index.html` change to
  propagate it into `ios/App/App/public/` and
  `android/app/src/main/assets/public/`.

## ⏭️ Next task: none scoped — this was the user's explicit stopping point
The user asked specifically to reach **April 1971**, matching what the
Gospel Library app itself offers, and that goal is now met — **there is
no further backward expansion to do** unless the user asks to go beyond
what Gospel Library provides (which would need fresh research into
whatever came before Joseph Fielding Smith, and isn't information the
Church's own current app surfaces either). If a future session is asked
to keep expanding anyway: the immediate next research needed would be
**Joseph Fielding Smith's own predecessor** (David O. McKay, died Jan 18
1970) and Smith's succession to the presidency, plus fresh Relief
Society/Young Women/Primary/Presiding-Bishopric-predecessor research,
none of which this project has ever touched below April 1971.
**Two process lessons from this session are worth re-reading before any
future large role-tagging pass, regardless of direction**:
1. **Never add a name to a "stable apostles" (or any other stable-role)
   set without verifying that specific person's actual calling date** —
   five real bugs this session came from assuming later-batch precedent
   applied to earlier conferences without checking. A name being
   "obviously an apostle" in every batch you've seen it in is not
   evidence it was an apostle in a batch you haven't checked yet.
2. **Run the full validation pass — especially the role flip-flop
   check — against the *entire* merged dataset after every batch, not
   just the newly-added rows.** Four of the five bugs above were sitting
   undetected in already-merged data from earlier sessions; the
   flip-flop check caught all of them the moment a later batch's data
   made the pattern visible. It would be worth deliberately re-running
   this check once more as a dedicated audit pass even with no new data
   being added, in case any earlier-era name still has an undetected
   error that just hasn't collided with a later batch yet.
Remember to keep scanning every new batch's raw titles for admin-report
variants (now handled by a prefix/substring rule, not a literal list)
and to re-scan every conference in a multi-conference batch against the
role sets individually.

## Known past mistake (for awareness, already fixed)
Earlier in this project, a large batch of talk-array entries was
accidentally pasted inside the `ROLE_LOOKUP` object literal instead of the
`TALKS` array, breaking the JS syntax. It was caught by validating the file
(parsing `TALKS` and `ROLE_LOOKUP`, checking every role key resolves to a
real talk, checking for duplicate talk rows) before shipping.
**Always run an equivalent validation pass after bulk-editing this file.**

**Node.js is now installed** (`v24.19.0`, confirmed during the Phase 1
mobile-packaging refactor) — prefer it for any new JS-behavior testing
(no file-size ceiling, no browser-tool flakiness; see the Phase 1 section
above for the pattern). The validation pass below predates Node being
available and still works fine via `python3` (present at
`/usr/bin/python3`) for pure data checks — no need to redo it in Node. A
JS object/array literal with
double-quoted keys and no trailing comma on the final entry parses fine
with `json.loads` after stripping `//` comment lines; a trailing comma
before the closing `}`/`]` is valid JS but breaks `json.loads`, so match
the file's existing convention of no trailing comma on the last entry.
Equivalent validation pass (adjust paths as needed):

```bash
python3 << 'EOF'
import re, json
content = open('conference-draw.html', encoding='utf-8').read()
def extract(varname, wrap):
    m = re.search(r'const ' + varname + r' = \' + wrap[0] + r'([\s\S]*?)\n\' + wrap[1] + r';', content)
    lines = [l for l in m.group(1).split('\n') if l.strip() and not l.strip().startswith('//')]
    return json.loads(wrap[0] + '\n'.join(lines) + wrap[1])
talks = extract('TALKS', '[]')
role_lookup = extract('ROLE_LOOKUP', '{}')
topic_lookup = extract('TOPIC_LOOKUP', '{}')
topic_labels = extract('TOPIC_LABELS', '{}')
print('talks:', len(talks), 'roles:', len(role_lookup), 'topic entries:', len(topic_lookup), 'topic labels:', len(topic_labels))
talk_keys = set(f'{t[1]}|{t[2]}|{t[3]}' for t in talks)
print('role keys with no matching talk:', sum(1 for k in role_lookup if k not in talk_keys))
topic_keys = set(f'{t[2]}|{t[3]}|{t[4]}' for t in talks)
print('topic-lookup keys with no matching talk:', sum(1 for k in topic_lookup if k not in topic_keys))
print('talks missing a topic-lookup entry:', sum(1 for k in topic_keys if k not in topic_lookup))
seen = set(); dupes = sum(1 for t in talks if tuple(t) in seen or seen.add(tuple(t)))
print('duplicate talk rows:', dupes)
EOF
```

Also worth a plain bracket/brace/string balance check over the whole
`<script>` block (comment- and string-aware) since there's no `node -e`
to lean on for a real parse — ask Claude to write one if needed, it's
straightforward with a small hand-rolled tokenizer.

## Fetching pattern that worked for conference session data
Each conference's full talk list (title + speaker + URL) can be retrieved
in one fetch of:
```
https://www.churchofjesuschrist.org/study/general-conference/{year}/{month}?lang=eng
```
This returns the complete session-by-session contents listing with real
URLs — much more efficient than fetching each talk individually.

**Better than WebFetch for this: `curl` the page directly and regex-parse
it.** `curl` has full network access in this environment (no auth needed),
and the raw HTML's sidebar nav has a reliable, regular structure:

```html
<a class="item-U_5Ca" href="/study/general-conference/2017/10/turn-on-your-light?lang=eng">
  <div class="itemTitle-MXhtV"><p><span>Turn On Your Light</span></p>
  <p class="subtitle-LKtQp">Sharon Eubank</p></div>
</a>
```

A regex like
`<a class="item-U_5Ca" href="(/study/general-conference/(\d{4})/(\d{2})/([^"?]+))\?lang=eng"[^>]*><div class="itemTitle-MXhtV"><p><span>(.*?)</span></p>(?:<p class="subtitle-LKtQp">(.*?)</p>)?</div></a>`
against the raw HTML gives exact title/speaker/slug with zero
summarization risk (WebFetch runs a small model over the page and can
silently drop or mangle entries on long listings). Cross-checked this
against WebFetch's output for Oct 2017 and it matched exactly — but for
bulk data entry, prefer the `curl` + regex path. This is also exactly how
`TOPIC_LOOKUP` was built: same trick against
`/study/general-conference/topics/{slug}?lang=eng` pages, whose talk links
use a plainer `href="/study/general-conference/YYYY/MM/slug"` pattern
(no `item-U_5Ca` wrapper needed there, just the href regex). All 335
official topic slugs came from `curl`-ing
`/study/general-conference/topics?lang=eng` and extracting
`href="/study/general-conference/topics/{slug}"` — no need to hand-slugify
topic names (though it turns out simple slugification of the official
name list — lowercase, strip periods/apostrophes, spaces→hyphens — matches
the real slugs exactly, e.g. "U.S. Constitution" → `us-constitution`).

Administrative items to filter out of any new conference's talk list:
exact title `"The Sustaining of Church Officers"`, plus anything starting
with `"Church Auditing Department Report"` or `"Statistical Report"`.

## ✅ Done: `other` role expanded beyond Eldred G. Smith (2026-08-22)
User-requested change: move **Assistant to the Twelve**, **Church
Historian/Assistant Church Historian**, and **BYU President** talks into
`other`, rather than leaving the first folded into `seventy` (as the
original Seventy backfill deliberately chose to do) or left untagged (as
Church Historian/BYU President previously were). `other`'s label stays the
generic "Other" — it's now a real multi-office bucket, not a
Eldred-G.-Smith-only special case. 47 `roleLookup` entries changed in
`docs/data.json` (synced to `ios/App/App/public/data.json` and
`android/app/src/main/assets/public/data.json`, byte-identical as always):

- **44 entries reassigned `seventy` → `other`** for talks given while the
  speaker specifically held the pre-1976 **"Assistant to the Twelve"**
  office (a `seventy`-adjacent but formally distinct title, retired when
  the office was folded into the reorganized First Quorum of the Seventy
  at the **October 1976** conference — not April 1976, confirmed by
  Faust's title change landing exactly "from Oct 1976"). Talks from the
  same speakers at or after that Oct 1976 conference (already-First-
  Quorum-of-the-Seventy talks) were deliberately left as `seventy`, not
  swept into `other`:
  - **David B. Haight** — all 8 pre-apostle talks (Apr 1971 – Oct 1975;
    he left the office for the apostleship Jan 8 1976, before the Oct
    1976 reorg even happened).
  - **ElRay L. Christiansen** — all 8 of his talks (Apr 1971 – Apr 1975);
    he held this office continuously from Oct 1958 until his death May 23
    1975, never reaching the 1976 reorg.
  - **James E. Faust** — 6 talks (Oct 1972 – Oct 1975). His Oct 1976 and
    Oct 1977 talks stay `seventy` (First Quorum of the Seventy presidency
    from Oct 1976).
  - **John H. Vandenberg** — 6 talks (Oct 1972 – Apr 1976, i.e. every
    Assistant-to-the-Twelve-era talk through the last conference *before*
    the Oct 1976 reorg). His Apr 1978 talk stays `seventy`.
  - **Joseph Anderson** — 9 talks (Apr 1971 – Apr 1976). Previously
    documented (see the original Seventy backfill section above) as a
    deliberate exception left at `seventy` — that decision is now
    superseded by this change. His Oct 1976, Apr 1978, and Oct 1986 talks
    stay `seventy`.
  - **L. Tom Perry** — 3 talks (Oct 1972 – Oct 1973; he left the office
    for the apostleship Apr 6 1974).
  - **Neal A. Maxwell** — 4 talks (Apr 1974 – Apr 1976, i.e. through the
    last conference before the Oct 1976 reorg). His Oct 1976, Apr 1978,
    and Oct 1980 talks stay `seventy` (Presidency of the Seventy from Oct
    1976 until his Oct 1981 apostleship).
  - **Not touched, and shouldn't be re-researched**: Vaughn J.
    Featherstone's `seventy`-tagged talks all start Oct 1976 or later
    (he was in the Presiding Bishopric through Apr 1976), so none of his
    entries were ever Assistant-to-the-Twelve-era — correctly still
    `seventy`.
- **3 previously-untagged talks newly tagged `other`** — real,
  identifiable non-Seventy offices that simply aren't one of the ten
  tracked categories, same rationale as Eldred G. Smith's original `other`
  tag:
  - **Richard E. Turley Sr.**, Apr 1998 — Assistant Church Historian (a
    professional employee, not a sustained General Authority; previously
    left untagged per the "one-off employee never sustained a General
    Authority" carve-out documented in the Oct 1996–Apr 1999 batch
    section above — now reclassified from "untagged" to `other` instead).
  - **Dallin H. Oaks**, Oct 1971 — BYU President (served Sept 1971 – May
    1980, before his Utah Supreme Court and later apostolic service).
  - **Jeffrey R. Holland**, Apr 1983 — BYU President (served 1980–1989,
    before his Oct 1989 sustaining to the Quorum of the Twelve).
  - **Checked and found to need no action**: Merrill J. Bateman (BYU
    president Jan 1996 – 2003) and Cecil O. Samuelson (BYU president
    2003–2014) — neither has any talk in the dataset that falls during
    their BYU presidency; Bateman's entries are all from his Seventy/
    Presiding Bishopric years, and Samuelson has no talks in the dataset
    at all. Kevin J Worthen and C. Shane Reese (later BYU presidents)
    also have no talks in the dataset.
- **Not touched**: the "First Council of the Seventy" pre-1976 title
  (the other historical predecessor mentioned alongside Assistant to the
  Twelve in the code comment at the top of this file) — no specific
  case naming that exact title, as distinct from Assistant to the Twelve,
  was identified in this pass. If one turns up later, apply the same
  Oct-1976-boundary logic used above.
- If a future pass adds more offices to `other` (Church Patriarch's staff,
  mission presidents, temple presidents, etc.), keep following this same
  pattern: only tag a real, identifiable, verified office — `other` is
  still never a catch-all for "didn't bother to check."

## ✅ Done: `sunday-school` role added; `area-seventy` researched and deliberately NOT added (2026-08-22)
User asked for two new roles: **"Area Seventy"** (between `seventy` and
`other`) and **"Sunday School Presidency"** (between `young-men` and
`presiding-bishopric`), with all matching talks moved into them.

**New source-of-truth technique used for this pass, worth reusing any
time role assignment needs real verification:** every talk's own page at
`churchofjesuschrist.org/study/general-conference/{y}/{m}/{slug}` carries
the speaker's exact official calling in
`<p class="author-role">...</p>`, right under
`<p class="author-name">By Elder/Sister ...</p>`. This is the *exact*
wording the Church itself used for that talk at publication time — more
precise than any manual research, and scriptable via `curl` + a one-line
regex exactly like the existing `TOPIC_LOOKUP`/session-listing fetch
pattern documented above. For this pass, **every single one of the 1,316
candidate talks was checked this way**: all 1,263 talks then tagged
`seventy`, plus all 53 then-untagged talks — full coverage, not a sample.

- **`sunday-school` added, 22 talks reassigned `seventy` → `sunday-school`**
  (`roleLabels.sunday-school` = "Sunday School General Presidency"; role
  key order in both `docs/data.json` and `ROLE_ORDER` in `docs/index.html`
  is now `...,young-men,sunday-school,presiding-bishopric,seventy,other`).
  Every one of the 22 had an exact byline of "Sunday School General
  President," "First Counselor in the Sunday School General Presidency,"
  or "Second Counselor in the Sunday School General Presidency": A.
  Roger Merrill (Oct 2006), Daniel K Judd (Oct 2007), William D. Oswald
  (Oct 2008), Russell T. Osguthorpe (Oct 2009, Oct 2012), David M.
  McConkie (Oct 2010, Oct 2013), Matthew O. Richardson (Oct 2011), Tad R.
  Callister (Oct 2014, Oct 2017), Devin G. Durrant (Oct 2015, Apr 2018),
  Brian K. Ashton (Oct 2016, Oct 2018), Mark L. Pace (Oct 2019, Apr 2022,
  Apr 2024), Milton Camargo (Oct 2020, Apr 2023), Jan E. Newman (Apr
  2021, Oct 2023), Chad H Webb (Oct 2025) — this also **resolves the
  Chad H Webb uncertainty flagged in the original Seventy backfill
  section above**: his byline is Sunday School counselor, not GA Seventy,
  confirmed directly from the source rather than inferred.
  - **One deliberate exclusion**: Tad R. Callister's Apr 2019 talk is
    byline'd "**Recently Released** Sunday School General President" —
    per this project's "role at the time of the talk" rule, that's
    explicitly *not* currently holding the office at that talk, so it
    was left `seventy`, not moved.
  - No Sunday School Presidency talks existed among the pre-Oct-1997
    untagged pool either (checked as part of the same full sweep) — the
    office simply predates any of this dataset's Sunday School
    presidency members' conference talks.
- **`area-seventy` was NOT added.** Every one of the 1,316 checked talks'
  bylines was inspected for "Area Seventy" / "Area Authority Seventy" —
  **zero matches, anywhere in the entire 4,054-talk dataset.** This
  matches real Church practice: Area Seventies are sustained at
  conference (in the leadership/business session) but essentially never
  given an actual sermon speaking slot in the public Saturday/Sunday
  sessions this dataset draws from — that's reserved for General
  Authorities and general officers. **User was asked and chose to skip
  adding an always-empty category** rather than add one that would
  permanently show "0 talks match." If a real Area Seventy talk is ever
  found in a future conference (or an older one previously missed),
  add `area-seventy` at that point, positioned between `seventy` and
  `other` in both `ROLE_ORDER` and `roleLabels`, labeled "Area Seventy."
- **Byproduct findings from this full sweep, NOT acted on (out of scope
  for this request, flagged for a future pass)** — worth revisiting
  since the data is already sitting in `/tmp/pre1997_roles.tsv`,
  `/tmp/seventy_roles2.tsv`, `/tmp/untagged_roles.tsv` from this session
  (not committed anywhere, regenerate via the same curl+regex technique
  if needed):
  - **~102 pre-1976 talks have the exact byline "Assistant to the
    Council of the Twelve"** — noticeably more than the 44 talks (7
    speakers) reclassified to `other` in the section above this one,
    which was based on manual per-speaker research rather than a full
    byline sweep. The gap is unexplained and worth reconciling: either
    additional speakers held this exact office and were missed, or (more
    likely) many of these 102 are `seventy`-appropriate talks whose
    speaker's byline still read "Assistant to the Council of the Twelve"
    at the *pre-1976* time of the talk even though this project's
    existing merge logic already accounts for some of them — needs a
    side-by-side diff against the 44 already-moved keys before acting,
    not a blind bulk move.
  - **A handful of currently-`seventy`- or untagged talks have bylines
    that are obviously not Seventy at all**: local stake/ward callings
    ("Bishop, Beavercreek Ward...", "President, Portland Oregon East
    Stake", "Member of the Slate Canyon 14th Ward..."), a football coach
    ("Head Football Coach, Brigham Young University"), an astronaut
    ("Astronaut"), a Scouting official ("National President, Boy Scouts
    of America"), and a few Church employees ("Director of Internal
    Communications", "Commissioner, Health Services Corporation") — none
    of these should be `seventy`, and some may deserve `other` (real,
    identifiable non-Seventy office) once individually confirmed, same
    standard as Richard E. Turley Sr./Oaks/Holland above.
  - **Several already-tracked-category counselors are currently
    untagged** even though their byline is an exact match for an
    existing role: e.g. Elaine L. Jack and Jayne B. Malan (Young Women
    counselors, 1989/1991), and roughly two dozen Relief Society/Primary/
    Young Women counselors from 2016–2025 (Linda S. Reeves, Carole M.
    Stephens, Carol F. McConkie, Joy D. Jones, Bonnie H. Cordon, Neill F.
    Marriott, Sharon Eubank, Cristina B. Franco, Rebecca L. Craven, Lisa
    L. Harkness, Reyna I. Aburto, Tamara W. Runia, Andrea Muñoz Spannaus,
    Jean B. Bingham, Mary R. Durham [hers is "Recently Released," so
    correctly excluded]) — these look like a straightforward, low-risk
    batch tagging pass since the byline gives an exact, unambiguous
    match to a role that already exists in `ROLE_LABELS`.

## ⚠️ Manual step required before the next iOS build/push: enable App Groups

The streak counter now mirrors into the `TalkOfDayWidget` extension via a
custom native bridge (`ios/App/App/StreakBridgePlugin.swift`), which needs
an **App Group** shared container that only Xcode's Signing & Capabilities
UI can provision (it needs your Apple Developer Team ID) — I can't do this
step from the CLI. Until it's done, the app and Android widget work fine;
the iOS widget just silently shows no streak line (falls back to
talk-only, same as before this feature).

**To enable it, in Xcode:**
1. Select the **App** target → Signing & Capabilities → **+ Capability** →
   **App Groups** → **+** → add `group.com.captainfun333.findatalk`
   (must match exactly).
2. Select the **TalkOfDayWidget** (extension) target → same steps → check
   the *same* `group.com.captainfun333.findatalk` group (don't create a
   second one).
3. Build once so Xcode regenerates the `.entitlements` files for both
   targets.

If the group ID ever needs to change, update it in all three places it's
hardcoded: `StreakBridgePlugin.swift` (`appGroupID`), `TalkOfDayWidget.swift`
(`StreakStore.appGroupID`), and whatever you set in Xcode.

## ✅ Done: Color Palette setting (Brass/Rose/Slate/Sage), plus widget sync

Added a second, independent Settings axis alongside Light/Dark/System:
**Color Palette**, with four options — **Brass** (the original look, still
the default), **Rose**, **Slate**, **Sage** — in that fixed order.

**Web (`docs/index.html`)**:
- `themePalette` in `localStorage` holds `'rose'`/`'slate'`/`'sage'`;
  absent means Brass. Applied as `data-palette` on `<html>`, mirroring the
  existing `data-theme` pattern exactly (same anti-flash `<head>` script,
  same pre-paint timing).
- A new CSS "color palettes" block (right after the existing dark-mode
  `@media` block) defines three full token sets — light, explicit dark,
  and `prefers-color-scheme: dark` — for Rose/Slate/Sage. Brass needs no
  override; it's already the base `:root`. Each non-Brass palette also
  redefines `--accent-grad-start/-end`/`--accent-fill`/`--accent-fill-hover`
  (the fixed-regardless-of-theme solid-button colors), same idea as
  Brass's own already had.
- Settings modal: a new "Color Palette" segmented-control section (same
  `.segmented` component as Appearance), each button carrying a small
  literal-hex `.palette-swatch` dot so people can see the hue before
  picking it.
- `setPalette()`/`getStoredPalette()`/`updatePaletteToggleUI()` mirror the
  shape of `setTheme()`/`getStoredTheme()`/`updateThemeToggleUI()` exactly,
  as a fully independent axis — picking a palette never touches
  `themePreference`, and vice versa.

**Native widget sync** (this was explicitly requested as a fast-follow —
the palette shipped first without it, then this was added): `setPalette()`
now also calls `mirrorPaletteToNative(palette)`, the same
platform-branching shape as the existing `mirrorThemeToNative()`:
- **Android**: writes `findATalkPalette` via `@capacitor/preferences`
  (removed entirely for `'brass'`, same "missing key = default" pattern
  the theme mirror already used), then calls `WidgetRefresh.refresh()`.
  `TalkOfDayWidgetProvider.java`'s old `applyThemeOverride()` became
  `applyAppearanceOverride()` — now reads **both** `THEME_KEY` and the new
  `PALETTE_KEY`, and only early-returns (leaving the layout's
  auto-following `@color/widget_*`/`values-night` resources alone) in the
  one case that needs nothing extra: Brass with no explicit theme choice
  either. Any other combination resolves a literal color set from a new
  per-palette constant matrix (`LIGHT_ROSE_INK`, `DARK_SLATE_ACCENT2`,
  etc.) and one of **6 new drawables**
  (`widget_background_{rose,slate,sage}_{light,dark}.xml`) — plain
  rounded-rect shapes mirroring the existing Brass pair, literal hex only
  (no `@color/` refs, same reasoning as the Brass ones: a resource
  reference would re-resolve against whatever the device's *current*
  system night mode is, defeating an explicit override). A new
  `isSystemDark(Context)` helper covers the case a non-Brass palette is
  set but no explicit Light/Dark choice was made — it can't rely on
  `values-night` doing that automatically like Brass could, since
  `@color/widget_*` only ever resolves to Brass's hex values.
  - **Real bug caught by actually running `./gradlew`, worth remembering**:
    the first draft of those 6 drawables had XML comments mentioning CSS
    variable names like `--paper-raised` — literal `--` **inside** an XML
    comment body is invalid (XML spec forbids it, unlike HTML), and Android's
    resource compiler rejects it with a fairly obscure
    `XMLStreamException`/"The string "--" is not permitted within
    comments" error, not a friendly one. Fixed by dropping the leading
    `--` when referring to a CSS custom property name inside an XML
    comment (write `paper-raised`, not `--paper-raised`). Both
    `compileDebugJavaWithJavac` and a full `assembleDebug` were run to
    confirm — this wasn't just a syntax skim.
- **iOS**: `StreakBridgePlugin` gained a second bridge method,
  `setPalettePreference`, writing `findATalkPalette` to the same App Group
  `UserDefaults` suite as the streak/theme keys, then reloading the widget
  timeline — same shape as the existing `setThemePreference`.
  `TalkOfDayWidget.swift`'s `TalkPalette` enum was restructured from a
  single light/dark pair into four `PaletteSet`s (`brass`/`rose`/`slate`/
  `sage`, each still holding its own light+dark `Scheme`); `TalkEntry`
  gained a `paletteOverride: String?` field alongside the existing
  `themeOverride`, read via a new `PaletteStore` (mirrors `ThemeStore`
  exactly). `TalkPalette.resolve()` now takes both overrides — palette
  picks which `PaletteSet`, theme (or the system `colorScheme` if no
  explicit theme choice) picks light vs. dark within it. Verified with
  `swiftc -typecheck` on `TalkModel.swift`/`TalkOfDayWidget.swift` (clean,
  zero errors — these only import system frameworks) and `swiftc -parse`
  on `StreakBridgePlugin.swift` (clean syntax; full typecheck isn't
  possible standalone since it imports Capacitor, same limitation noted
  elsewhere in this doc — needs a real Xcode build to fully confirm).

All three platforms' hex values were hand-derived from the same four
palette definitions and must be kept in sync if a palette's colors ever
change — the CSS block, the Android constant matrix, and the Swift
`PaletteSet`s are three independent copies of the same numbers, exactly
like the pre-existing Brass light/dark values already were across all
three before this feature existed.

## ✅ Done: palette color rebalance + a real on-device WebKit bug found and fixed

Two follow-ups to the Color Palette feature above, from the same session,
both worth remembering in detail.

**Color rebalance**, from live feedback after actually looking at all four
palettes on-device: (1) Rose's light-mode background was too close to
Brass's own ivory to read as a distinct palette at a glance — boosted the
saturation of `--paper`/`--paper-raised`/`--line`/`--tint`/`--chip-*`/
`--bg-glow-*` (ink/accent colors unchanged). (2) Every dark-mode `--ink`
across all four palettes (including Brass) changed to pure `#ffffff`,
not a tinted off-white — a tinted dark-mode ink is the app's single
dominant text color, so any hue there read as "a color filter over the
whole screen," worst on Sage. (3) Sage's light mode had the same root
problem in miniature: `--ink`/`--ink-soft`/`--brass`/`--line` all carried
real saturation toward green, on top of the already-green `--paper`,
compounding into the same wash effect. Pulled all of those back toward
neutral, matching the principle Brass itself already followed: only the
two accent roles (`--brass`, `--burgundy`) should carry real saturation;
neutral roles (`ink`, `paper`, `line`, `tint`, `chip`) stay close to
neutral so the accents read as deliberate color choices, not a tint over
everything. All three platforms (CSS, Android color constants +
drawables, Swift `PaletteSet`s) were updated with the exact same new hex
values and re-verified.

**The WebKit bug** — found because the rebalance work above led to
testing every palette live in the iOS Simulator (not just in a desktop
browser), which the original Color Palette build never did. Rose (and
only Rose) rendered as plain Brass no matter what — the Settings button
showed "Rose" pressed, `localStorage` had `'rose'`, the DOM's
`data-palette` attribute was genuinely `"rose"` (confirmed with a
temporary live `getComputedStyle` debug readout injected into the page),
but `getComputedStyle(document.documentElement).getPropertyValue('--ink')`
kept resolving to Brass's ink, not Rose's. Reproduced identically in
plain mobile Safari (not just the Capacitor WKWebView), ruling out
anything Capacitor-specific. A Chromium-based browser (the Browser-pane
tool used throughout this project) did **not** reproduce it at all —
this is WebKit-only.

**Root cause, confirmed empirically**: it isn't about the word "rose".
Physically swapping the Rose and Slate CSS blocks in the stylesheet moved
the failure to Slate (now first) while Rose (now second) started working
— proven twice, in both directions, with a live debug readout each time.
WebKit does not reliably wire up dynamic-attribute-change invalidation
for the **first** CSS rule anywhere in a stylesheet that uses a brand-new
attribute name in an attribute selector (here, `[data-palette="..."]`).
Change that attribute's value via JS afterward and the DOM attribute is
correct, but the matching rule silently never applies — the cascade just
keeps resolving to whatever rule *did* get bucketed correctly (the base
`:root{}`, i.e. Brass). Two other fixes were tried and **did not work on
their own**, worth remembering so nobody retries them expecting a
different result: (1) reordering the blocks (just relocates the bug); (2)
having `data-palette="brass"` present in the static HTML from initial
parse, so the attribute always exists and only its *value* ever changes
(still failed identically on a fresh origin, no prior page load, ruling
out "attribute presence at parse time" as the deciding factor).

**The actual fix**: a single harmless, permanently-unmatched dummy rule —
`:root[data-palette="_warmup"]{ --ink: inherit; }` — placed as the
literal first `[data-palette="..."]` rule in the stylesheet, before
Rose/Slate/Sage's real rules. This "pre-registers" whatever internal
selector bucket WebKit uses for that attribute name, so every real rule
after it (first, second, or third) gets normal, correctly-invalidated
updates. Verified extensively after adding it: fresh app installs, first
click in a fresh Safari origin, and reordering Rose/Slate back to their
original positions — all four palettes (including Rose, repeatedly) now
apply correctly, confirmed both by `getComputedStyle` readouts and by
pixel-sampling real screenshots for exact hex matches (not eyeballing —
screenshot colors at a distance are unreliable, and this session
misjudged them more than once before switching to programmatic pixel
checks).

**Do not remove the `_warmup` rule, and do not move it after the real
palette rules** — it only works by being the literal first
`[data-palette]` rule in the file. Its own code comment (right above it,
in the "color palettes" CSS section of `docs/index.html`) carries this
same warning. If a fifth palette is ever added, it does not need a
`_warmup` rule of its own — one already covers the whole attribute name.
This is a WebKit engine quirk, not something tied to this app's specific
markup, so it's plausible (though unconfirmed) that the same fix would be
needed for any future `[data-xxx="..."]`-driven dynamic styling added to
this app — if a brand-new attribute-selector-driven feature ever seems to
silently not apply on iOS/Safari specifically while working fine in a
desktop browser, this bug is the first thing to suspect.

## ✅ Done: Notes ("what I learned" per talk) and a My Notes page
Added a fifth per-talk action alongside Favorite/Add to List/Share: a
pencil icon that opens a small modal for a free-text note, plus a new "My
Notes" page in the tab bar (Home/Recents/Favorites/**My Notes**/My Lists).
Fully local (no accounts/sync), same as Favorites/My Lists/streak.

- **Storage**: `NOTES_KEY = 'findATalkNotes'`, `noteMap` — a plain object
  (`talkKey() -> note text`), not a Set/array like `favoriteKeys`, since
  each talk holds at most one note and the text itself is needed, not
  just membership. `setNote()` trims and **deletes** the key on an empty
  string rather than storing `""`, so `hasNote()` never has to
  special-case a blank value sitting in storage.
- **"Recently Noted" ordering quirk worth remembering**: plain-object key
  order is insertion order, but JS does **not** move a key to the end on
  reassignment the way `favoriteKeys` (a `Set`) does on re-add. `setNote()`
  works around this by `delete`-then-`re-set`ting on every save, so
  editing an existing note bumps it to the front of "Recently Noted" the
  same way re-favoriting already does for Favorites — without this, only
  the first-ever save of a note would affect its sort position.
- **UI reuse**: the note icon button (`createNoteButton()`) is the same
  `.share-btn-icon` circle pattern as `createFavoriteButton()`/
  `createCollectionButton()` — filled/brass once a note exists, tooltip
  shows a preview, `dataset.talkKey` + `refreshNoteBadgesFor()` re-syncs
  every on-page copy after a save/delete (identical pattern to
  `refreshCollectionBadgesFor()`). The note preview itself
  (`.list-item-note`, "Your note: …") renders on **every** row that has
  one — list rows, Recently Viewed, Favorites, My Lists, My Notes — not
  just the My Notes page, same "surface it everywhere the talk appears"
  spirit as the kicker/read badge.
- **My Notes page**: built with the exact same `createSubsetFilterPanel()`
  / `createSortToggle()` / `renderSubsetList()` machinery Recently Viewed
  and Favorites already use — full Speaker/Calling/Conference/Topic
  filters, "Recently Noted" vs. "Conference Date" sort, same empty-state
  pattern. No new page-rendering code was needed, just another instance
  pointed at `noteMap`'s keys instead of `favoriteKeys`/`recentKeys`.
- **Modal**: `#noteModalOverlay`, reuses the existing `.modal`/`.modal-
  header`/`.modal-copy` styling from the "Add to a List" modal, plus one
  new `.note-textarea` rule. Save / Cancel / Delete Note (Delete only
  shown when a note already exists). Same overlay-click/Escape-to-close
  pattern as every other modal in the app — each modal wires its own
  listener rather than sharing one generic handler, matching existing
  style (see the Settings and Add-to-List modals).
- **Backup export/import**: `notes: noteMap` added to
  `exportBackupData()`. `mergeBackupData()` never overwrites a note
  already on the device — an incoming backup only fills in talks that
  don't have a local note yet — same "import never destroys" guarantee
  as Favorites/My Lists, plus a returned `addedNotes` count now shown in
  the import summary toast.
- **Verified live** in the Browser pane against a local `python3 -m
  http.server` copy (not `file://` — local `fetch()` of `data.json` is
  blocked under `file://`, per the existing note on this in the Phase 1
  section above): added a note from the Talk of the Day card, confirmed
  the pencil icon filled brass immediately, confirmed it appears on the
  My Notes page with filters/sort working, edited it (modal correctly
  prefilled the existing text and showed "Delete Note"), deleted it, and
  confirmed the empty-state message. No console errors. Also verified via
  `node --check` on the extracted inline script (no syntax errors) and a
  full `getElementById`-vs-`id=` cross-check (no dangling references)
  before ever loading it in a browser.

## ✅ Done: scripture citation data extraction (idea 18, foundation only)
Extracted scripture citations for every talk, laying the data foundation for
the "interact with scripture citations" feature (chips on each talk, a
Scripture filter/search, and reverse lookup — those three UI pieces are
**not yet built**, this is the data layer only).

**Extraction**: every General Conference talk page has its scripture
citations as structured footnote links — `<a class="scripture-ref"
href="/study/scriptures/{volume}/{book}/{chapter}?...">Display Text</a>` —
not prose, so this was mechanical/bounded rather than a research task like
Role tagging. A resumable, checkpointed Python script (curl + BeautifulSoup,
8-way concurrency) fetched all 4,054 individual talk pages directly from
churchofjesuschrist.org and parsed every `a.scripture-ref` link. Result:
**4,054/4,054 talks processed, zero fetch failures**, 47,841 total citation
instances (19,719 unique), across all four standard works plus Joseph Smith
Translation footnotes (`bofm`/`nt`/`ot`/`dc-testament`/`pgp`/`jst`). 212
talks (5.2%) have zero citations — verified as real, not a parsing gap: the
zero-citation count declines steadily by decade (66 in the 1970s down to 6
in the 2020s), a plausible real editorial trend, not concentrated in one
era the way a structural parsing bug would show up.

**Storage — interned, not verbose**: storing the full `{ref, volume, book,
chapter}` object on every citation instance would have been ~8.6MB (way too
large — `data.json` was 1.37MB going in). Instead, unique citation identities
are interned once into `citationRefs` (an array of `[ref, volume, book,
chapter]` tuples, 19,719 entries) and each talk's `citationLookup` entry is
just a list of integer indices into that table. Final `data.json`: **2.76MB**
(up from 1.37MB — a real but proportionate increase, comparable to what the
Session backfill added). New top-level keys: `citationRefs`,
`citationLookup` (keyed `year|month|slug`, same convention as
`sessionLookup`), `citationVolumeLabels` (6 entries: Book of Mormon, New
Testament, Old Testament, Doctrine and Covenants, Pearl of Great Price,
Joseph Smith Translation), `citationBookLabels` (101 entries, keyed
`volume|book`, e.g. `"bofm|alma"` → `"Alma"` — hand-authored from the actual
101 distinct volume/book slugs found in the real data, not scraped, since
these are fixed/well-known; do not regex-derive book names from the `ref`
display text itself — that text is genuine footnote prose with huge
formatting variance, e.g. "John", "John 17", "verse 17", "vv. 11, 14–15",
"third chapter of John, verse 16" all exist for the same book, so it does
**not** reliably reduce to a clean book name).

**Verified**: merged `data.json` round-tripped correctly (all pre-existing
keys — `talks`, `roleLookup`, `sessionLookup`, etc. — intact, counts
unchanged), and a spot-check reconstruction (index → ref/volume/book/chapter
→ real label lookup) confirmed correct for a known talk (Bednar, Oct 2023,
22 citations).

**Not done yet, still open** (see idea 18 in the feature-ideas memory notes):
citation chips on the ticket/list rows, the Scripture filter/search
(book-level, since citation cardinality is far higher than the 317-topic
taxonomy), and the reverse-lookup page (start from a scripture, find talks
that cite it). The app's JS doesn't read any of the four new `data.json`
keys yet — this session was data-extraction only. Native `cap sync` also not
run yet — no point until the UI actually uses the data.

## ✅ Done: scripture citation chips (idea 18, bullet 1 — real UI, not just data)
Built the first real UI on top of the citation data extracted earlier (see
"scripture citation data extraction" above): a "Citations:" pill row,
designed and iterated on with the user via an Artifact mockup before being
built for real (chips-vs-dropdown-vs-type-pills tradeoffs, hide-when-empty
rule, exclusive-expand-per-card behavior, icon design — including a
pulpit-with-microphone icon matched to the app's own logo silhouette — all
settled in that mockup first).

**What shipped**: a `<talk>.cite-block` (one unclickable "Citations:" label
+ one pill per citation type that actually has data) appears wherever a talk
is shown — the drawn-talk ticket, and every talk row (Show a List, Recently
Viewed, Favorites, My Lists, My Notes, the Talk of the Day card — all of
these share `buildListItemRow()`, so extending that one function covered
all of them at once). Only **Scriptures** is real today — Other Talks/
Hymns/Church Magazines/Other Sources were designed in the mockup but their
underlying data was never extracted (see the "what about other citation
types" research earlier in that conversation), so `buildCitationsBlock()`'s
`groups` array currently has one entry; more can be added later with zero
changes to the rendering/toggle logic, which was written generically for
exactly that.

**Behavior**: each pill is click-to-expand/collapse, showing every citation
as a real link straight to the exact verse on the Church's own scripture
pages (not just the chapter — see the anchor-precision note below). Only
one pill's panel is open at a time **within a given ticket or list row** —
opening a pill in one row never closes a different row's open pill
(`btn.closest('.ticket, .list-row')` scopes the "close the others" logic).
A talk with zero citations shows no block at all — verified live against a
real zero-citation talk ("A Witness and a Blessing," 1971).

**Anchor precision — a real fix made during this build, not in the original
data merge**: the first `citationRefs` merge (see the earlier section)
dropped the verse-level `id=`/`#` URL fragment to save space, keeping only
`[ref, volume, book, chapter]` — meaning every citation link would have
landed on the top of the chapter page, not the actual cited verse. Caught
before shipping and fixed by re-merging from the original raw extraction
(still on disk in scratch) with a 5th tuple element, `anchor` (e.g. `"p17"`,
`"p5-p6"`, `"p30,32"`) — `data.json` grew from 2.76MB to 2.93MB for this,
a small trade for exact-verse links matching the precision the rest of the
app already has (`talkUrl()`/"Open This Talk"). `talkCitations()` splits a
multi-verse anchor on `,` then `-` to build the `#` fragment (the real
Church pages use just the first verse for the scroll target, the full
anchor for the `id=` highlight param) — same pattern the original raw
`href`s used.

**CSS approach — reused existing tokens, added zero new custom
properties**: the app now has 4 color palettes (Brass/Rose/Slate/Sage) ×
2 themes, so a naive port of the mockup's own `--cite-border`/`--cite-bg`/
`--cite-text` variables would have needed 8 new blocks. Instead, citation
pills/panels are styled entirely from tokens that already exist in every
one of those 8 blocks (`--line`, `--paper-raised`, `--ink-soft`, `--brass`,
`--chip-bg`, `--chip-border`) — confirmed correct with a live
`getComputedStyle()` check after switching to the Rose palette, no visual
regression, no new tokens needed anywhere.

**Verified live** (local `python3 -m http.server` copy of `docs/`, real
browser, not just a syntax check — Browser-pane screenshots were
unavailable this session for an unrelated pane-visibility reason, so
verification leaned on DOM/JS state checks instead, which are arguably more
precise anyway): real per-talk citation counts rendered correctly across
~10 different talks in a live "Show a List" (1 to 42 citations, matching
the real extracted data); a known 22-citation talk (Bednar, Oct 2023)
round-tripped correctly end-to-end including the exact anchored href;
click-to-expand and click-to-collapse both confirmed via real `aria-pressed`
state and panel `hidden` toggling; a zero-citation talk confirmed to render
no block at all via the app's own search+list flow; `node --check` on the
extracted inline script (clean); a full `getElementById` cross-check
(`ticketCitations` present both in the HTML and the JS, no dangling refs).
One real bug hit and fixed **during testing, not the code itself**: a stale
cached copy of `data.json` in `localStorage` (from an earlier session
against this same local server) briefly made the new data look completely
missing after reload — a reminder that `loadData()`'s cache-first design
(see Phase 1 above) means a locally-tested change needs a clean
`localStorage` to actually reflect a `data.json` edit, not just a page
reload.

Synced into the Android project via `npx cap sync android`. Not yet done:
Other Talks/Hymns/Church Magazines/Other Sources data extraction (a
follow-up, not blocking), and bullets 2–3 (the Scripture filter/search and
the reverse-lookup page) from idea 18 are both still fully open.

## 🔍 Research done, not yet built: other citation types beyond Scriptures
Before building the citation chips above, surveyed a spread of ~48 talks
across all six decades in the dataset to catalog every footnote type, not
just `scripture-ref`. Findings, for whoever extracts these next:
- **`cross-ref`** (~9% of footnotes) — real, structured, clickable links to
  **other conference talks** and **Ensign/Liahona magazine articles**,
  sometimes anchored to a specific paragraph in the target. Same extraction
  technique as scripture-ref would work (a second CSS selector, same pass) —
  this is "Other Talks" and "Church Magazines" in the mockup/pill UI, and
  needs splitting into two groups by target domain (a conference-talk URL
  vs. an Ensign/Liahona URL).
- **Hymns** — NOT in `cross-ref`. They're plain, unlinked footnote text in a
  consistent pattern (`"America the Beautiful," Hymns, no. 338.`) — no href,
  no class. Relatively rare (~1 per 10 talks in the sample). To make these
  clickable needs a small curated hymn-number → title → URL-slug lookup
  (~341 hymns, bounded) since the footnote only gives the number, not a
  link — confirmed the real page pattern is
  `churchofjesuschrist.org/media/music/songs/{title-slug}`.
- **Plain-text citations with no link at all** (~18%) — books, magazines,
  "History of the Church, 5:25," personal correspondence/conversations,
  devotional talks not hosted online. Not linkable; this is "Other Sources"
  in the mockup/pill UI (renamed from "Other" since it's mostly not
  clickable, unlike its siblings).
- **A small `no-class` residual** (~5%) — real hrefs to non-Church external
  sites (e.g. josephsmithpapers.org). Folded into "Other Sources" rather
  than given its own pill.

None of this was extracted — only `scripture-ref` was. See idea 18 in
See idea 18 in the feature-ideas memory notes for status.

## ✅ Done: the other four citation types (Other Talks/Hymns/Church Magazines/Other Sources)
Followed up the earlier research pass (see "other citation types" above)
with a real extraction + merge + UI wiring — all five pills in the
Citations row are now live, not just Scriptures.

**Real bug caught and fixed before this shipped, not after**: a first-draft
extraction script only scanned numbered footnote `<li data-marker>`
elements. Some talks — especially older ones — cite scripture/other talks/
hymns as an **inline parenthetical right in the body paragraph**, with no
separate footnote section at all (e.g., `... make you free.” (<a
class="scripture-ref" href="...">John 8:31–32</a>.)` sitting directly in a
`<p>`, 1974's "God Will Not Be Mocked" being the exact case that surfaced
this). Scoping to footnote `<li>`s alone silently missed every citation on
those talks. Caught by cross-checking this script's own scripture count
against the already-merged, page-wide `a.scripture-ref` count from the
first extraction pass — 2,953 of 4,054 talks mismatched on the first run.
Fixed by classifying `a.scripture-ref`/`a.cross-ref` **page-wide** (not
`<li>`-scoped) and scanning **every** `p[data-aid]` content paragraph for
the Hymns pattern, not just footnote paragraphs — re-ran, 0 mismatches
after the fix (a small number of *higher* counts than the original merge
remained, expected and correct: the original scripture extraction dedupes
a citation repeated twice in one talk down to one entry, this cross-check
count doesn't).

**A second real risk caught before it became bad data**: classifying
"Other Talks" by bare href pattern (`/study/general-conference/...`)
instead of requiring the actual `cross-ref` CSS class would have picked up
a talk page's own table-of-contents sidebar — confirmed on a real page: 57
unrelated navigation links matching that URL pattern vs. 0 real
`a.cross-ref` citations on that specific talk. Fixed by requiring the
`cross-ref` class, same fix shape as the scripture-ref-vs-footnote-`<li>`
issue above: match the real citation markup, not a loose pattern.

**Extraction results**: all 4,054 talks re-processed, 0 failures.
2,276 Other Talks citations (**2,275 resolve to a talk already in this
app's own dataset** — matched by parsing the cited talk's year/month/slug
out of its href and checking against `TALKS`, so those link to the talk's
real title via `talkUrl()`, not a raw/possibly-stale footnote text
snippet; only 1 didn't resolve — a citation to a 1997 sesquicentennial
pioneer-trek commemorative address that was never part of a normal
semi-annual conference session, correctly absent from `TALKS`). 365
Church Magazine citations (Ensign/Liahona/New Era/Friend articles). 626
Hymn citations, 181 distinct hymns — of which **4 citations (hymn "no.
386") use the pre-1985 hymnal's numbering**, which doesn't exist in the
current 341-hymn book; left unlinked (plain text) rather than guessed,
since there's no reliable old-number-to-new-number mapping available.
7,085 Other Sources citations (books, personal correspondence, other
speeches not hosted online, "History of the Church" volume:page
references, and a small number of real external links like Joseph Smith
Papers) — spot-checked, genuinely real historical citations, not parsing
junk.

**Hymn number → title/URL lookup** (needed since a footnote only ever
gives a number, never a link): fetched the real hymnal table of contents
at `churchofjesuschrist.org/study/manual/hymns` — 341 entries, numbers 1–
341, zero gaps, zero conflicts. Real page pattern confirmed:
`/study/manual/hymns/{title-slug}`.

**Storage**: each type interned into its own shared table, same pattern as
the original `citationRefs` — `citationTalkRefs` (1,552 unique `[text,
resolvedTalkKey_or_null, href]`), `citationMagazineRefs` (302 unique
`[text, href]`), `citationHymnRefs` (181 unique hymn numbers),
`citationOtherRefs` (6,156 unique citation strings), `citationHymnLabels`
(the 341-hymn number→`[title, slug]` table), and `citationTypeLookup`
(talk → `{talk:[idx,...], magazine:[...], hymn:[...], other:[...]}`,
only non-empty keys present). `data.json` grew from 2.93MB to **4.22MB** —
the largest single jump so far, mostly the 6,156 Other Sources strings
(avg 126 chars each); a real, meaningful size cost, flagged plainly rather
than absorbed silently, but still well within reason for a bundled mobile
asset or a fetch-once-cache web payload.

**UI wiring**: `buildCitationsBlock()`'s `groups` array (previously just
Scriptures) now has all five entries — `talkOtherTalkCitations()`,
`talkMagazineCitations()`, `talkHymnCitations()`,
`talkOtherSourceCitations()`, each returning the same `{ref, href}` shape
`talkCitations()` already used, with `href` allowed to be `null` (Other
Sources; the 4 pre-1985 Hymns citations) — the rendering loop creates a
plain `<span>` instead of an `<a>` in that case, never a dead link. New
icons matching the mockup: a pulpit-with-microphone silhouette (Other
Talks), a music note (Hymns), a magazine/document shape (Church
Magazines), an info-circle (Other Sources) — all reusing the same palette
tokens as the Scriptures pill, so still zero new CSS custom properties
needed across the app's 4 palettes × 2 themes.

**A real scope-boundary bug caught and fixed during this build, worth
remembering**: `talkOtherTalkCitations()` initially referenced
`TALKS_BY_KEY` for the internal-talk-title lookup — but that index is
declared *inside* `initApp()`'s function scope, while this accessor (like
its `talkTopics()`/`talkKicker()`/`talkCitations()` siblings) lives at
true top level, *outside* `initApp()`, for direct testability from the
console. Referencing an inner-scoped variable from an outer-scoped
function threw `ReferenceError: TALKS_BY_KEY is not defined` at render
time — caught immediately via `read_console_messages` while testing live,
not left for later. Fixed with a direct `TALKS.find(t=>talkKey(t)===
resolvedKey)` instead (cheap enough — called a handful of times per
render against ~4,054 entries) rather than moving the function inside
`initApp()`, preserving the existing top-level-accessor pattern. **Any
future top-level `talkXxx()` accessor needs the same care** — don't
reach for `TALKS_BY_KEY`/other `initApp()`-local indexes from outside
that closure.

**Verified live** (fresh local server, `localStorage` cleared before
testing — a stale cached `data.json` bit this exact workflow during the
Scriptures-only build too, see above): real talks confirmed for every
pill type — Other Talks resolving to the correct in-app title +
`talkUrl()` link (Bednar → Uchtdorf's Apr 2019 talk), Hymns linking to
the real hymnal page (Oaks → "America the Beautiful"), the pre-1985
hymn-386 case rendering as unlinked plain text exactly as designed,
Other Sources rendering as plain unlinked `<span>`s with the real
citation text, a talk with four simultaneous pill types (Scriptures/
Other Talks/Hymns/Other Sources) rendering and toggling correctly with
full mutual exclusivity, and a talk with none of the new types correctly
showing only its Scriptures pill (no empty/ghost pills). `node --check`
clean on the extracted script throughout. Synced into the Android project
via `npx cap sync android`.

## ✅ Done: "Search Scriptures & Hymns" + filter-tile tightening
Idea 18's bullet 2 (Scripture/Hymn search) landed as a hybrid the user
proposed after reviewing three architecture options (a new filter
dimension, a dedicated reverse-lookup page, or extending the existing
search box) — a **second, separately-labeled search box on Home**, right
below "Search titles & summaries." Gets verse-level precision (unlike a
filter dimension, which would've had to coarsen to book-level given
19,719 unique scripture refs) without a new page, and avoids conflating
citation matches with title matches in one result stream (a labeled,
separate box, not a merged search).

**Design process, in order**: three architecture options discussed and
compared → user proposed the two-search-box hybrid, which was recognized
as strictly better than all three original options → before building,
asked whether the filter tile had room without shrinking further, which
led to a separate design pass on tightening it first (mockups built and
iterated in an Artifact, a 2-column layout tried and explicitly rejected
by the user, three other changes tried together and approved, then the
new search box mocked on top of the *tightened* tile to show the real net
cost) → all built for real together in one pass.

**What shipped**:
1. **Removed the "Recent/Favorites" ("mine") filter dimension from Home.**
   Real capability lost, named explicitly before removing it: combining a
   personal-collection scope with the *other* Home filters and the draw/
   list mechanics (e.g. "randomly draw from just my Favorites, filtered to
   Topic=Family") — the Favorites/Recently Viewed pages' own search+sort
   (added earlier) only browses the saved list, no random draw, no
   combining with other filters. Removed anyway per the user's call,
   trading that capability for the space. `filterState.mine`,
   `matchesDim()`'s mine branch, `valuesForDim()`'s mine branch,
   `DIM_CONFIG.mine`, `availableSets.mine`, and the HTML field block all
   removed cleanly — confirmed zero remaining references.
2. **Tightened label spacing** on every remaining filter field and both
   search boxes: margin under the label 7px → 3px, font-size 11px →
   10.5px, letter-spacing eased slightly (.1em → .08em).
3. **Merged "Reset filters" and the match-count** into one row (count on
   the left, Reset on the right) instead of two stacked blocks. Careful
   about scope: `.pool-count` is a shared class also used standalone by
   Recently Viewed/Favorites/My Notes/List-detail's own filter-actions
   rows — added a second class, `.pool-count-inline`, applied only to
   Home's usage, rather than changing the shared base rule; confirmed live
   that the other four pages' pool-count styling (centered, its own
   bottom margin) is untouched.
4. **Added the "Search Scriptures & Hymns" box** — same `search-input`/
   `search-clear` shared component the My Notes/My Lists search boxes
   already reuse, its own `filterState.citeQuery` string (parallel to the
   existing `query`), AND'd with every other active filter and with the
   title/kicker search, matched via a new `matchesCiteSearch()` — plain
   case-insensitive substring matching against `talkCitations()` (scripture
   refs) and `talkHymnCitations()` (hymn refs, e.g. "I Am a Child of God
   (Hymns, no. 301)") display text. Deliberately scoped to just these two
   citation types, not Other Talks/Church Magazines/Other Sources, matching
   how it was proposed. Wired into `currentPool()`, `poolExcept()`, and
   `resetBtn`'s handler/disabled-state logic alongside the existing search.

**A real 2-column layout was tried and rejected**: the first option
explored was lowering the filter grid's `620px` single-column breakpoint
so 2 columns would survive down to real phone widths (~375–430px) instead
of only ever applying above tablet width — mocked live with the two
longest real filter values in the app ("Quorum of the Twelve Apostles,"
"Saturday Evening (post-2020)") to stress-test truncation. The user
rejected it outright ("That's not going to work") without needing more
detail — logged here so a future session doesn't re-propose the same
2-column idea without knowing it was already tried and turned down.

**Verified live** (fresh local server, `localStorage` cleared before
testing): 5 filter fields confirmed (was 6), the new search box's label/
placeholder correct, both boxes reachable by their shared CSS classes
(confirmed via computed styles, not just visual inspection — a first pass
forgot to add the shared `.search-input`/`.search-clear` classes to the
new box's elements, since it wasn't `#querySearch` and had no class,
caught before it shipped by checking computed styles rather than assuming
the shared selector applied). "Alma 32" search verified against a real
"Show a List" result set (176 matches, spot-checked rows' actual
`talkCitations()` output contains "Alma 32:*"). "I Am a Child of God"
verified the same way against hymn citations (29 real matches, hymn 301).
Reset filters confirmed to clear both search boxes and re-disable itself.
The other four pages' `.pool-count` styling confirmed unaffected by the
new `.pool-count-inline` override. Tightened label spacing confirmed via
computed styles (10.5px / 3px). Full mobile-width (375px) screenshot
confirmed the merged Reset/count row and both search boxes rendering
cleanly on one screen with no crowding. Zero console errors throughout.
`node --check` clean. Synced into the Android project via `npx cap sync
android`.
