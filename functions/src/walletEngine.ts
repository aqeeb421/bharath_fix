import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Firestore Trigger: onJobCompleted
 * Triggers when job status transitions to 'PAID_AND_CLOSED' or 'QUOTATION_REJECTED'.
 * Calculates platform commission (15%), credits technician wallet balance, or logs COD collection.
 */
export const onJobCompleted = functions.firestore
  .document('jobs/{jobId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    const isNewlyCompleted =
      beforeData.status !== 'PAID_AND_CLOSED' && afterData.status === 'PAID_AND_CLOSED';

    if (isNewlyCompleted) {
      const providerId = afterData.providerId;
      if (!providerId) return;

      const db = admin.firestore();
      const providerRef = db.collection('providers').doc(providerId);

      const quoteTotal = afterData.quoteTotal || afterData.visitingFee || 199.0;
      const commissionRate = 0.15; // 15% default platform commission
      const platformFee = quoteTotal * commissionRate;
      const technicianEarnings = quoteTotal - platformFee;

      const isCOD = afterData.paymentMode === 'COD';

      await db.runTransaction(async (transaction) => {
        const providerDoc = await transaction.get(providerRef);
        if (!providerDoc.exists) return;

        const currentData = providerDoc.data()!;
        const currentWalletBalance = currentData.walletBalance || 0;
        const currentCodDebt = currentData.codDebt || 0;

        let newWalletBalance = currentWalletBalance;
        let newCodDebt = currentCodDebt;

        if (isCOD) {
          // Tech collected full cash, owes platform fee
          newCodDebt += platformFee;
        } else {
          // Online payment collected by platform, credit tech net earnings
          newWalletBalance += technicianEarnings;
        }

        // COD Safety Threshold check ($100 / ₹5000)
        const codThreshold = 5000;
        const isDutyBlocked = newCodDebt >= codThreshold;

        transaction.update(providerRef, {
          walletBalance: newWalletBalance,
          codDebt: newCodDebt,
          isDutyBlocked: isDutyBlocked,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Add ledger entry
        const ledgerRef = db.collection('providers').doc(providerId).collection('walletLedger').doc();
        transaction.set(ledgerRef, {
          jobId: context.params.jobId,
          type: isCOD ? 'COD_COMMISSION_DEBIT' : 'JOB_EARNINGS_CREDIT',
          amount: isCOD ? -platformFee : technicianEarnings,
          grossAmount: quoteTotal,
          platformFee: platformFee,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`Updated wallet for provider ${providerId} for job ${context.params.jobId}`);
    }
  });
