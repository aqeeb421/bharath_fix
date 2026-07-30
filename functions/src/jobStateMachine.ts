import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export type JobStatus =
  | 'DRAFT'
  | 'PENDING_PAYMENT'
  | 'BOOKED'
  | 'ACCEPTED'
  | 'IN_TRANSIT'
  | 'ARRIVED'
  | 'INSPECTION_IN_PROGRESS'
  | 'QUOTATION_PENDING_APPROVAL'
  | 'QUOTATION_REJECTED'
  | 'WORK_IN_PROGRESS'
  | 'WORK_COMPLETED'
  | 'PAID_AND_CLOSED'
  | 'CANCELLED_BY_CUSTOMER'
  | 'CANCELLED_BY_TECHNICIAN'
  | 'UNASSIGNED_EXPIRED'
  | 'PAUSED_PARTS_SOURCING'
  | 'WARRANTY_CLAIM';

const VALID_TRANSITIONS: Record<JobStatus, JobStatus[]> = {
  DRAFT: ['PENDING_PAYMENT', 'CANCELLED_BY_CUSTOMER'],
  PENDING_PAYMENT: ['BOOKED', 'CANCELLED_BY_CUSTOMER'],
  BOOKED: ['ACCEPTED', 'UNASSIGNED_EXPIRED', 'CANCELLED_BY_CUSTOMER'],
  ACCEPTED: ['IN_TRANSIT', 'CANCELLED_BY_TECHNICIAN', 'CANCELLED_BY_CUSTOMER'],
  IN_TRANSIT: ['ARRIVED', 'CANCELLED_BY_TECHNICIAN', 'CANCELLED_BY_CUSTOMER'],
  ARRIVED: ['INSPECTION_IN_PROGRESS', 'CANCELLED_BY_CUSTOMER'],
  INSPECTION_IN_PROGRESS: ['QUOTATION_PENDING_APPROVAL', 'CANCELLED_BY_CUSTOMER'],
  QUOTATION_PENDING_APPROVAL: ['WORK_IN_PROGRESS', 'QUOTATION_REJECTED', 'CANCELLED_BY_CUSTOMER'],
  QUOTATION_REJECTED: ['PAID_AND_CLOSED'], // Converted to inspection-only closed
  WORK_IN_PROGRESS: ['PAUSED_PARTS_SOURCING', 'WORK_COMPLETED', 'CANCELLED_BY_CUSTOMER'],
  PAUSED_PARTS_SOURCING: ['WORK_IN_PROGRESS'],
  WORK_COMPLETED: ['PAID_AND_CLOSED'],
  PAID_AND_CLOSED: ['WARRANTY_CLAIM'],
  CANCELLED_BY_CUSTOMER: [],
  CANCELLED_BY_TECHNICIAN: ['BOOKED'], // Re-broadcast job
  UNASSIGNED_EXPIRED: [],
  WARRANTY_CLAIM: ['ACCEPTED'],
};

/**
 * Callable Function: updateJobStatus
 * Enforces valid state transitions and performs side-effects (e.g. OTP check, wallet math, refund calculations)
 */
export const updateJobStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { jobId, targetStatus, otp, quoteItems } = data;
  if (!jobId || !targetStatus) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing jobId or targetStatus');
  }

  const db = admin.firestore();
  const jobRef = db.collection('jobs').doc(jobId);
  const jobDoc = await jobRef.get();

  if (!jobDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Job not found');
  }

  const currentJob = jobDoc.data()!;
  const currentStatus: JobStatus = currentJob.status || 'DRAFT';
  const allowedNextStatuses = VALID_TRANSITIONS[currentStatus] || [];

  if (!allowedNextStatuses.includes(targetStatus as JobStatus)) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Cannot transition job from ${currentStatus} to ${targetStatus}`
    );
  }

  const updates: Record<String, any> = {
    status: targetStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Specific Business Rules per State Transition
  if (targetStatus === 'INSPECTION_IN_PROGRESS') {
    // Requires startOtp validation
    if (otp !== currentJob.startOtp) {
      throw new functions.https.HttpsError('permission-denied', 'Invalid 4-digit start OTP');
    }
  } else if (targetStatus === 'QUOTATION_PENDING_APPROVAL') {
    if (!quoteItems || !Array.isArray(quoteItems) || quoteItems.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Quotation must include at least 1 item');
    }
    const quoteTotal = quoteItems.reduce((acc: number, item: any) => acc + (item.price || 0), 0);
    updates.quoteItems = quoteItems;
    updates.quoteTotal = quoteTotal;
  } else if (targetStatus === 'QUOTATION_REJECTED') {
    // Inspection-only completion
    updates.finalAmountPaid = currentJob.visitingFee || 199.0;
    updates.isFinalBillPaid = true;
  } else if (targetStatus === 'CANCELLED_BY_CUSTOMER') {
    // Compute refund policy
    let refundAmount = 0;
    if (currentStatus === 'BOOKED' || currentStatus === 'PENDING_PAYMENT') {
      refundAmount = currentJob.visitingFee || 199.0; // 100% refund
    } else if (currentStatus === 'IN_TRANSIT') {
      refundAmount = (currentJob.visitingFee || 199.0) * 0.5; // 50% refund, remainder to tech
    } else {
      refundAmount = 0; // Forfeited after arrival
    }
    updates.refundAmount = refundAmount;
    updates.cancelledAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await jobRef.update(updates);
  return { success: true, newStatus: targetStatus };
});
