// functions/index.js
//
// Stripe payments for booking deposits.
//
// Money flow: these functions use the salon's OWN Stripe account (the
// manager's), so every payment lands in that account's balance and Stripe
// pays it out automatically to the business bank account set in
// Stripe Dashboard → Settings → Payouts. Nothing passes through any other
// account.
//
// Bookings: when Stripe confirms a payment, the webhook creates the booking in
// Firestore (bookings/{BK-xxxxx}) — the app never creates bookings itself.
//
// Security:
//  • The Stripe secret key and webhook secret are Firebase secrets — never in the app.
//  • The amount is set HERE, not by the app, so it can't be tampered with.
//  • Card details are entered on Stripe's hosted Checkout page only; they
//    never touch this app or these servers.
//  • A payment is only marked "paid" by Stripe's signed webhook.

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const Stripe = require("stripe");

initializeApp();
const db = getFirestore();

const REGION = "europe-west2"; // London
setGlobalOptions({ region: REGION, maxInstances: 10 });

const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = defineSecret("STRIPE_WEBHOOK_SECRET");

// Booking deposit, in pence. Keep in sync with the app's "Book Now £10" label.
const DEPOSIT_PENCE = 1000;
const CURRENCY = "gbp";

const stripeClient = () => new Stripe(STRIPE_SECRET_KEY.value());

function returnPageUrl() {
  const project = process.env.GCLOUD_PROJECT;
  return `https://${REGION}-${project}.cloudfunctions.net/paymentReturn`;
}

function requireString(data, key, max) {
  const v = data?.[key];
  if (typeof v !== "string" || v.trim().length === 0 || v.length > max) {
    throw new HttpsError("invalid-argument", `Missing or invalid "${key}".`);
  }
  return v.trim();
}

// ─────────────────────────────────────────────────────────────
// 1. App → create a Stripe Checkout page for the £10 deposit.
// ─────────────────────────────────────────────────────────────
exports.createCheckoutSession = onCall(
  { secrets: [STRIPE_SECRET_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please log in to pay.");
    }
    const uid = request.auth.uid;
    const data = request.data || {};

    const serviceName = requireString(data, "serviceName", 120);
    const date = requireString(data, "date", 10); // YYYY-MM-DD
    const time = requireString(data, "time", 5); // HH:MM
    const phone = requireString(data, "phone", 30);
    const customerName = typeof data.customerName === "string" ? data.customerName.trim().slice(0, 80) : "";
    const servicePrice = Number.isInteger(data.servicePrice) ? data.servicePrice : null;

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !/^\d{2}:\d{2}$/.test(time)) {
      throw new HttpsError("invalid-argument", "Invalid date or time.");
    }

    const paymentRef = db.collection("payments").doc();
    await paymentRef.set({
      uid,
      status: "pending",
      amount: DEPOSIT_PENCE,
      currency: CURRENCY,
      serviceName,
      servicePrice,
      date,
      time,
      phone,
      customerName,
      createdAt: FieldValue.serverTimestamp(),
    });

    const stripe = stripeClient();
    const back = returnPageUrl();
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      client_reference_id: paymentRef.id,
      customer_email: request.auth.token.email || undefined,
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: CURRENCY,
            unit_amount: DEPOSIT_PENCE,
            product_data: {
              name: `Booking deposit – ${serviceName}`,
              description: `${date} at ${time}`,
            },
          },
        },
      ],
      metadata: { paymentId: paymentRef.id, uid },
      payment_intent_data: {
        metadata: { paymentId: paymentRef.id, uid },
        description: `Deposit: ${serviceName} on ${date} ${time}`,
      },
      // Stripe's minimum; unpaid pages expire after 30 minutes.
      expires_at: Math.floor(Date.now() / 1000) + 30 * 60,
      success_url: `${back}?result=success`,
      cancel_url: `${back}?result=cancel`,
    });

    await paymentRef.update({ sessionId: session.id });
    return { paymentId: paymentRef.id, url: session.url };
  },
);

// ─────────────────────────────────────────────────────────────
// 2. App → customer gave up waiting: close the Checkout page so it
//    can't be paid later without a booking. Reports if it was already paid.
// ─────────────────────────────────────────────────────────────
exports.cancelCheckoutSession = onCall(
  { secrets: [STRIPE_SECRET_KEY] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Please log in.");
    const paymentId = requireString(request.data, "paymentId", 64);

    const ref = db.collection("payments").doc(paymentId);
    const snap = await ref.get();
    if (!snap.exists || snap.get("uid") !== request.auth.uid) {
      throw new HttpsError("not-found", "Payment not found.");
    }
    const sessionId = snap.get("sessionId");
    if (!sessionId || snap.get("status") !== "pending") {
      return { status: snap.get("status") };
    }

    const stripe = stripeClient();
    const session = await stripe.checkout.sessions.retrieve(sessionId);
    if (session.status === "complete") {
      return { status: "paid" }; // the webhook will (or did) record it
    }
    if (session.status === "open") {
      await stripe.checkout.sessions.expire(sessionId);
    }
    await ref.update({ status: "cancelled" });
    return { status: "cancelled" };
  },
);

