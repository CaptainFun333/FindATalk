const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const Stripe = require('stripe');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { SignedDataVerifier, Environment } = require('@apple/app-store-server-library');
const { makeTotdPicker, talkKey, isConferenceDay } = require('./totd');
const { isDay, recomputeStreak } = require('./streak');

initializeApp();
const firestore = getFirestore();

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

// Play Console -> Monetization setup -> "Base64-encoded RSA public key" —
// the one credential Android purchase verification needs. Deliberately
// not a full Google Cloud service account / Play Developer API
// integration (see PROJECT_HANDOFF.md) — this lets verifyIAPPurchase
// verify a purchase's signature completely offline, same as the iOS side.
const playRsaPublicKey = defineSecret('PLAY_RSA_PUBLIC_KEY');

const ONE_YEAR_MS = 365 * 24 * 60 * 60 * 1000;

// Recomputes the whole donations/{uid} doc from scratch (years ∪ this
// donation's year, activeUntil = eventTime + 365 days, lastDonationAt =
// eventTime) rather than incrementing anything — see docs/index.html's
// donationState comment. That makes redelivery of the same Stripe event
// naturally idempotent: writing the same inputs twice produces the same
// doc, no separate event-dedup bookkeeping needed.
async function recordDonation(uid, eventTimeMs) {
  const ref = firestore.collection('donations').doc(uid);
  const existing = await ref.get();
  const existingYears = (existing.exists && Array.isArray(existing.data().years))
    ? existing.data().years
    : [];
  const donationYear = new Date(eventTimeMs).getUTCFullYear();
  const years = [...new Set([...existingYears, donationYear])].sort((a, b) => a - b);

  await ref.set({
    years,
    activeUntil: eventTimeMs + ONE_YEAR_MS,
    lastDonationAt: eventTimeMs,
  });
}

async function handleCheckoutSessionCompleted(event) {
  const session = event.data.object;
  const uid = session.client_reference_id;
  if (!uid) {
    // Payment Links only attach client_reference_id when the donor was
    // signed in (docs/index.html:5787) — nothing to attribute this to.
    logger.info(`checkout.session.completed ${event.id} has no client_reference_id, skipping`);
    return;
  }

  const eventTimeMs = event.created * 1000;
  await recordDonation(uid, eventTimeMs);

  // Annual tier is a subscription — its yearly renewals arrive as
  // invoice.paid with no client_reference_id, only customer/subscription
  // IDs. Stash the uid now so a future renewal can find its way back here.
  if (session.mode === 'subscription' && session.subscription) {
    await firestore.collection('stripeSubscriptions').doc(session.subscription).set({ uid });
  }
}

async function handleInvoicePaid(event) {
  const invoice = event.data.object;
  // The initial subscription invoice is already covered by
  // checkout.session.completed above — only act on actual renewals.
  if (invoice.billing_reason !== 'subscription_cycle' || !invoice.subscription) {
    return;
  }

  const mapping = await firestore.collection('stripeSubscriptions').doc(invoice.subscription).get();
  if (!mapping.exists) {
    logger.warn(`invoice.paid ${event.id} for subscription ${invoice.subscription} has no known uid, skipping`);
    return;
  }

  await recordDonation(mapping.data().uid, event.created * 1000);
}

exports.stripeWebhook = onRequest(
  // Reached via a Firebase Hosting rewrite (see firebase.json), not
  // invoked directly — this project's org policy (Domain Restricted
  // Sharing) blocks granting `allUsers` invoker access directly, so
  // `invoker: 'public'` can't be used here. Hosting's own service agent
  // is granted invoker access automatically instead.
  { secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    const stripe = new Stripe(stripeSecretKey.value());

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        req.headers['stripe-signature'],
        stripeWebhookSecret.value()
      );
    } catch (err) {
      logger.warn('Stripe signature verification failed', err);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    if (event.type === 'checkout.session.completed') {
      await handleCheckoutSessionCompleted(event);
    } else if (event.type === 'invoice.paid') {
      await handleInvoicePaid(event);
    } else {
      logger.info(`Ignoring unhandled Stripe event type: ${event.type}`);
    }

    res.status(200).send();
  }
);

// --- Native IAP tip jar (StoreKit 2 / Play Billing) ---
//
// Verifies a purchase's own signature offline instead of calling Apple's
// App Store Server API or Google's Play Developer API — neither needs an
// App Store Connect API key or a Google Cloud service account this way,
// only a bundled Apple root cert (functions/certs/AppleRootCA-G3.cer,
// downloaded from https://www.apple.com/certificateauthority/) and the
// PLAY_RSA_PUBLIC_KEY secret above. See PROJECT_HANDOFF.md.
//
// Once verified, a tip writes the SAME donations/{uid} doc recordDonation
// already writes for Stripe — a native tip and a web donation both count
// toward the same Supporter streak for a signed-in user, and no new
// Firestore rule is needed (donations/{uid} is already client-read /
// Admin-write-only).

