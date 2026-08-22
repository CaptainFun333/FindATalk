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

## ⏭️ Next task (optional): keep expanding backward
The next gap going further back is **April 1996 and earlier**. Going
past October 1974 backward, or filling 1975–1986 / 1988–1994 (this
project has never touched those years at all), is a much bigger
undertaking than any single batch so far and hasn't been scoped. Note:
**if you go earlier than March 1995, you'll need fresh First Presidency
research** (Hinckley became president March 12 1995, succeeding Ezra Taft
Benson who died May 30 1994 — Benson's own First Presidency and its
transition to Hinckley haven't been researched yet in this project).
Remember to extend Seventy/auxiliary-presidency role work too — don't
leave new talks role-untagged — and re-run the "sandwiched gap" + full
integrity validation passes described above afterward.

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
