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

  const updates: Record<string, any> = {
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
    updates['quotation.status'] = 'pending';
    updates.quotationStatus = 'pending';
  } else if (targetStatus === 'WORK_IN_PROGRESS') {
    const quoteTotal = currentJob.quoteTotal || 0;
    const visitingFee = currentJob.visitingFee || 199.0;
    const isFeePaid = currentJob.isVisitingFeePaid || false;
    updates.finalAmountPaid = quoteTotal + (isFeePaid ? 0 : visitingFee);
    updates.isVisitingFeePaid = true;
    updates.isFinalBillPaid = true;
    updates['quotation.status'] = 'approved';
    updates.quotationStatus = 'approved';
  } else if (targetStatus === 'QUOTATION_REJECTED') {
    // Inspection-only completion
    const visitingFee = currentJob.visitingFee || 199.0;
    const isFeePaid = currentJob.isVisitingFeePaid || false;
    updates.finalAmountPaid = visitingFee;
    updates.isFinalBillPaid = isFeePaid;
    updates['quotation.status'] = 'rejected';
    updates.quotationStatus = 'rejected';
    if (isFeePaid) {
      updates.status = 'PAID_AND_CLOSED';
    }
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

  // Dispatch push notifications to Customer and/or Technician based on new status
  const customerId = currentJob.customerId;
  const providerId = currentJob.providerId;
  const jobTitle = currentJob.title || 'Service Request';

  const statusMessages: Record<string, { title: string; body: string }> = {
    ACCEPTED: { title: 'Technician Assigned', body: `A technician has accepted your ${jobTitle} request.` },
    IN_TRANSIT: { title: 'Technician En Route', body: 'Your technician is on the way.' },
    ARRIVED: { title: 'Technician Arrived', body: 'Your technician has arrived at your location.' },
    INSPECTION_IN_PROGRESS: { title: 'Inspection Started', body: 'Technician has started inspecting your appliance.' },
    QUOTATION_PENDING_APPROVAL: { title: 'Quotation Ready', body: `Quotation submitted for ₹${updates.quoteTotal || currentJob.quoteTotal || 0}. Please review.` },
    WORK_IN_PROGRESS: { title: 'Work Started', body: 'Technician has started the repair work.' },
    WORK_COMPLETED: { title: 'Work Completed', body: 'Repair work completed. Please review and complete payment.' },
    PAID_AND_CLOSED: { title: 'Job Completed & Paid', body: 'Thank you! Your service job is closed.' },
    CANCELLED_BY_CUSTOMER: { title: 'Job Cancelled', body: `Service request for ${jobTitle} was cancelled.` },
    CANCELLED_BY_TECHNICIAN: { title: 'Job Re-broadcasting', body: 'Assigned technician cancelled. Finding a new provider for you.' },
  };

  const msg = statusMessages[targetStatus];
  if (msg) {
    const timestamp = Date.now();
    if (customerId) {
      const notifId = `notif_u_${timestamp}`;
      await db.collection('users').doc(customerId).collection('notifications').doc(notifId).set({
        id: notifId,
        userId: customerId,
        title: msg.title,
        body: msg.body,
        data: { jobId, type: 'JOB_STATUS_UPDATE', status: targetStatus },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (providerId && targetStatus !== 'CANCELLED_BY_TECHNICIAN') {
      const notifId = `notif_t_${timestamp}`;
      await db.collection('providers').doc(providerId).collection('notifications').doc(notifId).set({
        id: notifId,
        techId: providerId,
        title: msg.title,
        body: msg.body,
        data: { jobId, type: 'JOB_STATUS_UPDATE', status: targetStatus },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  return { success: true, newStatus: targetStatus };
});