// Product ids as actually created in App Store Connect/Play Console — not
// renameable after creation, so these have to match exactly what's there.
// Only the 5 one-time tips; the matching 5 annual-subscription products
// also created there are not yet wired up (different StoreKit/Play Billing
// verification path — see PROJECT_HANDOFF.md).
// iOS and Android use DIFFERENT real ids for the "same" 5 tiers (see
// TIP_TIERS's own comment in docs/index.html for why) — this allowlist
// has to include both platforms' ids together, not just one set.
const TIP_PRODUCT_IDS = [
  '2OneTime26', '3OneTime26', '5OneTime26', '10OneTime26', '25OneTime26', // iOS
  '2onetime26', '3onetime26', '5onetime26', '10onetime26', '25onetime26' // Android — Play Console requires lowercase ids
];

const IOS_BUNDLE_ID = 'com.captainfun333.findatalk';
// App Store Connect -> App Information -> Apple ID (the numeric id, not
// the bundle id, and not an Apple ID login/email — those are a different
// thing despite the confusingly identical name). Required by Apple's
// library only for verifying Production transactions specifically;
// Sandbox and Xcode-local-testing transactions verify without it.
const IOS_APP_APPLE_ID = 6807210681;

const appleRootCAs = [
  fs.readFileSync(path.join(__dirname, 'certs', 'AppleRootCA-G3.cer')),
];

// Real devices/App Review traffic can be Sandbox or Production, and the
// Simulator's StoreKit Testing feature declares itself as a third,
// separate "Xcode" environment — Apple designs local testing to sign
// against the same real root CA chain specifically so this kind of code
// doesn't need to special-case it, but verifyAndDecodeTransaction still
// hard-rejects a transaction whose own declared environment doesn't match
// the verifier instance's, so one instance per possible environment is
// required (see @apple/app-store-server-library's jws_verification.js).
function buildIOSVerifiers() {
  const environments = [Environment.XCODE, Environment.SANDBOX];
  if (IOS_APP_APPLE_ID) environments.push(Environment.PRODUCTION);
  return environments.map((environment) => new SignedDataVerifier(
    appleRootCAs,
    false, // enableOnlineChecks — OCSP revocation checking needs network; skip it
    environment,
    IOS_BUNDLE_ID,
    environment === Environment.PRODUCTION ? IOS_APP_APPLE_ID : undefined
  ));
}

async function verifyIOSTransaction(jwsRepresentation) {
  let lastError;
  for (const verifier of buildIOSVerifiers()) {
    try {
      return await verifier.verifyAndDecodeTransaction(jwsRepresentation);
    } catch (err) {
      lastError = err;
    }
  }
  throw lastError;
}

// Play Console's license key is the Base64 form of an X.509
// SubjectPublicKeyInfo (the same shape crypto.createPublicKey expects as
// 'spki'/'der'), and Play signs each purchase's originalJson with
// SHA1withRSA — this mirrors exactly what Play's own docs describe app
// developers doing to verify a purchase locally, just run server-side
// instead of on-device.
function verifyAndroidPurchase(originalJson, signature, publicKeyBase64) {
  const publicKey = crypto.createPublicKey({
    key: Buffer.from(publicKeyBase64, 'base64'),
    format: 'der',
    type: 'spki',
  });
  const verifier = crypto.createVerify('RSA-SHA1');
  verifier.update(originalJson, 'utf8');
  verifier.end();
  return verifier.verify(publicKey, signature, 'base64');
}

exports.verifyIAPPurchase = onCall(
  { secrets: [playRsaPublicKey] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Must be signed in to record a tip.');
    }

    const { platform, productId } = request.data || {};
    if (!TIP_PRODUCT_IDS.includes(productId)) {
      throw new HttpsError('invalid-argument', `Unknown product id: ${productId}`);
    }

    if (platform === 'ios') {
      const { jwsRepresentation } = request.data;
      if (!jwsRepresentation) {
        throw new HttpsError('invalid-argument', 'Missing jwsRepresentation');
      }
      let transaction;
      try {
        transaction = await verifyIOSTransaction(jwsRepresentation);
      } catch (err) {
        logger.warn('Apple transaction verification failed', err);
        throw new HttpsError('permission-denied', 'Could not verify purchase');
      }
      if (transaction.productId !== productId || transaction.revocationDate) {
        throw new HttpsError('invalid-argument', 'Transaction does not match a valid tip purchase');
      }
      await recordDonation(uid, Date.now());
      return { recorded: true };
    }

    if (platform === 'android') {
      const { originalJson, signature } = request.data;
      if (!originalJson || !signature) {
        throw new HttpsError('invalid-argument', 'Missing originalJson or signature');
      }
      let verified;
      try {
        verified = verifyAndroidPurchase(originalJson, signature, playRsaPublicKey.value());
      } catch (err) {
        logger.warn('Android purchase verification failed', err);
        throw new HttpsError('permission-denied', 'Could not verify purchase');
      }
      if (!verified) {
        throw new HttpsError('permission-denied', 'Invalid purchase signature');
      }
      const parsed = JSON.parse(originalJson);
      const purchasedProductId = parsed.productId
        || (Array.isArray(parsed.productIds) ? parsed.productIds[0] : undefined);
      if (purchasedProductId !== productId) {
        throw new HttpsError('invalid-argument', 'Purchase productId does not match');
      }
      await recordDonation(uid, Date.now());
      return { recorded: true };
    }

    throw new HttpsError('invalid-argument', `Unknown platform: ${platform}`);
  }
);

