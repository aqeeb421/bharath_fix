enum JobStatus {
  draft,
  pendingPayment,
  booked,
  accepted,
  inTransit,
  arrived,
  inspectionInProgress,
  quotationPendingApproval,
  quotationRejected,
  workInProgress,
  workCompleted,
  paidAndClosed,
  cancelledByCustomer,
  cancelledByTechnician,
  unassignedExpired,
  pausedPartsSourcing,
  warrantyClaim;

  String get code {
    switch (this) {
      case JobStatus.draft:
        return 'DRAFT';
      case JobStatus.pendingPayment:
        return 'PENDING_PAYMENT';
      case JobStatus.booked:
        return 'BOOKED';
      case JobStatus.accepted:
        return 'ACCEPTED';
      case JobStatus.inTransit:
        return 'IN_TRANSIT';
      case JobStatus.arrived:
        return 'ARRIVED';
      case JobStatus.inspectionInProgress:
        return 'INSPECTION_IN_PROGRESS';
      case JobStatus.quotationPendingApproval:
        return 'QUOTATION_PENDING_APPROVAL';
      case JobStatus.quotationRejected:
        return 'QUOTATION_REJECTED';
      case JobStatus.workInProgress:
        return 'WORK_IN_PROGRESS';
      case JobStatus.workCompleted:
        return 'WORK_COMPLETED';
      case JobStatus.paidAndClosed:
        return 'PAID_AND_CLOSED';
      case JobStatus.cancelledByCustomer:
        return 'CANCELLED_BY_CUSTOMER';
      case JobStatus.cancelledByTechnician:
        return 'CANCELLED_BY_TECHNICIAN';
      case JobStatus.unassignedExpired:
        return 'UNASSIGNED_EXPIRED';
      case JobStatus.pausedPartsSourcing:
        return 'PAUSED_PARTS_SOURCING';
      case JobStatus.warrantyClaim:
        return 'WARRANTY_CLAIM';
    }
  }

  String get displayName {
    switch (this) {
      case JobStatus.draft:
        return 'Draft Request';
      case JobStatus.pendingPayment:
        return 'Payment Pending';
      case JobStatus.booked:
        return 'Searching Nearby Technicians';
      case JobStatus.accepted:
        return 'Technician Assigned';
      case JobStatus.inTransit:
        return 'Technician On The Way';
      case JobStatus.arrived:
        return 'Technician Arrived';
      case JobStatus.inspectionInProgress:
        return 'Inspection In Progress';
      case JobStatus.quotationPendingApproval:
        return 'Quotation Awaiting Approval';
      case JobStatus.quotationRejected:
        return 'Quotation Declined';
      case JobStatus.workInProgress:
        return 'Work In Progress';
      case JobStatus.workCompleted:
        return 'Work Completed - Payment Due';
      case JobStatus.paidAndClosed:
        return 'Paid & Completed';
      case JobStatus.cancelledByCustomer:
        return 'Cancelled by Customer';
      case JobStatus.cancelledByTechnician:
        return 'Cancelled by Technician';
      case JobStatus.unassignedExpired:
        return 'Expired - No Tech Available';
      case JobStatus.pausedPartsSourcing:
        return 'Paused - Sourcing Parts';
      case JobStatus.warrantyClaim:
        return 'Warranty Support Requested';
    }
  }

  static JobStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'DRAFT':
        return JobStatus.draft;
      case 'PENDING_PAYMENT':
        return JobStatus.pendingPayment;
      case 'BOOKED':
      case 'BROADCASTING':
        return JobStatus.booked;
      case 'ACCEPTED':
        return JobStatus.accepted;
      case 'IN_TRANSIT':
        return JobStatus.inTransit;
      case 'ARRIVED':
        return JobStatus.arrived;
      case 'INSPECTION_IN_PROGRESS':
        return JobStatus.inspectionInProgress;
      case 'QUOTATION_PENDING_APPROVAL':
        return JobStatus.quotationPendingApproval;
      case 'QUOTATION_REJECTED':
        return JobStatus.quotationRejected;
      case 'WORK_IN_PROGRESS':
        return JobStatus.workInProgress;
      case 'WORK_COMPLETED':
      case 'BILL_PENDING':
        return JobStatus.workCompleted;
      case 'PAID_AND_CLOSED':
      case 'PAID & CLOSED':
        return JobStatus.paidAndClosed;
      case 'CANCELLED_BY_CUSTOMER':
        return JobStatus.cancelledByCustomer;
      case 'CANCELLED_BY_TECHNICIAN':
        return JobStatus.cancelledByTechnician;
      case 'UNASSIGNED_EXPIRED':
        return JobStatus.unassignedExpired;
      case 'PAUSED_PARTS_SOURCING':
        return JobStatus.pausedPartsSourcing;
      case 'WARRANTY_CLAIM':
        return JobStatus.warrantyClaim;
      default:
        return JobStatus.draft;
    }
  }
}
