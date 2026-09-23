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
const DAY_MS = 24 * 60 * 60 * 1000;

async function computeLedgerStats(previous) {
  const now = Date.now();

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
  const sizeOf = (v) => (Array.isArray(v) ? v.length : (v && typeof v === 'object' ? Object.keys(v).length : 0));
  const users = await firestore.collection('users').select('read', 'favorites', 'collections', 'notes', 'streak').get();
  users.forEach((d) => {
    const x = d.data();
    const reads = sizeOf(x.read);
    if (reads || sizeOf(x.favorites) || sizeOf(x.collections) || sizeOf(x.notes)) accountsWithData++;
    accountsTalksRead += reads;
    favorites += sizeOf(x.favorites);
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

  let content = null;
  try {
    const res = await fetch('https://findatalk.com/data.json');
    const data = await res.json();
    const conferences = new Set(data.talks.map((t) => `${t[2]}-${t[3]}`));
    content = { talks: data.talks.length, conferences: conferences.size, dataGeneratedAt: data.generatedAt };
  } catch (err) {
    logger.warn('ledger stats: could not read data.json', err);
  }

  const today = new Date(now).toISOString().slice(0, 10);
  const history = ((previous && previous.history) || []).filter((h) => h.d !== today);
  history.push({ d: today, accounts: total, talksRead: globalTalksRead, supporters: supportersTotal });

  return {
    generatedAt: now,
    accounts: { total, new7, new30, active7, active30, withData: accountsWithData, providers },
    activity: { globalTalksRead, accountsTalksRead, favorites, lists, notes, streaksActive, longestStreak },
    supporters: { total: supportersTotal, active: supportersActive, byYear: supportersByYear },
    content,
    history: history.slice(-LEDGER_HISTORY_DAYS),
  };
}

async function refreshLedgerStats({ force }) {
  const ref = firestore.collection('stats').doc('ledger');
  const existing = await ref.get();
  const previous = existing.exists ? JSON.parse(existing.data().json) : null;
  if (!force && previous && Date.now() - previous.generatedAt < LEDGER_MIN_REFRESH_MS) {
    return { stats: previous, throttled: true };
  }
  const stats = await computeLedgerStats(previous);
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