// --- Project ledger stats (docs/ledger.html "Stats" tab) ---
//
// Aggregates only — counts, never per-user data or dollar amounts — written
// to stats/ledger, which firestore.rules makes publicly readable so the
// ledger page can read it straight from Firestore with no function call.
// Refreshed once a day by ledgerStatsDaily, and on demand (throttled) by
// ledgerStatsRefresh via a Hosting rewrite, same pattern as stripeWebhook.
const LEDGER_MIN_REFRESH_MS = 10 * 60 * 1000;
const LEDGER_HISTORY_DAYS = 120;
const POPULAR_MIN_PEOPLE = 5;
const OVERREAD_MIN_SUPPLY = 10;
const DAY_MS = 24 * 60 * 60 * 1000;

// Calendar dates are Mountain time: the daily run is 6am there, and it is
// where most readers are.
const denverDate = (ms) => {
  // formatToParts, not a locale's date format: a slim-ICU Node ignores 'en-CA'.
  const p = {};
  for (const part of new Intl.DateTimeFormat('en-US', { timeZone: 'America/Denver', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date(ms))) p[part.type] = part.value;
  return `${p.year}-${p.month}-${p.day}`;
};
const shiftDate = (ymd, days) => new Date(Date.parse(`${ymd}T00:00:00Z`) + days * DAY_MS).toISOString().slice(0, 10);

async function computeLedgerStats(previous, { scheduled } = {}) {
  const now = Date.now();
  const todayLocal = denverDate(now);
  const calendarStart = shiftDate(todayLocal, -(LEDGER_HISTORY_DAYS - 1));
  // Per day: distinct accounts that read anything, and distinct accounts per talk.
  const readersByDay = {}, talkReadersByDay = {}, conferenceJoinedByDay = {};

  const providers = {};
  let total = 0, new7 = 0, new30 = 0, active7 = 0, active30 = 0;
  let pageToken;
  do {
    const page = await getAuth().listUsers(1000, pageToken);
    for (const u of page.users) {
      total++;
      const created = Date.parse(u.metadata.creationTime);
      const last = Date.parse(u.metadata.lastRefreshTime || u.metadata.lastSignInTime);
      if (now - created < 7 * DAY_MS) new7++;
      if (now - created < 30 * DAY_MS) new30++;
      if (now - last < 7 * DAY_MS) active7++;
      if (now - last < 30 * DAY_MS) active30++;
      for (const p of u.providerData) providers[p.providerId] = (providers[p.providerId] || 0) + 1;
    }
    pageToken = page.pageToken;
  } while (pageToken);

  let accountsTalksRead = 0, favorites = 0, lists = 0, notes = 0;
  let streaksActive = 0, longestStreak = 0, accountsWithData = 0;
  const readersByTalk = {}, favoritersByTalk = {}, listersByTalk = {};
  const speakerKeyReaders = []; // per-user read-key sets, resolved to speakers/topics/books below
  let studyDaysTotal = 0, studyPeople = 0;
  const sizeOf = (v) => (Array.isArray(v) ? v.length : (v && typeof v === 'object' ? Object.keys(v).length : 0));
  const users = await firestore.collection('users').select('read', 'favorites', 'collections', 'collectionMembers', 'notes', 'streak', 'readLog', 'readLogEstimated', 'studyDaysEstimated').get();
  users.forEach((d) => {
    const x = d.data();
    const reads = sizeOf(x.read);
    if (reads || sizeOf(x.favorites) || sizeOf(x.collections) || sizeOf(x.notes)) accountsWithData++;
    accountsTalksRead += reads;
    favorites += sizeOf(x.favorites);
    // Distinct people per talk (not total reads) — one person rereading a talk
    // 500 times shouldn't outrank 40 different readers.
    for (const k of new Set(Array.isArray(x.read) ? x.read : [])) readersByTalk[k] = (readersByTalk[k] || 0) + 1;
    {
      const readSet = new Set(Array.isArray(x.read) ? x.read : []);
      if (readSet.size) speakerKeyReaders.push(readSet);
      // A talk counts once per person however many of their lists it is on.
      const listed = new Set();
      for (const members of Object.values(x.collectionMembers || {})) {
        if (Array.isArray(members)) members.forEach((k) => listed.add(k));
      }
      for (const k of listed) listersByTalk[k] = (listersByTalk[k] || 0) + 1;
      // Distinct days of study: real read dates plus the streak's own record.
      const days = new Set();
      const addDay = (d) => { if (typeof d === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d)) days.add(d); };
      for (const dates of Object.values(x.readLog || {})) if (Array.isArray(dates)) dates.forEach(addDay);
      (Array.isArray(x.studyDaysEstimated) ? x.studyDaysEstimated : []).forEach(addDay);
      ((x.streak && x.streak.activeDays) || []).forEach(addDay);
      if (days.size) { studyDaysTotal += days.size; studyPeople++; }
      for (const day of days) if (day >= calendarStart) readersByDay[day] = (readersByDay[day] || 0) + 1;
      // Estimated dates count too: they only exist where the streak recorded
      // a real active day and that day's featured talk is marked read.
      const talkDays = new Set();
      for (const log of [x.readLog, x.readLogEstimated]) {
        for (const [k, dates] of Object.entries(log || {})) {
          if (Array.isArray(dates)) dates.forEach((day) => { if (typeof day === 'string' && day >= calendarStart) talkDays.add(`${day}|${k}`); });
        }
      }
      for (const dk of talkDays) talkReadersByDay[dk] = (talkReadersByDay[dk] || 0) + 1;
      // General Conference days this person answered "Yes" on in the app.
      for (const day of new Set(Array.isArray(x.conferenceDays) ? x.conferenceDays : [])) {
        if (typeof day === 'string' && day >= calendarStart) conferenceJoinedByDay[day] = (conferenceJoinedByDay[day] || 0) + 1;
      }
    }
    for (const k of new Set(Array.isArray(x.favorites) ? x.favorites : [])) favoritersByTalk[k] = (favoritersByTalk[k] || 0) + 1;
    lists += sizeOf(x.collections);
    notes += sizeOf(x.notes);
    const s = x.streak;
    if (s && typeof s.count === 'number') {
      longestStreak = Math.max(longestStreak, s.count);
      const lastDay = Date.parse(s.lastDate);
      if (s.count > 0 && !isNaN(lastDay) && now - lastDay < 2 * DAY_MS) streaksActive++;
    }
  });

  const globalDoc = await firestore.collection('stats').doc('global').get();
  const globalTalksRead = globalDoc.exists ? (globalDoc.data().totalTalksRead || 0) : 0;

  let supportersTotal = 0, supportersActive = 0;
  const supportersByYear = {};
  const donations = await firestore.collection('donations').get();
  donations.forEach((d) => {
    const x = d.data();
    supportersTotal++;
    if (x.activeUntil > now) supportersActive++;
    for (const y of (x.years || [])) supportersByYear[y] = (supportersByYear[y] || 0) + 1;
  });

  let content = null, popular = null, pickTalk = null, dataDate = null;
  try {
    const res = await fetch('https://findatalk.com/data.json');
    const data = await res.json();
    pickTalk = makeTotdPicker(data);
    dataDate = String(data.generatedAt).slice(0, 10);
    // Talks are [title, speaker, year, month, slug]; user docs key them "year|month|slug".
    const byKey = {};
    for (const t of data.talks) byKey[`${t[2]}|${t[3]}|${t[4]}`] = t;
    const top = (counts) => {
      let best = null;
      for (const [k, n] of Object.entries(counts)) {
        if (byKey[k] && (!best || n > best.n)) best = { k, n };
      }
      // Below the minimum, publish nothing — a handful of people shouldn't be identifiable.
      if (!best || best.n < POPULAR_MIN_PEOPLE) return null;
      const t = byKey[best.k];
      return { title: t[0], speaker: t[1], year: t[2], month: t[3], people: best.n };
    };
    // Roll each person's read talks up to speakers, topics and scripture chapters.
    // "People" counts each member once per speaker/topic/chapter; "reads" counts
    // every member-talk pair, so it can be compared with the library's own mix
    // (supply) to tell what people gravitate toward from what is merely common.
    const peopleBy = { speaker: {}, topic: {}, chapter: {} };
    const readsBy = { topic: {}, chapter: {} };
    const supplyBy = { topic: {}, chapter: {} };
    const bump = (map, k) => { map[k] = (map[k] || 0) + 1; };
    const chaptersOf = (k) => {
      const out = new Set();
      for (const i of (data.citationLookup[k] || [])) {
        const ref = data.citationRefs[i];
        if (ref && ref[3]) out.add(`${ref[1]}|${ref[2]}|${ref[3]}`);
      }
      return out;
    };
    for (const k of Object.keys(byKey)) {
      (data.topicLookup[k] || []).forEach((tp) => bump(supplyBy.topic, tp));
      chaptersOf(k).forEach((c) => bump(supplyBy.chapter, c));
    }
    const libraryTalks = Object.keys(byKey).length;
    let totalReads = 0;
    for (const readSet of speakerKeyReaders) {
      const speakers = new Set(), topics = new Set(), chapters = new Set();
      for (const k of readSet) {
        const t = byKey[k];
        if (!t) continue;
        totalReads++;
        speakers.add(t[1]);
        for (const tp of (data.topicLookup[k] || [])) { topics.add(tp); bump(readsBy.topic, tp); }
        for (const c of chaptersOf(k)) { chapters.add(c); bump(readsBy.chapter, c); }
      }
      speakers.forEach((v) => bump(peopleBy.speaker, v));
      topics.forEach((v) => bump(peopleBy.topic, v));
      chapters.forEach((v) => bump(peopleBy.chapter, v));
    }
    const topOf = (counts, label) => {
      let best = null;
      for (const [k, n] of Object.entries(counts)) if (!best || n > best.n) best = { k, n };
      if (!best || best.n < POPULAR_MIN_PEOPLE) return null;
      return { name: label(best.k), people: best.n };
    };
    // Popularity vs. supply: how much more of members' reading goes to this
    // topic/chapter than its share of the library would predict. Needs the
    // minimum number of people so a lone reader can't produce a "favorite".
    const overRead = (kind, label) => {
      let best = null;
      for (const [k, people] of Object.entries(peopleBy[kind])) {
        // Skip thinly-supplied tags: one talk read by a few people would otherwise
        // look like a huge preference.
        if (people < POPULAR_MIN_PEOPLE || (supplyBy[kind][k] || 0) < OVERREAD_MIN_SUPPLY || !totalReads) continue;
        const lift = (readsBy[kind][k] / totalReads) / (supplyBy[kind][k] / libraryTalks);
        if (!best || lift > best.lift) best = { k, people, lift };
      }
      return best && { name: label(best.k), people: best.people, lift: Math.round(best.lift * 10) / 10 };
    };
    const chapterLabel = (k) => {
      const [vol, book, ch] = k.split('|');
      return `${data.citationBookLabels[`${vol}|${book}`] || book} ${ch}`;
    };
    const topicLabel = (k) => data.topicLabels[k] || k;
    popular = {
      mostRead: top(readersByTalk),
      mostFavorited: top(favoritersByTalk),
      mostListed: top(listersByTalk),
      topSpeaker: topOf(peopleBy.speaker, (k) => k),
      topTopic: topOf(peopleBy.topic, topicLabel),
      topChapter: topOf(peopleBy.chapter, chapterLabel),
      overReadTopic: overRead('topic', topicLabel),
      overReadChapter: overRead('chapter', chapterLabel),
      studyDays: studyPeople >= POPULAR_MIN_PEOPLE ? { days: studyDaysTotal, people: studyPeople } : null,
      minPeople: POPULAR_MIN_PEOPLE,
    };
    const conferences = new Set(data.talks.map((t) => `${t[2]}-${t[3]}`));
    content = { talks: data.talks.length, conferences: conferences.size, dataGeneratedAt: data.generatedAt };
  } catch (err) {
    logger.warn('ledger stats: could not read data.json', err);
  }

  const today = new Date(now).toISOString().slice(0, 10);
  const history = ((previous && previous.history) || []).filter((h) => h.d !== today);
  history.push({ d: today, accounts: total, talksRead: globalTalksRead, supporters: supportersTotal });

  // The all-users read counter as of each morning's scheduled run, so a day's
  // reads by everyone (signed in or not) is one morning's value minus the last.
  const morning = { ...((previous && previous.morning) || {}) };
  if (!Object.keys(morning).length) for (const h of history) morning[h.d] = h.talksRead;
  if (scheduled || !(todayLocal in morning)) morning[todayLocal] = globalTalksRead;
  for (const d of Object.keys(morning)) if (d < calendarStart) delete morning[d];

  // A day's featured talk is stored the first time it is computed and never
  // recomputed: the pick depends on how many talks data.json holds, so a later
  // data update would otherwise rewrite history. Days before the current data
  // was generated get no talk for the same reason.
  const stored = {};
  for (const c of (previous && previous.calendar) || []) stored[c.d] = c;
  let calendar = [];
  for (let d = calendarStart; d <= todayLocal; d = shiftDate(d, 1)) {
    let talk = (stored[d] && stored[d].talk) || null;
    const [y, m, day] = d.split('-').map(Number);
    if (!talk && pickTalk && d >= dataDate) {
      const t = pickTalk(y, m, day);
      if (t) talk = { k: talkKey(t), title: t[0], speaker: t[1] };
    }
    // The app features no talk on a General Conference day. A conference day
    // from before that began keeps the talk already stored for it.
    const conference = !talk && isConferenceDay(y, m, day);
    const next = shiftDate(d, 1);
    const end = next in morning ? morning[next] : (d === todayLocal ? globalTalksRead : null);
    calendar.push({
      d,
      talk,
      readers: readersByDay[d] || 0,
      totdReaders: talk ? (talkReadersByDay[`${d}|${talk.k}`] || 0) : 0,
      ...(conference ? { conference: true, conferenceJoined: conferenceJoinedByDay[d] || 0 } : {}),
      reads: d in morning && end !== null ? Math.max(0, end - morning[d]) : null,
    });
  }
  const firstActive = calendar.findIndex((c) => c.readers || c.reads);
  calendar = firstActive < 0 ? [] : calendar.slice(firstActive);

  return {
    generatedAt: now,
    accounts: { total, new7, new30, active7, active30, withData: accountsWithData, providers },
    activity: { globalTalksRead, accountsTalksRead, favorites, lists, notes, streaksActive, longestStreak },
    supporters: { total: supportersTotal, active: supportersActive, byYear: supportersByYear },
    content,
    popular,
    history: history.slice(-LEDGER_HISTORY_DAYS),
    calendar,
    morning,
  };
}

