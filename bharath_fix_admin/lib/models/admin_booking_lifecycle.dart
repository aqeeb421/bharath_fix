import 'package:flutter/material.dart';

/// Discrete Booking Lifecycle & Edge Case States for Admin Portal
enum AdminBookingStatus {
  draft,
  booked,
  unfulfilledRefunded,
  accepted,
  onTheWay,
  arrived,
  customerUnreachable,
  inspectionInProgress,
  quotationPending,
  quotationRejected,
  visitOnlyCompleted,
  incrementalQuotePending,
  repairInProgress,
  partsAwaitedPaused,
  unrepairableClosed,
  categoryReclassified,
  safetyHaltCancelled,
  cancelledEnroute,
  cancelledAtSite,
  paymentPendingVerification,
  completed,
  reviewed,
  warrantyClaimed,
  warrantyReworkAssigned,
  warrantyRefunded,
  rePooled,
  adminAuditHold;

  String get code {
    switch (this) {
      case AdminBookingStatus.draft:
        return 'draft';
      case AdminBookingStatus.booked:
        return 'booked';
      case AdminBookingStatus.unfulfilledRefunded:
        return 'unfulfilled_refunded';
      case AdminBookingStatus.accepted:
        return 'accepted';
      case AdminBookingStatus.onTheWay:
        return 'on_the_way';
      case AdminBookingStatus.arrived:
        return 'arrived';
      case AdminBookingStatus.customerUnreachable:
        return 'customer_unreachable';
      case AdminBookingStatus.inspectionInProgress:
        return 'inspection_in_progress';
      case AdminBookingStatus.quotationPending:
        return 'quotation_pending';
      case AdminBookingStatus.quotationRejected:
        return 'quotation_rejected';
      case AdminBookingStatus.visitOnlyCompleted:
        return 'visit_only_completed';
      case AdminBookingStatus.incrementalQuotePending:
        return 'incremental_quote_pending';
      case AdminBookingStatus.repairInProgress:
        return 'repair_in_progress';
      case AdminBookingStatus.partsAwaitedPaused:
        return 'parts_awaited_paused';
      case AdminBookingStatus.unrepairableClosed:
        return 'unrepairable_closed';
      case AdminBookingStatus.categoryReclassified:
        return 'category_reclassified';
      case AdminBookingStatus.safetyHaltCancelled:
        return 'safety_halt_cancelled';
      case AdminBookingStatus.cancelledEnroute:
        return 'cancelled_enroute';
      case AdminBookingStatus.cancelledAtSite:
        return 'cancelled_at_site';
      case AdminBookingStatus.paymentPendingVerification:
        return 'payment_pending_verification';
      case AdminBookingStatus.completed:
        return 'completed';
      case AdminBookingStatus.reviewed:
        return 'reviewed';
      case AdminBookingStatus.warrantyClaimed:
        return 'warranty_claimed';
      case AdminBookingStatus.warrantyReworkAssigned:
        return 'warranty_rework_assigned';
      case AdminBookingStatus.warrantyRefunded:
        return 'warranty_refunded';
      case AdminBookingStatus.rePooled:
        return 're_pooled';
      case AdminBookingStatus.adminAuditHold:
        return 'admin_audit_hold';
    }
  }

  String get label {
    switch (this) {
      case AdminBookingStatus.draft:
        return 'Draft';
      case AdminBookingStatus.booked:
        return 'Booked & Paid';
      case AdminBookingStatus.unfulfilledRefunded:
        return 'Unfulfilled (Auto-Refunded)';
      case AdminBookingStatus.accepted:
        return 'Partner Assigned';
      case AdminBookingStatus.onTheWay:
        return 'On The Way';
      case AdminBookingStatus.arrived:
        return 'Arrived At Site';
      case AdminBookingStatus.customerUnreachable:
        return 'Customer Unreachable 📵';
      case AdminBookingStatus.inspectionInProgress:
        return 'Inspecting';
      case AdminBookingStatus.quotationPending:
        return 'Quote Pending Approval';
      case AdminBookingStatus.quotationRejected:
        return 'Quote Rejected ❌';
      case AdminBookingStatus.visitOnlyCompleted:
        return 'Visit Only (Quote Declined)';
      case AdminBookingStatus.incrementalQuotePending:
        return 'Incremental Quote Pending ⚙️';
      case AdminBookingStatus.repairInProgress:
        return 'Repair In Progress';
      case AdminBookingStatus.partsAwaitedPaused:
        return 'Parts Awaited (Paused)';
      case AdminBookingStatus.unrepairableClosed:
        return 'Unrepairable / BER Closed';
      case AdminBookingStatus.categoryReclassified:
        return 'Category Reclassified 🔄';
      case AdminBookingStatus.safetyHaltCancelled:
        return 'Safety Hazard Halt ⚠️';
      case AdminBookingStatus.cancelledEnroute:
        return 'Cancelled En Route';
      case AdminBookingStatus.cancelledAtSite:
        return 'Cancelled At Site';
      case AdminBookingStatus.paymentPendingVerification:
        return 'Payment Pending Verification ⏳';
      case AdminBookingStatus.completed:
        return 'Completed';
      case AdminBookingStatus.reviewed:
        return 'Reviewed';
      case AdminBookingStatus.warrantyClaimed:
        return 'Warranty Claim Active';
      case AdminBookingStatus.warrantyReworkAssigned:
        return 'Warranty Rework Assigned';
      case AdminBookingStatus.warrantyRefunded:
        return 'Warranty Refund Issued';
      case AdminBookingStatus.rePooled:
        return 'Emergency Released (Re-pooled)';
      case AdminBookingStatus.adminAuditHold:
        return 'Admin Audit Hold 🚨';
    }
  }

