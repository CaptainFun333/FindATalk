# Feature ideas

The running brainstorm list for FindATalk — every feature idea considered
so far and where it stands. This is a working list, not a roadmap or a
promise of what ships next. Grouped by status, most active first:
**In progress, Open, Done, Disregarded, Obsolete**.

---

## In progress

44. Siri/Google Assistant shortcuts — in progress (iOS done; Android/Google Assistant side still open, more constrained)
86. Fix a member's streak from the ledger — in progress (built 2026-10-04: private Admin tab at `ledger.html#admin`, look up an account by email, see missed days, mark them forgiven; waiting on a Firebase deploy)
87. General Conference weekend card — in progress (built 2026-10-04 on branch `conference-weekend`, not yet on main: on conference Saturday and Sunday in April and October the Talk of the Day gives way to "Are you participating in General Conference today?"; Yes counts toward the streak, No draws a random talk, no Talk of the Day is assigned those days; widgets, daily reminder, streak warning and the calendar all follow; needs new builds and a Firebase deploy for the ledger calendar)
68. Global "impact" counter — ongoing (data collection live. The ledger Stats tab now shows a trial "Loved by the community" block: most read, favorited and added-to-list talk, top speaker, topic and scripture chapter with "seek out" versions comparing reading to library share, and total study days. All counted by distinct signed-in members and hidden below 5 people. No in-app display yet)

## Open