async function refreshLedgerStats({ force }) {
  const ref = firestore.collection('stats').doc('ledger');
  const existing = await ref.get();
  const previous = existing.exists ? JSON.parse(existing.data().json) : null;
  if (!force && previous && Date.now() - previous.generatedAt < LEDGER_MIN_REFRESH_MS) {
    return { stats: previous, throttled: true };
  }
  const stats = await computeLedgerStats(previous, { scheduled: force });
  await ref.set({ json: JSON.stringify(stats), updatedAt: stats.generatedAt });
  return { stats, throttled: false };
}

exports.ledgerStatsDaily = onSchedule(
  { schedule: 'every day 06:00', timeZone: 'America/Denver' },
  async () => {
    await refreshLedgerStats({ force: true });
  }
);

exports.ledgerStatsRefresh = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).send('GET only');
    return;
  }
  try {
    const { stats, throttled } = await refreshLedgerStats({ force: false });
    res.json({ throttled, stats });
  } catch (err) {
    logger.error('ledgerStatsRefresh failed', err);
    res.status(500).json({ error: 'refresh failed' });
  }
});

/* ---------------- Shared lists (idea 57) ----------------
   A shared list is one Firestore doc, sharedLists/{listId}, that every
   member's app listens to. Clients can only READ it (firestore.rules);
   every change goes through the callables below, so "Added by" can't be
   forged (addedBy is always the caller's own uid), two people editing at
   once can't clobber each other (each change is its own transaction), and
   ownership hand-off on leave is atomic. Doc shape:
     { name, ownerUid, memberUids: [uid], members: {uid: {name, joinedAt}},
       talks: {talkKey: {addedBy, addedByName, addedAt}}, createdAt, updatedAt }
   sharedListIndex/{uid} = { lists: {listId: true} } tells each person's app
   which lists to listen to (a doc listener, not a collection query).
   sharedListInvites/{code} = { listId, createdBy, createdAt, expiresAt } —
   never client-readable; single-use and expiring, since a forwarded link
   is the main abuse risk. */
