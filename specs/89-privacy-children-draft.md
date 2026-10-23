# Draft: privacy policy changes for idea 89 (NOT live)

For Brad's review (and a lawyer's). Do **not** copy into `docs/privacy.html`
until the build in `specs/89-build-plan.md` is ready to ship — that page is
the public site and goes live on push. Not legal advice.

---

## Replace the current "Children's privacy" section with:

### Children's privacy

FindATalk is for everyone who studies General Conference, and it is not
designed for or marketed to young children. The app works fully without an
account, and in that case nothing about a child's use ever leaves their
device.

Children under 13 can have an account only when a parent or guardian sets
it up or approves it. When that happens, the account holds the same things
any account does (sign-in email, favorites, read marks, notes, lists,
streak), stored with Google Firebase, used only to run the app, and never
sold, used for advertising, or shared for anyone else's purposes. We use no
advertising, analytics or tracking tools.

A child's account is kept separate from the rest of the community:
children under 13 are not added to shared lists and are not visible to
teachers or leaders. A parent can choose to see how their child is doing in
a study plan (how many talks are finished and the last day one was
finished), and nothing more.

If you are a parent or guardian, you can ask us at any time to show you the
information we hold about your child, to stop us collecting more, or to
delete it, by emailing the address below. A signed-in parent can also
delete their child's data from the app. If we learn that a child under 13
has an account without a parent's approval, we will delete the account.

## Add to "Shared lists" (or a new section "Following progress"):

### Following someone's study progress (optional)

If you choose, you can let one other member of a shared list see how you are
doing in a study plan: how many talks you have finished, out of how many,
and the last day you finished one. You decide who, you can stop at any time,
and they see nothing else — not which talks, your notes, your reading times
or your streak. Other members of the list do not see whether you have
shared, and nobody is ranked or compared. Teachers and leaders see only the
people who have chosen to share with them.

## Add to "What is stored in your account":

…and, if you use study plans, your plan settings, which talks you have
finished as part of each plan, and finished-plan badges.

## Update the "Last updated" date when published.

---

## Store forms that must match this text

- **Google Play → App content → Target audience and content:** decide the
  declared age groups with Brad/lawyer (see build plan stage 0). Do not
  include under-13 unless the Families-policy requirements are met.
- **Google Play → Data safety:** account info (email), user content
  (lists, notes), app activity (reading progress); "shared": none for ads or
  analytics; "optional sharing between users" for plan progress. Mention
  parental controls / deletion.
- **App Store Connect → App Privacy:** same data types; "not used for
  tracking". Age rating questionnaire answered honestly (account-based
  sharing between users). Do **not** select the Kids Category.
- **App Store Connect → Privacy Policy URL:** unchanged, but must show the
  new text before the build is submitted.
