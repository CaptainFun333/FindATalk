const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const Stripe = require('stripe');

initializeApp();
const firestore = getFirestore();

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

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
