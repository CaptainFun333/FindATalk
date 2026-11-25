# Idea 91 — Search Citations (open the citation search to every source)

Build spec. Mockup: https://claude.ai/artifact/8FqfYazGThHn9y6iLFN5PN (version 3).
Brainstorm only until a build session picks this up; line numbers are from `main`
at the time of writing — re-find them by function name.

## What it is

The Home box "Search Scriptures & Hymns" becomes **"Search Citations"** with the
hint text **"Scripture, hymn, book, author, or talk"**. It keeps finding scriptures
and hymns exactly as today, and now also finds footnoted **Other Sources** (books,
authors, newspapers…), **Other Talks** (by title and speaker), and **Church
Magazines**. Same box, same "N matching" badge, same results look — wider reach.

## Decisions (all made by Brad)

- Name: "Search Citations". Hint (placeholder): "Scripture, hymn, book, author, or talk".
- Cited talks are searchable by title and speaker.
- **No suggestion chips** (tried in mockup v2, dropped). The hint line does the teaching.
- Only footnoted sources can be found. A quote in the talk body without a footnote
  needs full-text search (idea 5) — out of scope.

## Code anchors (`docs/index.html`)

- Box markup: `#citeQueryLabel` / `#citeQuerySearch` (~line 3542). Change label text and
  placeholder. Placeholder was "e.g. Alma 32, I Am a Child of God…" — use the new hint
  (keep it short enough to fit a phone-width input without truncating; if it clips,
  fall back to "Scripture, hymn, book, author, talk").
- `citeSearchMatchedCitations(talk, rawQuery)` (~10489) returns `{scripture, hymn}`.
  This is the single source of truth: `matchesCiteSearch()` (the filter) and
  `appendCiteSearchMatchBadge()` (the badge, ~13131) both call it, so they can't disagree.
  **Keep that property.**
- Per-talk citation lists, all already produced as `{ref, href, talkHref?}` chip objects:
  `talkCitations`, `talkHymnCitations`, `talkOtherTalkCitations`,
  `talkMagazineCitations`, `talkOtherSourceCitations` (~6719–6815).
- Data (already in `data.json`, no data change needed): `citationOtherRefs` (strings,
  ~6.2k), `citationTalkRefs` (`[text, resolvedKey, href]`, ~1.6k), `citationMagazineRefs`
  (`[text, href]`, ~300), `citationTypeLookup[talkKey] = {other, talk, magazine, hymn}`
  (index arrays).
- `appendCiteSearchMatchBadge` currently builds `matches = [...scripture, ...hymn]`.
- Comments mentioning the old name: ~6818, 10457, 13114, 13120, 19488. Update them.

## Design

### Matching

Extend `citeSearchMatchedCitations` to return
`{scripture, hymn, talk, magazine, other}`. Order of work, per query:

1. If `parseCiteQuery(q)` recognises a book reference → **unchanged**: structural match,
   scriptures only. (Keeps the "Eph." vs "Zeph." protection described in the existing
   comment.) The other three lists are empty.
2. Otherwise → text match across **everything**: scripture display text, hymn text,
   plus the three new lists.

For the text match, normalise **both sides** with one shared helper
`normalizeCiteText(s)` and compare with whole-word logic:

- lowercase;
- strip accents (`NFD` + remove `̀–ͯ`) — "Les Miserables" finds "Les Misérables";
- treat curly and straight quotes the same, and drop apostrophes/quotes — "Alice's" finds "Alice’s";
- drop periods and collapse spaces inside initials — "C.S. Lewis" and "CS Lewis" find "C. S. Lewis";
  simplest: remove all `.` and `’'"“”`, then collapse whitespace;
- collapse en/em dashes and other punctuation to a space.

**Whole words, not raw substrings.** Match the normalised query as a sequence of whole
words inside the normalised citation: pad both with spaces and test
`(' ' + hay + ' ').includes(' ' + needle + ' ')`. This is what stops "Alice" matching
inside other words, and "Lincoln" matching "Lincolnshire". Known limit: a first name
alone ("Alice") still matches "Mary Alice Holland". That is accepted — the matching
footnote is always shown highlighted in the badge panel so the reason is visible.

Do **not** switch the existing scripture/hymn fallback to whole-word without checking:
hymn titles are typed partially ("I Am a Child"). For scriptures/hymns keep the current
lowercase substring match **and** also accept the normalised match (additive only —
never find fewer than today). For the three new lists use the normalised whole-word
match; for a multi-word query, require the whole phrase in order (same as a substring
today). Single short queries: ignore queries under 3 characters for the new lists to
avoid matching every footnote that contains "of".

Performance: ~8k strings × 4,054 talks is fine only if each talk's list is small, which
it is. Precompute the normalised form **lazily and cache it per ref index**
(`Map` keyed by list+index) rather than re-normalising every keystroke. The existing
`input` handler already re-filters on each keystroke; measure on a mid-range phone and,
if it stutters, add a 150 ms debounce to that handler.

### Cited talks (type `talk`)

`talkOtherTalkCitations` swaps the footnote text for the real talk's title when the
target is in the dataset. Search must match **any of**: the raw footnote text
(`CITATION_TALK_REFS[i][0]`), the resolved talk's title, and the resolved talk's
speaker name. That is what makes both "Overcome the World and Find Rest" and
"Russell M. Nelson" work. Build a combined haystack per entry; keep the chip object
returned to the badge identical to what `talkOtherTalkCitations` already produces
(including `resolvedTalk` so opening it still credits a read).