5. **Full-text/semantic search inside talk bodies** — open, heavy lift
6. **Daily/weekly/monthly active user tracking** — open
13. **Related-topics suggestions** — open
17. **Expand topic alias list** — open by design (ongoing, never marked done)
21. **Citation "playlist"** — open
29. **Weight equidistant-speaker ties by seniority** — open
38. **Talk playlist for a My List** — open
47. **Different languages** — open, scoping done
52. **"Conference Radio" continuous playback** — open, exploratory
53. **Pre-1971 talks as an advanced filter** — open, exploratory
57. **Live/collaborative list sharing** — open, exploratory
64. **Larger-text/accessibility view** — open
66. **Custom Firebase Auth domain branding** — open, low priority
83. **Shorter list-share links** — open (analysis 2026-10-01; recommended: base-62 packed talk positions, no commas, ~half the length, old links still work; optional cap on name length; a Firestore short link like findatalk.com/l/abc123 is the only way to get tiny links but adds a backend + privacy disclosure)
84. **Anonymous per-day Talk of the Day read counter** — open, queued for the release after 1.7.7 (lets the ledger calendar count everyone who read the day's featured talk, not only signed-in accounts; app change, needs new builds; counts start the day it ships)

## Done

3. ~~Light/Dark mode~~ — ✅ done
4. ~~"See next 10" pagination on Show a List~~ — ✅ done
7. ~~Preset color skins + custom photo background~~ — ✅ done
8. ~~Per-talk notes + My Notes page~~ — ✅ done
9. ~~"Session" filter~~ — ✅ done
10. ~~Reordered home-page filters + moved search box~~ — ✅ done
11. ~~Search + sort added to My Notes/My Lists~~ — ✅ done
12. ~~Topic search "did you mean" / synonym redirect~~ — ✅ done
14. ~~Move Export/Import Backup to bottom of My Lists~~ — ✅ done
15. ~~Removed filters from personal-collection pages~~ — ✅ done
16. ~~"Select First 10" + "Select All" on Show a List~~ — ✅ done
18. ~~Interact with scripture citations in each talk~~ — ✅ done
19. ~~"Search Scriptures & Hymns" box~~ — ✅ done
20. ~~Reverse scripture lookup~~ — ✅ done
22. ~~Swipe between main nav tabs~~ — ✅ done
23. ~~Browse previous Talks of the Day via calendar~~ — ✅ done
24. ~~"Come, Follow Me" tie-in~~ — ✅ done
25. ~~Synonym/query expansion for title search~~ — ✅ done
27. ~~Word-form/stemming matches for title search~~ — ✅ done
28. ~~"Did you mean" spelling correction (Topic/Speaker)~~ — ✅ done
30. ~~Swipe to change months on calendar popouts~~ — ✅ done
31. ~~Expand citation-count badge on CFM page~~ — ✅ done
32. ~~Clean up footer explainer text~~ — ✅ done
33. ~~"View in talk" — jump to citation's paragraph~~ — ✅ done (now a destination-choice popup)
34. ~~Show streak badge to brand-new users~~ — ✅ done
35. ~~"Show me around" onboarding tutorial~~ — ✅ done
36. ~~Prefilled share messages with branding~~ — ✅ done
37. ~~Animate swipe navigation between pages~~ — ✅ done
40. ~~FindATalk.com domain migration + deep linking~~ — ✅ done
41. ~~Confirmation when creating a list~~ — ✅ done
45. ~~Milestones, Notifications & Sharing (app-only)~~ — ✅ done
46. ~~Notification tap routing to relevant content~~ — ✅ done
48. ~~Rename a list from My Lists~~ — ✅ done
49. ~~Read/Unread filter~~ — ✅ done
51. ~~CFM calendar Monday-first columns~~ — ✅ done
54. ~~Hidden homepage easter-egg feature~~ — ✅ done
55. ~~Visit count ("×N") + Most Read lookup~~ — ✅ done
56. ~~Tighten Home-page footer text, round 2~~ — ✅ done
58. ~~My Lists row layout on phone~~ — ✅ done (Option A; further tightening still possible)
59. ~~Android back button navigation~~ — ✅ done
60. ~~Edge-swipe-to-go-back on iOS~~ — ✅ done
61. ~~User accounts with cross-device sync~~ — ✅ done
62. ~~Show when today's streak is done~~ — ✅ done
63. ~~Show only matching citations in search results~~ — ✅ done
65. ~~Rename Home's "Find Another"/"Show a List" buttons~~ — ✅ done
67. ~~Donation/support prompt~~ — ✅ done (checkout, native IAP, reading-milestone ask, and a Dec 18–31 Christmas ask shipped in 1.7.2)
69. ~~Data controls for accounts (conflicts, clearing data)~~ — ✅ done
70. ~~Streak "salvage" for one missed day~~ — ✅ done (read 2 talks, plus a reminder that day — 1.7.2; once-a-week cap removed 2026-10-04)
71. ~~Share a talk as a generated image card~~ — ✅ done (talk, badge, Supporter, and streak cards plus an editable message preview — 1.7.2)
72. ~~Make the number of talks read visible~~ — ✅ done (delivered inside "Your FindATalk")
73. ~~"Your FindATalk" stats window~~ — ✅ done (six numbers; the Home streak pill opens it)
74. ~~Total counts on Favorites/My Lists~~ — ✅ done (My Lists only; Favorites already shows a count)
75. ~~Split Settings — trophy button for Badges/Stats/Support~~ — ✅ done
76. ~~Rating prompt after 25 talks~~ — ✅ done (app only; store rating sheet after a pre-ask, 90-day gap, 3-ask cap; needs a new build)
77. ~~App Store / Google Play badges on findatalk.com~~ — ✅ done (Google Play live; App Store shows "coming soon" until approved)
78. ~~"Oldest First" sort~~ — ✅ done (Show a List gets a third button; Favorites/My Notes/a List's page/Recently Viewed get two flippable buttons covering both the activity order and the talk's own conference date)
79. ~~Conference filter as a date range~~ — ✅ done ("Select a range" on Home and Come, Follow Me: tap a start and an end, everything between gets checked)
80. ~~"Your Journey" — talks read and days studied, by year~~ — ✅ done (‹ year › switcher; hidden until Dec 31, 2026; read dates recorded + estimated backfill; other candidate stats not chosen)
81. ~~Yearly "Check on your journey in [YEAR]" reveal~~ — ✅ done (Dec 31–Jan 14, 14+ days studied, once a year, with a "Share my year" card)
82. ~~Reading pace in Your FindATalk~~ — ✅ done (tap Reads & Rereads: About N a day / week / month, On pace for N a year; opens on the friendliest step; after 14 days)
85. ~~Tap your most-read talk in Your FindATalk to open it~~ — ✅ done (closes the window, lands on the talk's ticket with a pulse, Previous returns you; community lists under idea 68 should follow the same rule when built)

## Disregarded

1. ~~Community leaderboard (Most Read/Most Favorited)~~ — 🚫 disregarded
2. ~~Living/Deceased speaker filter~~ — 🚫 disregarded
26. ~~Accordion for Home's filter panel~~ — 🚫 disregarded
50. ~~Combine Conference + Session into one filter~~ — 🚫 disregarded (a side-by-side layout alternative was built instead)

## Obsolete

39. ~~Single-item shares beyond talks~~ — obsolete, merged into 45
42. ~~App-only features/perks strategy~~ — obsolete, remaining pieces spun into 43/44
43. ~~Richer push notifications~~ — obsolete, merged into 45

---

**In progress:** 44, 68, 86, 87
**Open:** 5, 6, 13, 17, 21, 29, 38, 47, 52, 53, 57, 64, 66, 83, 84
**Done:** 3, 4, 7, 8, 9, 10, 11, 12, 14, 15, 16, 18, 19, 20, 22, 23, 24, 25, 27, 28, 30, 31, 32, 33, 34, 35, 36, 37, 40, 41, 45, 46, 48, 49, 51, 54, 55, 56, 58, 59, 60, 61, 62, 63, 65, 67, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 85
**Disregarded:** 1, 2, 26, 50
**Obsolete:** 39, 42, 43
