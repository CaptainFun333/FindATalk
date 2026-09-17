const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const Stripe = require('stripe');

initializeApp();
const firestore = getFirestore();

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

// Event types we record donations from today. Recurring donations would come
// through as `invoice.paid` / `payment_intent.succeeded` on a subscription —
// not built yet, see PROJECT_HANDOFF.md.
const HANDLED_EVENT_TYPES = new Set(['checkout.session.completed']);

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

    if (!HANDLED_EVENT_TYPES.has(event.type)) {
      logger.info(`Ignoring unhandled Stripe event type: ${event.type}`);
      res.status(200).send();
      return;
    }

    const session = event.data.object;

    // Document ID is the Stripe event ID itself, not an auto-ID: Stripe
    // guarantees at-least-once delivery, so a redelivered event overwrites
    // the same doc instead of recording the donation twice.
    await firestore.collection('donations').doc(event.id).set({
      amount: session.amount_total,
      currency: session.currency,
      stripeEventId: event.id,
      stripeSessionId: session.id,
      createdAt: FieldValue.serverTimestamp(),
    });

    res.status(200).send();
  }
);