const { FieldValue } = require('firebase-admin/firestore');

const SHARED_LIST_MAX_MEMBERS = 10;
const SHARED_LIST_MAX_TALKS = 500;
const SHARED_LIST_INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const INVITE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to use shared lists.');
  return uid;
}
function cleanText(value, max, label) {
  const text = typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : '';
  if (!text) throw new HttpsError('invalid-argument', `${label} is required.`);
  if (text.length > max) throw new HttpsError('invalid-argument', `${label} must be ${max} characters or fewer.`);
  return text;
}
function cleanTalkKey(value) {
  if (typeof value !== 'string' || value.length > 200 || !/^\d{4}\|\d{2}\|[^|]+$/.test(value)) {
    throw new HttpsError('invalid-argument', 'Not a valid talk.');
  }
  return value;
}
function cleanListId(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9]{10,40}$/.test(value)) {
    throw new HttpsError('invalid-argument', 'Not a valid list.');
  }
  return value;
}
function listRef(listId) { return firestore.collection('sharedLists').doc(listId); }
function indexRef(uid) { return firestore.collection('sharedListIndex').doc(uid); }
function inviteRef(code) { return firestore.collection('sharedListInvites').doc(code); }

async function readMemberList(tx, listId, uid) {
  const snap = await tx.get(listRef(listId));
  if (!snap.exists) throw new HttpsError('not-found', 'That list no longer exists.');
  const data = snap.data();
  if (!Array.isArray(data.memberUids) || !data.memberUids.includes(uid)) {
    throw new HttpsError('permission-denied', "You're not a member of that list.");
  }
  return data;
}

