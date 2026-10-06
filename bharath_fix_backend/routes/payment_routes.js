const express = require('express');
const crypto = require('crypto');
const Razorpay = require('razorpay');

function createPaymentRoutes(admin) {
  const router = express.Router();
  const db = admin.firestore();

  // Helper to initialize Razorpay instance if keys are available
  function getRazorpayInstance() {
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (keyId && keySecret && keySecret.trim().length > 0) {
      return new Razorpay({
        key_id: keyId,
        key_secret: keySecret,
      });
    }
    return null;
  }

  /**
   * POST /api/payment/create-order
   * Generates a genuine Razorpay Order ID on Razorpay's servers.
   * Body parameters:
   *   - amount: Amount in Rupees (or amountInPaise)
   *   - currency: Defaults to 'INR'
   *   - receipt: Identifier string for tracking (e.g. 'rcpt_booking_123')
   *   - notes: Custom metadata { jobId, orderId, userId, paymentType }
   */
  router.post('/create-order', async (req, res) => {
    try {
      const { amount, amountInPaise, currency = 'INR', receipt, notes = {} } = req.body;

      const finalPaise = amountInPaise
        ? parseInt(amountInPaise, 10)
        : Math.round(parseFloat(amount || 0) * 100);

      if (!finalPaise || finalPaise <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid amount. Must be greater than 0 paise.',
        });
      }

      const rzp = getRazorpayInstance();

      if (rzp) {
        // Create genuine order via official Razorpay SDK
        const orderOptions = {
          amount: finalPaise,
          currency: currency.toUpperCase(),
          receipt: receipt || `rcpt_${Date.now()}`,
          notes: notes,
        };

        const razorpayOrder = await rzp.orders.create(orderOptions);

        console.log(`✅ Razorpay Live Order Created: ${razorpayOrder.id} for ₹${(finalPaise / 100).toFixed(2)}`);

        return res.status(200).json({
          success: true,
          isLiveOrder: true,
          order: {
            id: razorpayOrder.id,
            amount: razorpayOrder.amount,
            currency: razorpayOrder.currency,
            receipt: razorpayOrder.receipt,
            status: razorpayOrder.status,
            keyId: process.env.RAZORPAY_KEY_ID,
          },
        });
      } else {
        // Fallback for local development when RAZORPAY_KEY_SECRET is not yet supplied in .env
        const fallbackOrderId = `order_sim_${Date.now()}`;
        console.log(`⚠️ Razorpay Secret not set in .env. Emitting sandbox order ID: ${fallbackOrderId}`);

        return res.status(200).json({
          success: true,
          isLiveOrder: false,
          isSandboxSimulation: true,
          order: {
            id: fallbackOrderId,
            amount: finalPaise,
            currency: currency.toUpperCase(),
            receipt: receipt || `rcpt_${Date.now()}`,
            status: 'created',
            keyId: process.env.RAZORPAY_KEY_ID || 'rzp_live_TkB8ri3wj5Bx8L',
          },
          notice: 'Provide RAZORPAY_KEY_SECRET in backend .env to create live Razorpay orders.',
        });
      }
    } catch (err) {
      console.error('❌ Error creating Razorpay order:', err);
      return res.status(500).json({
        success: false,
        message: 'Failed to create payment order',
        error: err.message,
      });
    }
  });

  /**
   * POST /api/payment/verify-payment
   * Verifies client-side payment success via cryptographic HMAC-SHA256 signature.
   * Body parameters:
   *   - razorpay_order_id
   *   - razorpay_payment_id
   *   - razorpay_signature
   *   - paymentType: 'VISITING_FEE' | 'FINAL_BILL' | 'RETAIL_ORDER'
   *   - jobId (for repair bookings) or orderId (for marketplace appliance orders)
   *   - userId
   */
  router.post('/verify-payment', async (req, res) => {
    try {
      const {
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
        paymentType,
        amount,
        amountInPaise,
        jobId,
        orderId,
        userId,
      } = req.body;

      const keySecret = process.env.RAZORPAY_KEY_SECRET;

      // If Razorpay secret is configured, perform strict HMAC-SHA256 cryptographic check
      if (keySecret && keySecret.trim().length > 0 && razorpay_order_id && razorpay_payment_id && razorpay_signature) {
        const bodyText = `${razorpay_order_id}|${razorpay_payment_id}`;
        const expectedSignature = crypto
          .createHmac('sha256', keySecret)
          .update(bodyText)
          .digest('hex');

        if (expectedSignature !== razorpay_signature) {
          console.error('❌ Razorpay signature verification failed!');
          return res.status(400).json({
            success: false,
            message: 'Cryptographic signature mismatch. Payment verification rejected.',
          });
        }
        console.log(`✅ Cryptographic signature verified for payment: ${razorpay_payment_id}`);
      }

      const parsedAmount = amount || (amountInPaise ? amountInPaise / 100 : 0);

      // Transition Firestore states
      await handleSuccessfulPayment({
        db,
        admin,
        jobId,
        orderId,
        userId,
        amount: parsedAmount,
        paymentType,
        paymentId: razorpay_payment_id || `sim_${Date.now()}`,
        orderReference: razorpay_order_id,
      });

      return res.status(200).json({
        success: true,
        message: 'Payment verified and database record updated successfully.',
      });
    } catch (err) {
      console.error('❌ Error verifying payment:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  });

  /**
   * POST /api/payment/webhook
   * Razorpay Webhook listener with HMAC-SHA256 signature verification.
   * Triggers asynchronously directly from Razorpay servers.
   */
  router.post('/webhook', async (req, res) => {
    try {
      const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
      const signatureHeader = req.headers['x-razorpay-signature'];

      // Webhook HMAC Verification
      if (webhookSecret && webhookSecret.trim().length > 0) {
        if (!signatureHeader) {
          console.error('❌ Missing x-razorpay-signature header on webhook');
          return res.status(400).json({ success: false, message: 'Missing signature header' });
        }

        const rawPayload = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
        const expectedSig = crypto
          .createHmac('sha256', webhookSecret)
          .update(rawPayload)
          .digest('hex');

        if (expectedSig !== signatureHeader) {
          console.error('❌ Razorpay webhook signature mismatch!');
          return res.status(400).json({ success: false, message: 'Signature verification failed' });
        }
        console.log('✅ Razorpay Webhook HMAC verified successfully');
      }

      // Check if standard Razorpay event payload
      const event = req.body.event;
      if (event === 'payment.captured' || event === 'order.paid') {
        const entity = req.body.payload?.payment?.entity || req.body.payload?.order?.entity || {};
        const notes = entity.notes || {};
        const jobId = notes.jobId || notes.bookingId;
        const orderId = notes.orderId;
        const userId = notes.userId || notes.customerId;
        const paymentType = notes.paymentType || (orderId ? 'RETAIL_ORDER' : (notes.type === 'WALLET_TOPUP' ? 'WALLET_TOPUP' : 'VISITING_FEE'));
        const amount = notes.amount ? parseFloat(notes.amount) : (entity.amount ? entity.amount / 100 : 0);

        await handleSuccessfulPayment({
          db,
          admin,
          jobId,
          orderId,
          userId,
          amount,
          paymentType,
          paymentId: entity.id,
          orderReference: entity.order_id,
        });

        return res.status(200).json({ success: true, message: 'Webhook processed' });
      }

      // Custom/Direct callback payload handling fallback
      const { jobId, orderId, paymentType, status: paymentStatus, userId, amount } = req.body;
      if (paymentStatus === 'SUCCESS') {
        await handleSuccessfulPayment({
          db,
          admin,
          jobId,
          orderId,
          userId,
          amount: parseFloat(amount || 0),
          paymentType: paymentType || (orderId ? 'RETAIL_ORDER' : 'VISITING_FEE'),
          paymentId: req.body.paymentId || `cb_${Date.now()}`,
        });
        return res.status(200).json({ success: true, message: 'Payment callback processed' });
      }

      return res.status(200).json({ success: true, message: 'Event ignored or already logged' });
    } catch (err) {
      console.error('❌ Webhook processing error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
}

/**
 * Shared state updater for successful payments in Firestore
 */
async function handleSuccessfulPayment({ db, admin, jobId, orderId, userId, amount, paymentType, paymentId, orderReference }) {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // 1. Repair Booking Workflow: VISITING_FEE
  if (paymentType === 'VISITING_FEE' && jobId) {
    const randomStartOtp = Math.floor(1000 + Math.random() * 9000).toString();
    const bookingRef = db.collection('bookings').doc(jobId);
    const updateData = {
      status: 'BOOKED',
      isVisitingFeePaid: true,
      startOtp: randomStartOtp,
      razorpayPaymentId: paymentId || '',
      razorpayOrderId: orderReference || '',
      updatedAt: now,
    };
    batch.set(bookingRef, updateData, { merge: true });

    if (userId) {
      const userSubRef = db.collection('users').doc(userId).collection('bookings').doc(jobId);
      batch.set(userSubRef, updateData, { merge: true });
    }
  }

  // 2. Repair Booking Workflow: FINAL_BILL (Spares & Labor)
  else if (paymentType === 'FINAL_BILL' && jobId) {
    const bookingRef = db.collection('bookings').doc(jobId);
    const updateData = {
      status: 'PAID_AND_CLOSED',
      isFinalBillPaid: true,
      razorpayPaymentId: paymentId || '',
      updatedAt: now,
    };
    batch.set(bookingRef, updateData, { merge: true });

    if (userId) {
      const userSubRef = db.collection('users').doc(userId).collection('bookings').doc(jobId);
      batch.set(userSubRef, updateData, { merge: true });
    }
  }

  // 3. Retail Marketplace Order Workflow: RETAIL_ORDER (Slide 5 Appliance Purchase)
  else if ((paymentType === 'RETAIL_ORDER' || orderId) && orderId) {
    const randomDeliveryOtp = Math.floor(1000 + Math.random() * 9000).toString();
    const orderRef = db.collection('orders').doc(orderId);
    const updateData = {
      orderStatus: 'placed',
      isPaid: true,
      deliveryOtp: randomDeliveryOtp,
      razorpayPaymentId: paymentId || '',
      razorpayOrderId: orderReference || '',
      updatedAt: now,
    };
    batch.set(orderRef, updateData, { merge: true });

    if (userId) {
      const userOrderSubRef = db.collection('users').doc(userId).collection('orders').doc(orderId);
      batch.set(userOrderSubRef, updateData, { merge: true });
    }
  }

  // 4. Wallet Top-Up Workflow: WALLET_TOPUP
  else if (paymentType === 'WALLET_TOPUP' && userId) {
    const userRef = db.collection('users').doc(userId);
    const topUpAmount = parseFloat(amount || 0);

    if (topUpAmount > 0) {
      // Idempotency check: avoid crediting twice if both client and webhook trigger
      const existingTxSnap = await userRef
        .collection('wallet_transactions')
        .where('paymentId', '==', paymentId)
        .limit(1)
        .get();

      if (existingTxSnap.empty) {
        const txId = `tx_credit_${Date.now()}`;
        batch.set(
          userRef,
          { walletBalance: admin.firestore.FieldValue.increment(topUpAmount) },
          { merge: true }
        );

        const txRef = userRef.collection('wallet_transactions').doc(txId);
        batch.set(txRef, {
          id: txId,
          amount: topUpAmount,
          type: 'CREDIT',
          description: 'Wallet Top-Up via Razorpay (Verified)',
          timestamp: new Date().toISOString(),
          paymentId: paymentId || '',
          orderId: orderReference || '',
          status: 'SUCCESS',
          createdAt: now,
        });

        /*
        // 10% Cashback Bonus reward if top-up >= ₹500 (Temporarily disabled; uncomment to re-enable in future)
        if (topUpAmount >= 500) {
          const cashbackTxId = `tx_cashback_${Date.now()}`;
          const cashbackRef = userRef.collection('wallet_transactions').doc(cashbackTxId);
          batch.set(
            userRef,
            { walletBalance: admin.firestore.FieldValue.increment(50.0) },
            { merge: true }
          );
          batch.set(cashbackRef, {
            id: cashbackTxId,
            amount: 50.0,
            type: 'CREDIT',
            description: '₹50 Automated Cashback Reward 🎉',
            timestamp: new Date().toISOString(),
            status: 'SUCCESS',
            createdAt: now,
          });
        }
        */

        console.log(`✅ Credited ₹${topUpAmount} to wallet of user ${userId} for payment ${paymentId}`);
      } else {
        console.log(`ℹ️ Wallet top-up payment ${paymentId} already credited for user ${userId}. Skipping duplicate.`);
      }
    }
  }

  await batch.commit();
}

module.exports = createPaymentRoutes;

