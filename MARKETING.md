# FindATalk — Zero-Budget Marketing Plan

Researched 2026-09-28. Everything here costs time, not money. Keep this file
at the repo root (not in `docs/`, which is public).

## The situation

- Free app, donations only, no ad budget. Google Play is live; the App Store
  is still pending.
- The audience is narrow and easy to find: Latter-day Saints (and the
  curious) who want to study General Conference but find Gospel Library a
  bit much. That audience gathers in a small number of places (wards,
  seminary/institute, Come, Follow Me groups, a few subreddits and Facebook
  groups, a handful of podcasts and news sites). A small, targeted audience
  is the best case for free marketing.
- **Timing:** October 2026 General Conference is **Saturday–Sunday, Oct 3–4**.
  Interest in conference talks peaks the week before and the few weeks after,
  and again every April. Plan around those two peaks each year.
- Church News is already running "A talk a day: Preparing for October 2026
  general conference", which is exactly FindATalk's pitch. That gives you a
  timely reason to reach out.

## Guardrail: stay clearly unofficial

The site footer already says "FindATalk is a fan-made tool, not produced by
the Church," and links to the Church's own General Conference library. Keep
that. Also put the same line in the Play/App Store descriptions, and never
use Church logos or lookalike styling in promotional images or posts.

## Ranked plan

### 1. Conference week push (this week, Oct 3–4, and every April/October)
- Post once in each relevant community, framed as help rather than an ad:
  *"I built a free app that picks a random conference talk each day, no
  study plan needed. Here's how to find every talk that quotes a given
  scripture..."* Include one screenshot or share card.
- The day after conference, post a "the new talks are in" note as soon as
  `data.json` has the October 2026 talks. Being first with the new talks
  searchable is a real hook, and data updates ship live without a store build.
- Suggest a practical use: "a talk a day until April conference".

### 2. Word of mouth through the share features (ongoing, highest leverage)
The app already has talk, badge, streak, and "Your FindATalk" share cards.
Each shared card is free advertising, so make sure each one carries
`findatalk.com` and the store badge, and nudge people to share at moments
of accomplishment (a streak milestone, a finished list). Ask friends and
family who use it to share one talk they liked. People in this audience
share talks with a spouse, class, or friend as part of normal church life.

### 3. Ward, stake, seminary, and institute teachers
These are the people who hand talks to others every week: Sunday School,
Relief Society, Elders Quorum, Youth, seminary, and institute teachers, and
speakers preparing a sacrament meeting talk. The Topic and scripture
(reverse citation) search is most useful to them.
- Write a one-page "How to find a talk for your lesson in 30 seconds" guide
  (a web page on findatalk.com, printable) and share it in teacher groups.
- Mention it in your own ward/stake, and ask friends in other stakes to do
  the same. Don't use official ward channels to promote it; personal
  recommendations are fine.

### 4. Online communities (free; follow each group's rules)
- Reddit: r/latterdaysaints (check the sidebar; many faith subs limit
  self-promotion to specific threads or require mod approval, so message the
  mods first). Post as the builder with a genuine story, then keep taking
  part in the community rather than posting and leaving.
- Facebook groups: Come, Follow Me study groups, seminary/institute teacher
  groups, and Relief Society/EQ lesson-sharing groups (these are large and
  active). Ask the admin before posting.
- Instagram/TikTok/YouTube Shorts: short screen recordings ("the angels
  pick my talk for the drive to work", "find every talk that quotes Alma
  32") work well. One a week, timed around conference.
- The founder story in `MISSION.md` (an easy way to hear from prophets on
  the drive to work) is the most shareable thing you have. Lead with it.

### 5. Free press and podcasts
- Pitch short, personal emails to LDS Living, Church News/Deseret News
  (faith section), Meridian Magazine, LDS365, and the Daily Universe (BYU),
  and to Come, Follow Me and conference-themed podcasts. Angle: *"a local
  member built a free app that removes the barrier to a daily talk,"* tied
  to the conference season or the "talk a day" theme.
- LDS365 publishes "ways to watch/study conference" roundups. Ask to be
  included in the next one.
- Offer podcast hosts something useful for their listeners (for example,
  "every talk that cites this week's Come, Follow Me chapter").

### 6. Store listing optimization (free, compounding)
- Google Play: put the words people search for in the title and short
  description, such as "General Conference Talks, Daily Study". Use
  screenshots with a caption on each, and reply to every review.
- The in-app rating ask (after 25 talks) is already built; more ratings
  help the app rank in store search.
- When iOS is approved, flip `APP_STORE_URL` and announce "now on iPhone"
  as a second launch moment.

### 7. Website SEO (small code changes, long tail)
- ✅ Done 2026-09-28: the page title is now "FindATalk — Daily & Searchable
  General Conference Talks" with a matching meta description and
  link-preview text (it used to be "Pick a Talk — General Conference").
- Switch `twitter:card` to `summary_large_image` and use a wide (1200×630)
  `og:image` so shared links preview better.
- Later: static, searchable pages (e.g., "General Conference talks on
  faith", "talks citing Alma 32") would let Google send search traffic.
  This is bigger work; weigh it against the single-page architecture.
- Submit findatalk.com to Google Search Console (free) to see what people
  search for.

### 8. Free programs to apply to
- **Google Ad Grants** gives registered nonprofits free search ads, but it
  requires 501(c)(3) status. Only worth it if you ever form a nonprofit.
- Product Hunt / Hacker News "Show HN": mostly a tech audience, so low fit.
  Low priority.

## What to measure
Keep it aggregate-only, like the ledger Stats tab: Play Console installs by
source (it shows store search vs. referrals), website visits (Search Console),
and a rough count per week. Use UTM-style `?ref=reddit`/`?ref=fb` links on
findatalk.com to see which channels actually work, then double down on
those.

## Suggested first week
1. Add the footer's "fan-made, not produced by the Church" line to the store listing.
2. ✅ Page title/description fixed.
3. Draft one Reddit post, one Facebook group post, and one short video.
   Ask mods and admins for permission now.
4. Email 3–5 pitches (LDS Living, Church News, LDS365, two podcasts).
5. Load October 2026 talks right after conference and post "new talks are in."
