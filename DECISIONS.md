# Decisions

A short, running log of the *why* behind choices that aren't obvious from the
code or the changelog — one or two lines each, newest first. This is not a
changelog (see `CHANGELOG.md` for user-facing changes) and not the full
architecture history (see `PROJECT_HANDOFF.md`) — it's the middle layer:
enough context that a future session (or future you) doesn't re-litigate a
call that was already made on purpose.

See `CLAUDE.md` for when to add to this file.

---

- **2026-09-19** — Donation-ask prompts (reading-count milestones + New
  Year nudge) were built and committed, but held locally rather than pushed
  to `main`, until a version past 1.7.1 ships — so the asks don't land on
  users mid-cycle of an already-shipped version's bug fixes.
- **2026-09-18** — The hidden badge/palette unlocked by the star easter egg
  is deliberately never named in changelog, store listing, or email copy —
  keeping it vague is the point; naming it would spoil the discovery.
- **2026-09-18** — Monetization model is "free forever" with optional
  donations, not a paywall or subscription — a native IAP tip jar was added
  as one more way to give, not a gate on features.
- **2026-09-18** — iOS 1.7 was fully pre-flighted and version-bumped, but
  the actual App Store submission and IAP review request were deliberately
  left for a later, deliberate step rather than auto-submitted.
- **Earlier** — Domain migration: Phase 1 (web app live on FindATalk.com)
  shipped; Phase 2 (transferring the registrar itself to Bluehost) was
  cancelled — staying on GoDaddy for the registrar going forward.
