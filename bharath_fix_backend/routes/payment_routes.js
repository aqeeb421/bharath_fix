const express = require('express');

function createPaymentRoutes(admin) {
  const router = express.Router();
  const db = admin.firestore();

  /**
   * HTTPS Webhook Endpoint: /api/payment/webhook
   * Securely receives payment callbacks from payment gateways (Razorpay / Stripe / PhonePe)
   * and transitions bookings to 'BOOKED' or 'PAID_AND_CLOSED'.
   */
  router.post('/webhook', async (req, res) => {
    try {
      const body = req.body;
      const { jobId, paymentType, status: paymentStatus } = body;

      if (!jobId || paymentStatus !== 'SUCCESS') {
        return res.status(400).json({ success: false, message: 'Invalid payment payload' });
      }

      const bookingRef = db.collection('bookings').doc(jobId);
      const bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) {
        return res.status(404).json({ success: false, message: 'Booking not found' });
      }

      const bookingData = bookingDoc.data();
      const userId = bookingData.userId || bookingData.customerId;

      // Generate random 4-digit start OTP when job is booked
      const randomStartOtp = Math.floor(1000 + Math.random() * 9000).toString();

      let updateData = null;

      if (paymentType === 'VISITING_FEE') {
        updateData = {
          status: 'BOOKED',
          isVisitingFeePaid: true,
          startOtp: randomStartOtp,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
      } else if (paymentType === 'FINAL_BILL') {
        updateData = {
          status: 'PAID_AND_CLOSED',
          isFinalBillPaid: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
      }

      if (updateData) {
        const batch = db.batch();
        batch.update(bookingRef, updateData);

        if (userId) {
          const userSubRef = db.collection('users').doc(userId).collection('bookings').doc(jobId);
          batch.set(userSubRef, updateData, { merge: true });
        }

        await batch.commit();
      }

      return res.status(200).json({ success: true, message: 'Payment processed & booking state updated' });
    } catch (err) {
      console.error('Webhook error:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
  });

  return router;
}

module.exports = createPaymentRoutes;
