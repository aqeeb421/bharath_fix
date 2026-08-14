import 'package:flutter/material.dart';

/// Discrete Booking Lifecycle & Edge Case States across BharathFix Ecosystem
enum BookingLifecycleState {
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
      case BookingLifecycleState.draft:
        return 'draft';
      case BookingLifecycleState.booked:
        return 'booked';
      case BookingLifecycleState.unfulfilledRefunded:
        return 'unfulfilled_refunded';
      case BookingLifecycleState.accepted:
        return 'accepted';
      case BookingLifecycleState.onTheWay:
        return 'on_the_way';
      case BookingLifecycleState.arrived:
        return 'arrived';
      case BookingLifecycleState.customerUnreachable:
        return 'customer_unreachable';
      case BookingLifecycleState.inspectionInProgress:
        return 'inspection_in_progress';
      case BookingLifecycleState.quotationPending:
        return 'quotation_pending';
      case BookingLifecycleState.quotationRejected:
        return 'quotation_rejected';
      case BookingLifecycleState.visitOnlyCompleted:
        return 'visit_only_completed';
      case BookingLifecycleState.incrementalQuotePending:
        return 'incremental_quote_pending';
      case BookingLifecycleState.repairInProgress:
        return 'repair_in_progress';
      case BookingLifecycleState.partsAwaitedPaused:
        return 'parts_awaited_paused';
      case BookingLifecycleState.unrepairableClosed:
        return 'unrepairable_closed';
      case BookingLifecycleState.categoryReclassified:
        return 'category_reclassified';
      case BookingLifecycleState.safetyHaltCancelled:
        return 'safety_halt_cancelled';
      case BookingLifecycleState.cancelledEnroute:
        return 'cancelled_enroute';
      case BookingLifecycleState.cancelledAtSite:
        return 'cancelled_at_site';
      case BookingLifecycleState.paymentPendingVerification:
        return 'payment_pending_verification';
      case BookingLifecycleState.completed:
        return 'completed';
      case BookingLifecycleState.reviewed:
        return 'reviewed';
      case BookingLifecycleState.warrantyClaimed:
        return 'warranty_claimed';
      case BookingLifecycleState.warrantyReworkAssigned:
        return 'warranty_rework_assigned';
      case BookingLifecycleState.warrantyRefunded:
        return 'warranty_refunded';
      case BookingLifecycleState.rePooled:
        return 're_pooled';
      case BookingLifecycleState.adminAuditHold:
        return 'admin_audit_hold';
    }
  }

  String get label {
    switch (this) {
      case BookingLifecycleState.draft:
        return 'Draft Booking';
      case BookingLifecycleState.booked:
        return 'Booked & Paid';
      case BookingLifecycleState.unfulfilledRefunded:
        return 'Unfulfilled (Auto-Refunded)';
      case BookingLifecycleState.accepted:
        return 'Technician Assigned';
      case BookingLifecycleState.onTheWay:
        return 'Technician On The Way 🛵';
      case BookingLifecycleState.arrived:
        return 'Technician Arrived 📍';
      case BookingLifecycleState.customerUnreachable:
        return 'Customer Unreachable 📵';
      case BookingLifecycleState.inspectionInProgress:
        return 'Inspection In Progress 🔍';
      case BookingLifecycleState.quotationPending:
        return 'Quotation Pending Approval 📋';
      case BookingLifecycleState.quotationRejected:
        return 'Estimate Rejected ❌';
      case BookingLifecycleState.visitOnlyCompleted:
        return 'Inspection Completed (Visit Only)';
      case BookingLifecycleState.incrementalQuotePending:
        return 'Additional Part Quote Pending ⚙️';
      case BookingLifecycleState.repairInProgress:
        return 'Repair Work In Progress 🛠️';
      case BookingLifecycleState.partsAwaitedPaused:
        return 'Job Paused (Part Sourcing) 📦';
      case BookingLifecycleState.unrepairableClosed:
        return 'Unrepairable / Beyond Economic Repair';
      case BookingLifecycleState.categoryReclassified:
        return 'Category Reclassified 🔄';
      case BookingLifecycleState.safetyHaltCancelled:
        return 'Cancelled (Safety Hazard) ⚠️';
      case BookingLifecycleState.cancelledEnroute:
        return 'Cancelled En Route (Travel Fee Charged)';
      case BookingLifecycleState.cancelledAtSite:
        return 'Cancelled At Site (Visiting Fee Retained)';
      case BookingLifecycleState.paymentPendingVerification:
        return 'Payment Pending Bank Verification ⏳';
      case BookingLifecycleState.completed:
        return 'Service Completed ✅';
      case BookingLifecycleState.reviewed:
        return 'Service Reviewed ⭐';
      case BookingLifecycleState.warrantyClaimed:
        return 'Warranty Claim Active 🛡️';
      case BookingLifecycleState.warrantyReworkAssigned:
        return 'Free Warranty Rework Assigned 🛠️';
      case BookingLifecycleState.warrantyRefunded:
        return 'Warranty Refund Issued 💰';
      case BookingLifecycleState.rePooled:
        return 'Emergency Released (Re-pooled) 🔄';
      case BookingLifecycleState.adminAuditHold:
        return 'Admin Price Audit Hold 🚨';
    }
  }

  Color get color {
    switch (this) {
      case BookingLifecycleState.draft:
        return Colors.grey;
      case BookingLifecycleState.booked:
        return const Color(0xFF000062);
      case BookingLifecycleState.unfulfilledRefunded:
        return Colors.red.shade700;
      case BookingLifecycleState.accepted:
        return Colors.blue.shade700;
      case BookingLifecycleState.onTheWay:
        return Colors.orange.shade800;
      case BookingLifecycleState.arrived:
        return Colors.purple.shade700;
      case BookingLifecycleState.customerUnreachable:
        return Colors.red.shade800;
      case BookingLifecycleState.inspectionInProgress:
        return Colors.amber.shade900;
      case BookingLifecycleState.quotationPending:
        return Colors.amber.shade800;
      case BookingLifecycleState.quotationRejected:
        return Colors.red.shade700;
      case BookingLifecycleState.visitOnlyCompleted:
        return Colors.teal.shade700;
      case BookingLifecycleState.incrementalQuotePending:
        return Colors.amber.shade900;
      case BookingLifecycleState.repairInProgress:
        return Colors.orange.shade900;
      case BookingLifecycleState.partsAwaitedPaused:
        return Colors.indigo.shade600;
      case BookingLifecycleState.unrepairableClosed:
        return Colors.grey.shade800;
      case BookingLifecycleState.categoryReclassified:
        return Colors.deepPurple.shade700;
      case BookingLifecycleState.safetyHaltCancelled:
        return Colors.red.shade900;
      case BookingLifecycleState.cancelledEnroute:
      case BookingLifecycleState.cancelledAtSite:
        return Colors.red.shade700;
      case BookingLifecycleState.paymentPendingVerification:
        return Colors.amber.shade800;
      case BookingLifecycleState.completed:
        return Colors.green.shade700;
      case BookingLifecycleState.reviewed:
        return Colors.green.shade800;
      case BookingLifecycleState.warrantyClaimed:
      case BookingLifecycleState.warrantyReworkAssigned:
      case BookingLifecycleState.warrantyRefunded:
        return Colors.indigo.shade800;
      case BookingLifecycleState.rePooled:
        return Colors.blue.shade800;
      case BookingLifecycleState.adminAuditHold:
        return Colors.deepOrange.shade800;
    }
  }

  static BookingLifecycleState parse(String? rawStatus) {
    if (rawStatus == null) return BookingLifecycleState.booked;
    final st = rawStatus.trim().toLowerCase();

    if (st == 'draft') return BookingLifecycleState.draft;
    if (st == 'booked') return BookingLifecycleState.booked;
    if (st == 'unfulfilled_refunded' || st == 'expired_refunded') return BookingLifecycleState.unfulfilledRefunded;
    if (st == 'accepted' || st == 'assigned') return BookingLifecycleState.accepted;
    if (st == 'on_the_way' || st == 'in_transit') return BookingLifecycleState.onTheWay;
    if (st == 'arrived' || st == 'at_location') return BookingLifecycleState.arrived;
    if (st == 'customer_unreachable') return BookingLifecycleState.customerUnreachable;
    if (st == 'inspection_in_progress' || st == 'inspecting') return BookingLifecycleState.inspectionInProgress;
    if (st == 'quotation_pending' || st == 'quotation_pending_approval') return BookingLifecycleState.quotationPending;
    if (st == 'quotation_rejected' || st == 'quote_rejected') return BookingLifecycleState.quotationRejected;
    if (st == 'visit_only_completed') return BookingLifecycleState.visitOnlyCompleted;
    if (st == 'incremental_quote_pending') return BookingLifecycleState.incrementalQuotePending;
    if (st == 'repair_in_progress' || st == 'in_progress' || st == 'work_started') return BookingLifecycleState.repairInProgress;
    if (st == 'parts_awaited_paused' || st == 'parts_awaited') return BookingLifecycleState.partsAwaitedPaused;
    if (st == 'unrepairable_closed' || st == 'ber_closed') return BookingLifecycleState.unrepairableClosed;
    if (st == 'category_reclassified') return BookingLifecycleState.categoryReclassified;
    if (st == 'safety_halt_cancelled') return BookingLifecycleState.safetyHaltCancelled;
    if (st == 'cancelled_enroute') return BookingLifecycleState.cancelledEnroute;
    if (st == 'cancelled_at_site') return BookingLifecycleState.cancelledAtSite;
    if (st == 'payment_pending_verification') return BookingLifecycleState.paymentPendingVerification;
    if (st == 'completed' || st == 'paid_and_closed') return BookingLifecycleState.completed;
    if (st == 'reviewed' || st == 'rating_given') return BookingLifecycleState.reviewed;
    if (st == 'warranty_claimed' || st == 'under_warranty') return BookingLifecycleState.warrantyClaimed;
    if (st == 'warranty_rework_assigned') return BookingLifecycleState.warrantyReworkAssigned;
    if (st == 'warranty_refunded') return BookingLifecycleState.warrantyRefunded;
    if (st == 're_pooled' || st == 'released') return BookingLifecycleState.rePooled;
    if (st == 'admin_audit_hold') return BookingLifecycleState.adminAuditHold;

    return BookingLifecycleState.booked;
  }
}