  Color get color {
    switch (this) {
      case AdminBookingStatus.draft:
        return Colors.grey;
      case AdminBookingStatus.booked:
        return const Color(0xFF000062);
      case AdminBookingStatus.unfulfilledRefunded:
        return Colors.red.shade700;
      case AdminBookingStatus.accepted:
        return Colors.blue.shade700;
      case AdminBookingStatus.onTheWay:
        return Colors.orange.shade800;
      case AdminBookingStatus.arrived:
        return Colors.purple.shade700;
      case AdminBookingStatus.customerUnreachable:
        return Colors.red.shade800;
      case AdminBookingStatus.inspectionInProgress:
        return Colors.amber.shade900;
      case AdminBookingStatus.quotationPending:
        return Colors.amber.shade800;
      case AdminBookingStatus.quotationRejected:
        return Colors.red.shade700;
      case AdminBookingStatus.visitOnlyCompleted:
        return Colors.teal.shade700;
      case AdminBookingStatus.incrementalQuotePending:
        return Colors.amber.shade900;
      case AdminBookingStatus.repairInProgress:
        return Colors.orange.shade900;
      case AdminBookingStatus.partsAwaitedPaused:
        return Colors.indigo.shade600;
      case AdminBookingStatus.unrepairableClosed:
        return Colors.grey.shade800;
      case AdminBookingStatus.categoryReclassified:
        return Colors.deepPurple.shade700;
      case AdminBookingStatus.safetyHaltCancelled:
        return Colors.red.shade900;
      case AdminBookingStatus.cancelledEnroute:
      case AdminBookingStatus.cancelledAtSite:
        return Colors.red.shade700;
      case AdminBookingStatus.paymentPendingVerification:
        return Colors.amber.shade800;
      case AdminBookingStatus.completed:
        return Colors.green.shade700;
      case AdminBookingStatus.reviewed:
        return Colors.green.shade800;
      case AdminBookingStatus.warrantyClaimed:
      case AdminBookingStatus.warrantyReworkAssigned:
      case AdminBookingStatus.warrantyRefunded:
        return Colors.indigo.shade800;
      case AdminBookingStatus.rePooled:
        return Colors.blue.shade800;
      case AdminBookingStatus.adminAuditHold:
        return Colors.deepOrange.shade800;
    }
  }

  static AdminBookingStatus parse(String? rawStatus) {
    if (rawStatus == null) return AdminBookingStatus.booked;
    final st = rawStatus.trim().toLowerCase();

    if (st == 'draft') return AdminBookingStatus.draft;
    if (st == 'booked') return AdminBookingStatus.booked;
    if (st == 'unfulfilled_refunded' || st == 'expired_refunded') return AdminBookingStatus.unfulfilledRefunded;
    if (st == 'accepted' || st == 'assigned') return AdminBookingStatus.accepted;
    if (st == 'on_the_way' || st == 'in_transit') return AdminBookingStatus.onTheWay;
    if (st == 'arrived' || st == 'at_location') return AdminBookingStatus.arrived;
    if (st == 'customer_unreachable') return AdminBookingStatus.customerUnreachable;
    if (st == 'inspection_in_progress' || st == 'inspecting') return AdminBookingStatus.inspectionInProgress;
    if (st == 'quotation_pending' || st == 'quotation_pending_approval') return AdminBookingStatus.quotationPending;
    if (st == 'quotation_rejected' || st == 'quote_rejected') return AdminBookingStatus.quotationRejected;
    if (st == 'visit_only_completed') return AdminBookingStatus.visitOnlyCompleted;
    if (st == 'incremental_quote_pending') return AdminBookingStatus.incrementalQuotePending;
    if (st == 'repair_in_progress' || st == 'in_progress' || st == 'work_started') return AdminBookingStatus.repairInProgress;
    if (st == 'parts_awaited_paused' || st == 'parts_awaited') return AdminBookingStatus.partsAwaitedPaused;
    if (st == 'unrepairable_closed' || st == 'ber_closed') return AdminBookingStatus.unrepairableClosed;
    if (st == 'category_reclassified') return AdminBookingStatus.categoryReclassified;
    if (st == 'safety_halt_cancelled') return AdminBookingStatus.safetyHaltCancelled;
    if (st == 'cancelled_enroute') return AdminBookingStatus.cancelledEnroute;
    if (st == 'cancelled_at_site') return AdminBookingStatus.cancelledAtSite;
    if (st == 'payment_pending_verification') return AdminBookingStatus.paymentPendingVerification;
    if (st == 'completed' || st == 'paid_and_closed') return AdminBookingStatus.completed;
    if (st == 'reviewed' || st == 'rating_given') return AdminBookingStatus.reviewed;
    if (st == 'warranty_claimed' || st == 'under_warranty') return AdminBookingStatus.warrantyClaimed;
    if (st == 'warranty_rework_assigned') return AdminBookingStatus.warrantyReworkAssigned;
    if (st == 'warranty_refunded') return AdminBookingStatus.warrantyRefunded;
    if (st == 're_pooled' || st == 'released') return AdminBookingStatus.rePooled;
    if (st == 'admin_audit_hold') return AdminBookingStatus.adminAuditHold;

    return AdminBookingStatus.booked;
  }
}
