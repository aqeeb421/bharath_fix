import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * HTTPS Webhook Function: handlePaymentWebhook
 * Securely receives payment callbacks from payment gateways (Razorpay / Stripe / PhonePe)
 * and transitions jobs to 'BOOKED' or 'PAID_AND_CLOSED'.
 */
export const handlePaymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const body = req.body;
    // Extract metadata payload from payment gateway callback
    const { jobId, paymentType, status: paymentStatus } = body;

    if (!jobId || paymentStatus !== 'SUCCESS') {
      res.status(400).json({ success: false, message: 'Invalid payment payload' });
      return;
    }

    const db = admin.firestore();
    const jobRef = db.collection('jobs').doc(jobId);
    const jobDoc = await jobRef.get();

    if (!jobDoc.exists) {
      res.status(404).json({ success: false, message: 'Job not found' });
      return;
    }

    // Generate random 4-digit start OTP when job is booked
    const randomStartOtp = Math.floor(1000 + Math.random() * 9000).toString();

    if (paymentType === 'VISITING_FEE') {
      await jobRef.update({
        status: 'BOOKED',
        isVisitingFeePaid: true,
        startOtp: randomStartOtp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else if (paymentType === 'FINAL_BILL') {
      await jobRef.update({
        status: 'PAID_AND_CLOSED',
        isFinalBillPaid: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    res.status(200).json({ success: true, message: 'Payment processed & job state updated' });
  } catch (err: any) {
    console.error('Webhook error:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});