exports.createSharedList = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const name = cleanText(data.name, 60, 'List name');
  const displayName = cleanText(data.displayName, 30, 'Your name');
  const keys = Array.isArray(data.talkKeys) ? data.talkKeys : [];
  if (keys.length > SHARED_LIST_MAX_TALKS) {
    throw new HttpsError('invalid-argument', `A shared list can hold up to ${SHARED_LIST_MAX_TALKS} talks.`);
  }
  const now = Date.now();
  const talks = {};
  // Staggered by index so the original "order added" survives the move.
  keys.map(cleanTalkKey).forEach((key, i) => {
    if (!talks[key]) talks[key] = { addedBy: uid, addedByName: displayName, addedAt: now - keys.length + i };
  });
  const ref = firestore.collection('sharedLists').doc();
  const batch = firestore.batch();
  batch.set(ref, {
    name, ownerUid: uid, memberUids: [uid],
    members: { [uid]: { name: displayName, joinedAt: now } },
    talks, createdAt: now, updatedAt: now,
  });
  batch.set(indexRef(uid), { lists: { [ref.id]: true } }, { merge: true });
  await batch.commit();
  return { listId: ref.id };
});

exports.setSharedListTalk = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const listId = cleanListId(data.listId);
  const key = cleanTalkKey(data.talkKey);
  const present = !!data.present;
  await firestore.runTransaction(async (tx) => {
    const list = await readMemberList(tx, listId, uid);
    const talks = { ...(list.talks || {}) };
    if (present) {
      if (talks[key]) return;
      if (Object.keys(talks).length >= SHARED_LIST_MAX_TALKS) {
        throw new HttpsError('resource-exhausted', `A shared list can hold up to ${SHARED_LIST_MAX_TALKS} talks.`);
      }
      const me = (list.members || {})[uid] || {};
      talks[key] = { addedBy: uid, addedByName: me.name || 'Someone', addedAt: Date.now() };
    } else {
      if (!talks[key]) return;
      delete talks[key];
    }
    tx.update(listRef(listId), { talks, updatedAt: Date.now() });
  });
  return { ok: true };
});

exports.renameSharedList = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const listId = cleanListId(data.listId);
  const name = cleanText(data.name, 60, 'List name');
  await firestore.runTransaction(async (tx) => {
    await readMemberList(tx, listId, uid);
    tx.update(listRef(listId), { name, updatedAt: Date.now() });
  });
  return { ok: true };
});