Mockup measure: "Overcome the World and Find Rest" is cited by 33 distinct talks.

### Result display

- Same "N matching" badge; `N` = total matches across all five lists. Update
  `appendCiteSearchMatchBadge` to use `[...scripture, ...hymn, ...talk, ...magazine, ...other]`.
- Each chip in the panel gets a small type label ("Other source", "Talk", "Magazine";
  scriptures and hymns keep their current look, no label needed). See the mockup's
  `.chip .ty` styling — small caps brass label before the text. Build it from existing
  chip classes; no new colour tokens.
- Matching text highlighted with the existing `mark` style in the chip text. Highlight on
  the **normalised match range** mapped back to the original string — if mapping back is
  fiddly, highlight by matching the original text case/accent-insensitively word-for-word;
  if no highlight can be found, show the chip unhighlighted rather than failing.
- Chips that already have links (talks, magazines) keep the existing destination-choice
  popup behaviour (`openCiteDestModal`) and read credit. "Other sources" have no link and
  stay plain text (`row-cite-plain`).
- Result counts in the pool line ("N talks") already come from the filter; no change.

### Not changing

- No suggestion chips, no new filter, no changes to `data.json`, no changes to CFM or
  other pages (`filterState.citeQuery` is Home-only, as today).
- Do not add the new types to `matchesSubsetSearch` (Favorites/Lists/Notes search).

## Edge cases

- Empty/whitespace query: unchanged (no filtering).
- Book-shaped query that is also a book title ("Job", "Mosiah", "Esther"): structural
  path wins, as today. A user wanting the book "Job" gets scripture hits only. Accept.
- Hymn queries ("Because I Have Been Given Much"): still found via the hymn text; make
  sure the new whole-word logic never *removes* a talk the old substring search found.
- Talks with no citations at all: no matches, as today.
- Accented/curly characters in data: normalisation must run on the data too (not only the
  query) — check "Gérald Caussé" style names for the speaker part.
- Very common words ("the", "of"): the 3-character floor plus whole-word match keeps
  these from matching everything; also cap highlighted chips per talk in the panel at a
  sensible number (say 8) with "+N more" if one talk matches dozens of footnotes.
- Query typed with a straight apostrophe vs footnote curly: covered by normalisation
  (mockup case "Alice's Adventures in Wonderland" → 6 talks).

## Reference results to test against (from the real data)

| Query | Talks |
|---|---|
| Victor Hugo | 4 |
| The Screwtape Letters | 3 |
| Alice's Adventures in Wonderland | 6 |
| Overcome the World and Find Rest | 33 |
| C. S. Lewis | ~20 |
| Shakespeare | 15 |
| Lincoln | 11 |
| Dickens | 8 |
| Emerson | 8 |

Re-run these after the build; counts may shift slightly if `data.json` has been updated.
"Les Miserables", "C.S. Lewis" and "Alice's Adventures" matched **0** before the cleanup.

## Regression checklist

- "Alma 32", "Alma 32:3", "D&C 1:38", "1 Ne. 3:7": identical talk counts to before.
- "Eph." does not pull in Zephaniah.
- A partial hymn title still finds its talks.
- Every query that found a talk before still finds it (additive only) — spot-check with a
  script comparing old vs new match sets over a list of ~50 queries.
- The "N matching" badge count equals the number of chips in its panel, and the filter
  and badge agree for every talk (single source of truth).
- Opening a cited-talk chip still credits a read (`resolvedTalk`).
- Clear (×), Reset filters, and the Home→other-page→back state behave as before.
- Light, dark, and the other palettes; phone width and desktop; screen-reader label reads
  "Search Citations".
- Android/iOS: placeholder not truncated on a small phone.

## Release notes / paperwork

- **Ships with:** `docs/index.html` only. The website gets it immediately; the native apps
  need a new build before existing installs see it (call that out in the changelog bullet,
  like other `index.html` entries).
- `CHANGELOG.md` (same commit), under `### Changed`: plain language, e.g. "The scripture
  search box is now Search Citations — find a book, an author, or a talk someone cited,
  not just scriptures and hymns (needs a new app build)."
- `IDEAS.md`: add idea 91 (open → in progress while building; done when merged). Repo
  `IDEAS.md` does not list 91 yet.
- `PROJECT_HANDOFF.md`: update the mentions of "Search Scriptures & Hymns" and describe the
  new matching rules (normalisation, whole-word, five lists).
- `DECISIONS.md`: one line — suggestion chips were tried in the mockup and dropped on
  purpose; cited talks are included; first-name-only matches (e.g. "Alice") are accepted
  because the matching footnote is always shown.
- `ENGINEERING_NOTES.md`: only if something surprising turns up (e.g. highlight mapping
  through normalisation).
- Tour/onboarding text: grep `docs/index.html` for any tour card that names the old box
  and update it. `docs/privacy.html` needs nothing for this idea.

## Build order

1. `normalizeCiteText` + lazy cache; unit-check against the cleanup table in the mockup.
2. Extend `citeSearchMatchedCitations` to five lists; keep `matchesCiteSearch` as the boolean wrapper.
3. Update `appendCiteSearchMatchBadge` (union, type labels, highlight, "+N more").
4. Rename label/placeholder; update the comments.
5. Run the reference queries and the old-vs-new comparison; test on a phone-width viewport.
6. Paperwork above, one commit.
