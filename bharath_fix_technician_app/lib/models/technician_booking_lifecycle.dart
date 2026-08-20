import 'package:flutter/material.dart';

/// Discrete Booking Lifecycle & Edge Case States for Technician Partner App
enum TechBookingStatus {
  booked,
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
      case TechBookingStatus.booked:
        return 'booked';
      case TechBookingStatus.accepted:
        return 'accepted';
      case TechBookingStatus.onTheWay:
        return 'on_the_way';
      case TechBookingStatus.arrived:
        return 'arrived';
      case TechBookingStatus.customerUnreachable:
        return 'customer_unreachable';
      case TechBookingStatus.inspectionInProgress:
        return 'inspection_in_progress';
      case TechBookingStatus.quotationPending:
        return 'quotation_pending';
      case TechBookingStatus.quotationRejected:
        return 'quotation_rejected';
      case TechBookingStatus.visitOnlyCompleted:
        return 'visit_only_completed';
      case TechBookingStatus.incrementalQuotePending:
        return 'incremental_quote_pending';
      case TechBookingStatus.repairInProgress:
        return 'repair_in_progress';
      case TechBookingStatus.partsAwaitedPaused:
        return 'parts_awaited_paused';
      case TechBookingStatus.unrepairableClosed:
        return 'unrepairable_closed';
      case TechBookingStatus.categoryReclassified:
        return 'category_reclassified';
      case TechBookingStatus.safetyHaltCancelled:
        return 'safety_halt_cancelled';
      case TechBookingStatus.cancelledEnroute:
        return 'cancelled_enroute';
      case TechBookingStatus.cancelledAtSite:
        return 'cancelled_at_site';
      case TechBookingStatus.paymentPendingVerification:
        return 'payment_pending_verification';
      case TechBookingStatus.completed:
        return 'completed';
      case TechBookingStatus.reviewed:
        return 'reviewed';
      case TechBookingStatus.warrantyClaimed:
        return 'warranty_claimed';
      case TechBookingStatus.warrantyReworkAssigned:
        return 'warranty_rework_assigned';
      case TechBookingStatus.warrantyRefunded:
        return 'warranty_refunded';
      case TechBookingStatus.rePooled:
        return 're_pooled';
      case TechBookingStatus.adminAuditHold:
        return 'admin_audit_hold';
    }
  }

  String get label {
    switch (this) {
      case TechBookingStatus.booked:
        return 'Available Job';
      case TechBookingStatus.accepted:
        return 'Claimed Job';
      case TechBookingStatus.onTheWay:
        return 'En Route 🛵';
      case TechBookingStatus.arrived:
        return 'Arrived at Site 📍';
      case TechBookingStatus.customerUnreachable:
        return 'Customer Unreachable 📵';
      case TechBookingStatus.inspectionInProgress:
        return 'Inspecting Appliance 🔍';
      case TechBookingStatus.quotationPending:
        return 'Estimate Pending Approval 📋';
      case TechBookingStatus.quotationRejected:
        return 'Estimate Rejected ❌';
      case TechBookingStatus.visitOnlyCompleted:
        return 'Inspection Completed (Visit Only)';
      case TechBookingStatus.incrementalQuotePending:
        return 'Additional Quote Submitted ⚙️';
      case TechBookingStatus.repairInProgress:
        return 'Executing Repair 🛠️';
      case TechBookingStatus.partsAwaitedPaused:
        return 'Job Paused (Part Procurement) 📦';
      case TechBookingStatus.unrepairableClosed:
        return 'Unrepairable / BER Closed';
      case TechBookingStatus.categoryReclassified:
        return 'Category Reclassified 🔄';
      case TechBookingStatus.safetyHaltCancelled:
        return 'Safety Hazard Halt ⚠️';
      case TechBookingStatus.cancelledEnroute:
      case TechBookingStatus.cancelledAtSite:
        return 'Cancelled (Fee Compensated)';
      case TechBookingStatus.paymentPendingVerification:
        return 'Payment Pending Bank Webhook ⏳';
      case TechBookingStatus.completed:
        return 'Job Completed ✅';
      case TechBookingStatus.reviewed:
        return 'Reviewed ⭐';
      case TechBookingStatus.warrantyClaimed:
        return 'Warranty Support Ticket 🛡️';
      case TechBookingStatus.warrantyReworkAssigned:
        return 'Warranty Rework Ticket 🛠️';
      case TechBookingStatus.warrantyRefunded:
        return 'Warranty Closed (Refunded)';
      case TechBookingStatus.rePooled:
        return 'Released to Pool 🔄';
      case TechBookingStatus.adminAuditHold:
        return 'Admin Price Audit Hold 🚨';
    }
  }

  Color get color {
    switch (this) {
      case TechBookingStatus.booked:
        return Colors.amber.shade800;
      case TechBookingStatus.accepted:
        return Colors.blue.shade700;
      case TechBookingStatus.onTheWay:
        return Colors.orange.shade800;
      case TechBookingStatus.arrived:
        return Colors.purple.shade700;
      case TechBookingStatus.customerUnreachable:
        return Colors.red.shade800;
      case TechBookingStatus.inspectionInProgress:
        return Colors.amber.shade900;
      case TechBookingStatus.quotationPending:
        return Colors.amber.shade800;
      case TechBookingStatus.quotationRejected:
        return Colors.red.shade700;
      case TechBookingStatus.visitOnlyCompleted:
        return Colors.teal.shade700;
      case TechBookingStatus.incrementalQuotePending:
        return Colors.amber.shade900;
      case TechBookingStatus.repairInProgress:
        return Colors.orange.shade900;
      case TechBookingStatus.partsAwaitedPaused:
        return Colors.indigo.shade600;
      case TechBookingStatus.unrepairableClosed:
        return Colors.grey.shade800;
      case TechBookingStatus.categoryReclassified:
        return Colors.deepPurple.shade700;
      case TechBookingStatus.safetyHaltCancelled:
        return Colors.red.shade900;
      case TechBookingStatus.cancelledEnroute:
      case TechBookingStatus.cancelledAtSite:
        return Colors.red.shade700;
      case TechBookingStatus.paymentPendingVerification:
        return Colors.amber.shade800;
      case TechBookingStatus.completed:
        return Colors.green.shade700;
      case TechBookingStatus.reviewed:
        return Colors.green.shade800;
      case TechBookingStatus.warrantyClaimed:
      case TechBookingStatus.warrantyReworkAssigned:
      case TechBookingStatus.warrantyRefunded:
        return Colors.indigo.shade800;
      case TechBookingStatus.rePooled:
        return Colors.blue.shade800;
      case TechBookingStatus.adminAuditHold:
        return Colors.deepOrange.shade800;
    }
  }

  static TechBookingStatus parse(String? rawStatus) {
    if (rawStatus == null) return TechBookingStatus.booked;
    final st = rawStatus.trim().toLowerCase();

    if (st == 'booked') return TechBookingStatus.booked;
    if (st == 'accepted' || st == 'assigned') return TechBookingStatus.accepted;
    if (st == 'on_the_way' || st == 'in_transit') return TechBookingStatus.onTheWay;
    if (st == 'arrived' || st == 'at_location') return TechBookingStatus.arrived;
    if (st == 'customer_unreachable') return TechBookingStatus.customerUnreachable;
    if (st == 'inspection_in_progress' || st == 'inspecting') return TechBookingStatus.inspectionInProgress;
    if (st == 'quotation_pending' || st == 'quotation_pending_approval') return TechBookingStatus.quotationPending;
    if (st == 'quotation_rejected' || st == 'quote_rejected') return TechBookingStatus.quotationRejected;
    if (st == 'visit_only_completed') return TechBookingStatus.visitOnlyCompleted;
    if (st == 'incremental_quote_pending') return TechBookingStatus.incrementalQuotePending;
    if (st == 'repair_in_progress' || st == 'in_progress' || st == 'work_started') return TechBookingStatus.repairInProgress;
    if (st == 'parts_awaited_paused' || st == 'parts_awaited') return TechBookingStatus.partsAwaitedPaused;
    if (st == 'unrepairable_closed' || st == 'ber_closed') return TechBookingStatus.unrepairableClosed;
    if (st == 'category_reclassified') return TechBookingStatus.categoryReclassified;
    if (st == 'safety_halt_cancelled') return TechBookingStatus.safetyHaltCancelled;
    if (st == 'cancelled_enroute') return TechBookingStatus.cancelledEnroute;
    if (st == 'cancelled_at_site') return TechBookingStatus.cancelledAtSite;
    if (st == 'payment_pending_verification') return TechBookingStatus.paymentPendingVerification;
    if (st == 'completed' || st == 'paid_and_closed' || st == 'work_completed') return TechBookingStatus.completed;
    if (st == 'reviewed' || st == 'rating_given') return TechBookingStatus.reviewed;
    if (st == 'warranty_claimed' || st == 'under_warranty') return TechBookingStatus.warrantyClaimed;
    if (st == 'warranty_rework_assigned') return TechBookingStatus.warrantyReworkAssigned;
    if (st == 'warranty_refunded') return TechBookingStatus.warrantyRefunded;
    if (st == 're_pooled' || st == 'released') return TechBookingStatus.rePooled;
    if (st == 'admin_audit_hold') return TechBookingStatus.adminAuditHold;

    return TechBookingStatus.booked;
  }
}