exports.setSharedListDisplayName = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const listId = cleanListId(data.listId);
  const displayName = cleanText(data.displayName, 30, 'Your name');
  await firestore.runTransaction(async (tx) => {
    const list = await readMemberList(tx, listId, uid);
    const members = { ...(list.members || {}) };
    members[uid] = { ...(members[uid] || {}), name: displayName };
    tx.update(listRef(listId), { members, updatedAt: Date.now() });
  });
  return { ok: true };
});

exports.createSharedListInvite = onCall(async (request) => {
  const uid = requireUid(request);
  const listId = cleanListId((request.data || {}).listId);
  const now = Date.now();
  let code = '';
  await firestore.runTransaction(async (tx) => {
    const list = await readMemberList(tx, listId, uid);
    if ((list.memberUids || []).length >= SHARED_LIST_MAX_MEMBERS) {
      throw new HttpsError('resource-exhausted', `A shared list can have up to ${SHARED_LIST_MAX_MEMBERS} people.`);
    }
    const bytes = crypto.randomBytes(8);
    code = Array.from(bytes, (b) => INVITE_ALPHABET[b % INVITE_ALPHABET.length]).join('');
    tx.set(inviteRef(code), { listId, createdBy: uid, createdAt: now, expiresAt: now + SHARED_LIST_INVITE_TTL_MS });
  });
  return { code, expiresAt: now + SHARED_LIST_INVITE_TTL_MS };
});

function cleanInviteCode(value) {
  const code = typeof value === 'string' ? value.trim().toUpperCase() : '';
  if (!/^[A-Z0-9]{8}$/.test(code)) throw new HttpsError('invalid-argument', "That invite link isn't valid.");
  return code;
}
function assertInviteUsable(inviteSnap) {
  if (!inviteSnap.exists) throw new HttpsError('not-found', 'That invite link has already been used or no longer works.');
  const invite = inviteSnap.data();
  if (!invite.expiresAt || invite.expiresAt < Date.now()) {
    throw new HttpsError('deadline-exceeded', 'That invite link has expired. Ask for a new one.');
  }
  return invite;
}

exports.previewSharedListInvite = onCall(async (request) => {
  const uid = requireUid(request);
  const code = cleanInviteCode((request.data || {}).code);
  const invite = assertInviteUsable(await inviteRef(code).get());
  const listSnap = await listRef(invite.listId).get();
  if (!listSnap.exists) throw new HttpsError('not-found', 'That list no longer exists.');
  const list = listSnap.data();
  const members = list.members || {};
  const inviter = members[invite.createdBy] || members[list.ownerUid] || {};
  return {
    listId: invite.listId,
    name: list.name,
    talkCount: Object.keys(list.talks || {}).length,
    inviterName: inviter.name || 'Someone',
    memberNames: (list.memberUids || []).map((m) => (members[m] || {}).name).filter(Boolean),
    alreadyMember: (list.memberUids || []).includes(uid),
  };
});

exports.joinSharedList = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const code = cleanInviteCode(data.code);
  const displayName = cleanText(data.displayName, 30, 'Your name');
  let listId = '';
  await firestore.runTransaction(async (tx) => {
    const inviteSnap = await tx.get(inviteRef(code));
    const invite = assertInviteUsable(inviteSnap);
    listId = invite.listId;
    const listSnap = await tx.get(listRef(listId));
    if (!listSnap.exists) throw new HttpsError('not-found', 'That list no longer exists.');
    const list = listSnap.data();
    const memberUids = list.memberUids || [];
    if (memberUids.includes(uid)) return; // already in — leave the invite for whoever it was meant for
    if (memberUids.length >= SHARED_LIST_MAX_MEMBERS) {
      throw new HttpsError('resource-exhausted', `A shared list can have up to ${SHARED_LIST_MAX_MEMBERS} people.`);
    }
    const now = Date.now();
    tx.update(listRef(listId), {
      memberUids: [...memberUids, uid],
      members: { ...(list.members || {}), [uid]: { name: displayName, joinedAt: now } },
      updatedAt: now,
    });
    tx.set(indexRef(uid), { lists: { [listId]: true } }, { merge: true });
    tx.delete(inviteRef(code));
  });
  return { listId };
});

// Removes `targetUid` from a list inside an open transaction. The earliest-
// joined remaining member inherits ownership; the last person out deletes
// the list itself.
function removeMemberInTx(tx, listId, list, targetUid) {
  const memberUids = (list.memberUids || []).filter((m) => m !== targetUid);
  tx.set(indexRef(targetUid), { lists: { [listId]: FieldValue.delete() } }, { merge: true });
  if (!memberUids.length) {
    tx.delete(listRef(listId));
    return;
  }
  const members = { ...(list.members || {}) };
  delete members[targetUid];
  let ownerUid = list.ownerUid;
  if (ownerUid === targetUid) {
    ownerUid = memberUids.slice().sort((a, b) => ((members[a] || {}).joinedAt || 0) - ((members[b] || {}).joinedAt || 0))[0];
  }
  tx.update(listRef(listId), { memberUids, members, ownerUid, updatedAt: Date.now() });
}