// ─────────────────────────────────────────────────────────────
// 3. Stripe → signed webhook. The ONLY place a payment becomes "paid".
// ─────────────────────────────────────────────────────────────
exports.stripeWebhook = onRequest(
  { secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET] },
  async (req, res) => {
    const stripe = stripeClient();
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        req.headers["stripe-signature"],
        STRIPE_WEBHOOK_SECRET.value(),
      );
    } catch (err) {
      logger.warn("Webhook signature check failed", err.message);
      res.status(400).send("Bad signature");
      return;
    }

    try {
      const session = event.data.object;
      const paymentId = session?.metadata?.paymentId;

      if (paymentId && event.type === "checkout.session.completed" && session.payment_status === "paid") {
        // Look up how they paid, for the booking's "paid with" label.
        let methodLabel = "Card";
        try {
          const pi = await stripe.paymentIntents.retrieve(session.payment_intent, {
            expand: ["latest_charge"],
          });
          const card = pi.latest_charge?.payment_method_details?.card;
          if (card?.wallet?.type === "apple_pay") methodLabel = "Apple Pay";
          else if (card?.wallet?.type === "google_pay") methodLabel = "Google Pay";
          else if (card) {
            const brand = card.brand === "amex" ? "Amex" : card.brand.charAt(0).toUpperCase() + card.brand.slice(1);
            methodLabel = `${brand} ending in ${card.last4}`;
          }
        } catch (e) {
          logger.warn("Could not read payment method", e.message);
        }

        await createBookingForPayment(paymentId, {
          amountPaid: session.amount_total,
          paymentIntentId: session.payment_intent,
          methodLabel,
        });
      } else if (paymentId && event.type === "checkout.session.expired") {
        const ref = db.collection("payments").doc(paymentId);
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(ref);
          if (snap.exists && snap.get("status") === "pending") {
            tx.update(ref, { status: "expired" });
          }
        });
      }
      res.json({ received: true });
    } catch (err) {
      logger.error("Webhook handling failed", err);
      res.status(500).send("Webhook error"); // Stripe will retry
    }
  },
);

// ─────────────────────────────────────────────────────────────
// Turn a paid payment into a booking (plus the manager's alerts).
// Runs in a transaction and does nothing if the booking already exists,
// so Stripe re-sending the same webhook can never double-book.
// ─────────────────────────────────────────────────────────────
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const FIRST_BOOKING_NUMBER = 10482;

function money(pence) {
  const pounds = pence / 100;
  return Number.isInteger(pounds) ? `£${pounds}` : `£${pounds.toFixed(2)}`;
}

async function createBookingForPayment(paymentId, { amountPaid, paymentIntentId, methodLabel }) {
  const paymentRef = db.collection("payments").doc(paymentId);
  const counterRef = db.collection("counters").doc("bookings");

  await db.runTransaction(async (tx) => {
    const paymentSnap = await tx.get(paymentRef);
    if (!paymentSnap.exists) throw new Error(`Payment ${paymentId} not found`);
    if (paymentSnap.get("bookingRef")) return; // already handled

    const counterSnap = await tx.get(counterRef);
    const number = counterSnap.exists ? counterSnap.get("next") : FIRST_BOOKING_NUMBER;
    const reference = `BK-${number}`;

    const p = paymentSnap.data();
    const customerName = p.customerName || "Guest";
    const deposit = (amountPaid ?? p.amount) / 100;
    const [, mm, dd] = p.date.split("-").map(Number);
    const when = `${dd} ${MONTHS[mm - 1]} · ${p.time}`;
    const now = FieldValue.serverTimestamp();

    tx.set(counterRef, { next: number + 1 }, { merge: true });

    tx.set(db.collection("bookings").doc(reference), {
      customerUid: p.uid,
      customerName,
      customerPhone: p.phone || "",
      serviceName: p.serviceName,
      servicePrice: p.servicePrice ?? null,
      depositPaid: deposit,
      date: p.date,
      time: p.time,
      paymentMethod: methodLabel,
      paymentId,
      status: "pending",
      createdAt: now,
      doneBy: "",
      doneNotes: "",
    });

    tx.set(db.collection("activity").doc(), {
      kind: "payment",
      title: "Payment received",
      subtitle: `${money(amountPaid ?? p.amount)} deposit · ${p.serviceName} for ${customerName}`,
      at: now,
      bookingRef: reference,
      read: false,
    });
    tx.set(db.collection("activity").doc(), {
      kind: "request",
      title: "Booking request",
      subtitle: `${p.serviceName} · ${when}`,
      at: now,
      bookingRef: reference,
      read: false,
    });

    tx.update(paymentRef, {
      status: "paid",
      amountPaid: amountPaid ?? p.amount,
      paymentIntentId,
      methodLabel,
      bookingRef: reference,
      paidAt: now,
    });
  });
}

// ─────────────────────────────────────────────────────────────
// 4. Page Stripe sends the customer back to after paying / cancelling.
// ─────────────────────────────────────────────────────────────
exports.paymentReturn = onRequest((req, res) => {
  const ok = req.query.result === "success";
  const title = ok ? "Payment complete" : "Payment cancelled";
  const msg = ok
    ? "Thank you! Your deposit has been paid. You can close this page and return to the app."
    : "No payment was taken. You can close this page and return to the app.";
  res.set("Content-Type", "text/html; charset=utf-8").send(`<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<style>body{font-family:-apple-system,system-ui,sans-serif;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px;background:#faf7f2;color:#222;text-align:center}h1{font-size:24px}p{color:#666;max-width:340px;line-height:1.5}</style>
</head><body><div><h1>${title}</h1><p>${msg}</p></div>
<script>setTimeout(function(){window.close()},2500)</script></body></html>`);
});
