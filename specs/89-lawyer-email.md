# Draft email to a privacy lawyer (idea 89)

For Brad to edit and send. Attach `specs/89-privacy-children-draft.md` (and,
if the lawyer wants more detail, `specs/89-progress-sharing.md`). Fill in the
[brackets]. Not sent; kept out of `docs/`.

---

**Subject:** Question about children's privacy (COPPA) for a small free app — progress sharing between parents, teens and class leaders

Hello [Name],

I'm an individual developer of FindATalk, a free app and website (findatalk.com, on iOS, Android and the web) for finding and studying talks from the General Conference of The Church of Jesus Christ of Latter-day Saints. It is a fan-made tool, not produced by the Church. I'd like your advice on adding a feature that touches children's data before I build it. I'm not looking for a long engagement, mainly a short review and answers to the questions below.

**How the app works today**
- Accounts are optional; without one, nothing leaves the user's device. With an account (Google, Apple, or email/password via Firebase Authentication), favorites, reading history, notes, lists and a reading streak sync through Cloud Firestore.
- No ads, no analytics SDK, no tracking, no sale of data. Data is used only to run the app. Users can delete their account in the app.
- Users can create "shared lists" with family or friends. Members see the talks, who added each, and a display name the member chose.
- The app is a general-audience study app, not marketed to children, and is not in Apple's Kids Category.
- I recently added "study plans" (a reading plan with a finish date or pace). Plan progress is private; a shared plan shows the group only a combined total.

**What I'd like to add (the "oversight" feature)**
Opt-in sharing of a member's study-plan progress with one chosen person, framed as an "accountability buddy." The viewer would see only how many talks the person has finished, out of how many, and the last day they finished one. Never which talks, notes, reading times or streaks, and no rankings. The people involved would be:
- **Teens and adults (13+):** anyone sharing with another member of the same shared list, including a seminary teacher or church leader viewing students. The person being viewed grants and can revoke access at any time.
- **Children under 13:** only parent-initiated, with the parent as the only viewer, and no sharing with teachers or leaders. A parent would set up or approve the child's account from their own signed-in account.

**A fact you should know**
My own two children (under 13) had accounts with Family Link–approved Google sign-in for a short time. I've had them delete those accounts, so I'm treating the policy as accurate again for now.

**My questions**
1. For the parent-initiated under-13 flow: is a parent signing into their own account and approving the child's account enough for "verifiable parental consent" under the amended COPPA Rule, or should I use one of the FTC's listed methods (e.g., a small card transaction or signed form)?
2. Does sharing a child's finished count and last-read day with the parent create any additional obligations beyond parental access rights?
3. For 13+ users, is a self-declared age (a neutral birth month/year screen, storing only an "under 13 / 13 and over" flag, never the birthdate) a reasonable approach, and what should I do when a user is clearly a minor but 13 or older?
4. Seminary classes are mostly teenagers. Any issues with a teacher or leader seeing an opted-in teen's progress (state laws, mandatory-reporter or policy considerations, or Church program rules I should check)?
5. If I can't verify a child's age, how should I handle signed-in users who may be under 13 without telling me?
6. I plan to publish the attached privacy policy changes. Do they cover COPPA's notice requirements, and is anything missing? Does an EU/UK or state-law angle (e.g., age of digital consent, California's age-appropriate design code) apply to a small US-based app with no ads or tracking?
7. Is there anything in Apple's or Google Play's child-related rules (I'm staying out of Apple's Kids Category and not declaring children as a target audience on Play) I should double-check with you?

I'm happy to share the draft policy and the feature spec. Could you tell me roughly how you'd approach this and what it would cost?

Thank you,
Brad Christensen
[phone / email]