exports.leaveSharedList = onCall(async (request) => {
  const uid = requireUid(request);
  const listId = cleanListId((request.data || {}).listId);
  await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(listRef(listId));
    if (!snap.exists) {
      tx.set(indexRef(uid), { lists: { [listId]: FieldValue.delete() } }, { merge: true });
      return;
    }
    const list = snap.data();
    if (!(list.memberUids || []).includes(uid)) {
      tx.set(indexRef(uid), { lists: { [listId]: FieldValue.delete() } }, { merge: true });
      return;
    }
    removeMemberInTx(tx, listId, list, uid);
  });
  return { ok: true };
});

exports.removeSharedListMember = onCall(async (request) => {
  const uid = requireUid(request);
  const data = request.data || {};
  const listId = cleanListId(data.listId);
  const target = typeof data.uid === 'string' ? data.uid : '';
  if (!target || target === uid) throw new HttpsError('invalid-argument', 'Use Leave to remove yourself.');
  await firestore.runTransaction(async (tx) => {
    const list = await readMemberList(tx, listId, uid);
    if (list.ownerUid !== uid) throw new HttpsError('permission-denied', 'Only the person who created this list can remove members.');
    if (!(list.memberUids || []).includes(target)) return;
    removeMemberInTx(tx, listId, list, target);
  });
  return { ok: true };
});

// ---- Ledger admin tools (private tab on docs/ledger.html) ----
//
// Unlike everything above, these read and change ONE person's data, so
// they're callable only by a signed-in admin and never write anything to
// the public stats/ledger doc. Every change is recorded in adminActions
// (no Firestore rule, so no client can read or write it).
const ADMIN_EMAILS = ['brad@smoothop.com'];
const ADMIN_MAX_FORGIVE_DAYS = 31;

function requireAdmin(request) {
  const token = request.auth && request.auth.token;
  if (!token) throw new HttpsError('unauthenticated', 'Sign in first.');
  const email = String(token.email || '').toLowerCase();
  if (!token.email_verified || !ADMIN_EMAILS.includes(email)) {
    throw new HttpsError('permission-denied', 'This account is not an admin.');
  }
  return email;
}

function streakSummary(data) {
  const s = (data && data.streak) || {};
  const activeDays = [...new Set((Array.isArray(s.activeDays) ? s.activeDays : []).filter(isDay))].sort();
  const bridgedDays = [...new Set((Array.isArray(s.bridgedDays) ? s.bridgedDays : []).filter(isDay))].sort();
  return { ...recomputeStreak(activeDays, s.longest, bridgedDays), activeDays, bridgedDays };
}

exports.adminStreakLookup = onCall(async (request) => {
  requireAdmin(request);
  const email = String((request.data && request.data.email) || '').trim().toLowerCase();
  if (!email) throw new HttpsError('invalid-argument', 'Enter an email address.');
  let user;
  try {
    user = await getAuth().getUserByEmail(email);
  } catch (err) {
    if (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-email') {
      throw new HttpsError('not-found', 'No account uses that email address.');
    }
    throw err;
  }
  const snap = await firestore.collection('users').doc(user.uid).get();
  return {
    uid: user.uid,
    email: user.email,
    hasData: snap.exists,
    streak: streakSummary(snap.exists ? snap.data() : null),
  };
});

// Marks missed days as forgiven (streak.bridgedDays): the streak runs
// straight through them, but they are NOT added to activeDays, so "days
// studied" stays an honest count. The app unions bridgedDays on every
// sync and rebuilds the count from them, so this survives the person's
// own devices pushing afterward (their pushes use merge:true).
exports.adminStreakForgive = onCall(async (request) => {
  const adminEmail = requireAdmin(request);
  const { uid, days } = request.data || {};
  if (typeof uid !== 'string' || !uid) throw new HttpsError('invalid-argument', 'Missing account.');
  if (!Array.isArray(days) || !days.length || days.length > ADMIN_MAX_FORGIVE_DAYS || !days.every(isDay)) {
    throw new HttpsError('invalid-argument', `Pick between 1 and ${ADMIN_MAX_FORGIVE_DAYS} valid days.`);
  }
  // Nobody's local "today" is later than UTC+14.
  const latest = new Date(Date.now() + 14 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const ref = firestore.collection('users').doc(uid);
  return firestore.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'That account has no synced data yet.');
    const before = streakSummary(snap.data());
    if (!before.activeDays.length) {
      throw new HttpsError('failed-precondition', 'That account has no reading days to connect.');
    }
    const active = new Set(before.activeDays);
    const first = before.activeDays[0];
    for (const d of days) {
      if (active.has(d)) throw new HttpsError('invalid-argument', `${d} is already a day they read.`);
      // The app drops forgiven days older than the first day it still remembers.
      if (d < first || d > latest) throw new HttpsError('invalid-argument', `${d} is outside their reading history.`);
    }
    const bridgedDays = [...new Set([...before.bridgedDays, ...days])].sort();
    const after = recomputeStreak(before.activeDays, before.longest, bridgedDays);
    tx.update(ref, {
      'streak.bridgedDays': bridgedDays,
      'streak.count': after.count,
      'streak.longest': after.longest,
    });
    tx.set(firestore.collection('adminActions').doc(), {
      action: 'streakForgive',
      at: Date.now(),
      admin: adminEmail,
      uid,
      days: [...days].sort(),
      before: { count: before.count, longest: before.longest },
      after: { count: after.count, longest: after.longest },
    });
    return { streak: { ...after, activeDays: before.activeDays, bridgedDays } };
  });
});
