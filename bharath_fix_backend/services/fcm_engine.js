/**
 * BharathFix Centralized Backend Engine
 * Listens to real-time Firestore booking state changes and dispatches automated FCM push alerts
 * Also handles Wallet/Commission calculations on job completion.
 */

class FcmEngine {
  constructor(admin) {
    this.admin = admin;
    this.db = admin.firestore();
    this.messaging = admin.messaging();
    this.isListening = false;
    this.unsubscribe = null;
    this.ordersUnsubscribe = null;
    this.lastNotifiedStatus = new Map();
    this.lastNotifiedOrderStatus = new Map();
  }

  startListener() {
    if (this.isListening) return;

    console.log('🚀 Initializing Centralized FCM Real-Time Listener...');
    let isInitialLoad = true;

    this.unsubscribe = this.db.collection('bookings').onSnapshot(
      (snapshot) => {
        if (isInitialLoad) {
          isInitialLoad = false;
          snapshot.docs.forEach((doc) => {
            const st = (doc.data()?.status || '').trim();
            this.lastNotifiedStatus.set(doc.id, st);
          });
          console.log(`📡 FCM Engine synchronized with ${snapshot.size} existing active bookings.`);
          return;
        }

        snapshot.docChanges().forEach(async (change) => {
          const bookingData = change.doc.data();
          const bookingId = change.doc.id;
          const status = (bookingData.status || '').trim();

          if (change.type === 'added') {
            console.log(`📋 New Booking Created: #${bookingId}`);
            this.lastNotifiedStatus.set(bookingId, status);
            await this.handleNewBooking(bookingId, bookingData);
          } else if (change.type === 'modified') {
            const previousStatus = this.lastNotifiedStatus.get(bookingId);
            if (previousStatus === status) {
              return;
            }
            this.lastNotifiedStatus.set(bookingId, status);
            console.log(`🔄 Booking #${bookingId} state updated: [${previousStatus || 'initial'}] -> [${status}]`);
            await this.handleStatusTransition(bookingId, bookingData);
          }
        });
      },
      (error) => {
        console.error('❌ Firestore FCM Listener Error:', error?.message || error);
        this.isListening = false;
        if (this.unsubscribe) {
          try {
            this.unsubscribe();
          } catch (_) {}
          this.unsubscribe = null;
        }
        console.log('🔄 Firestore listener dropped. Auto-reconnecting FCM Engine in 5 seconds...');
        setTimeout(() => {
          this.startListener();
        }, 5000);
      }
    );

    let isOrdersInitialLoad = true;
    this.ordersUnsubscribe = this.db.collection('orders').onSnapshot(
      (snapshot) => {
        if (isOrdersInitialLoad) {
          isOrdersInitialLoad = false;
          snapshot.docs.forEach((doc) => {
            const st = (doc.data()?.orderStatus || doc.data()?.status || '').trim();
            this.lastNotifiedOrderStatus.set(doc.id, st);
          });
          return;
        }

        snapshot.docChanges().forEach(async (change) => {
          const orderData = change.doc.data();
          const orderId = change.doc.id;
          const status = (orderData.orderStatus || orderData.status || '').trim();

          if (change.type === 'added') {
            this.lastNotifiedOrderStatus.set(orderId, status);
            await this.recordAdminNotification({
              title: '📦 New Product Order',
              body: `New order (#${orderId}) placed for ${orderData.productName || 'product'}.`,
              data: { orderId, type: 'NEW_ORDER' }
            });
          } else if (change.type === 'modified') {
            const previousStatus = this.lastNotifiedOrderStatus.get(orderId);
            if (previousStatus === status) return;
            
            this.lastNotifiedOrderStatus.set(orderId, status);
            await this.handleOrderStatusTransition(orderId, orderData);
          }
        });
      },
      (error) => console.error('❌ Firestore Orders Listener Error:', error)
    );

    this.isListening = true;
  }

  stopListener() {
    if (this.unsubscribe) {
      try {
        this.unsubscribe();
      } catch (_) {}
      this.unsubscribe = null;
    }
    if (this.ordersUnsubscribe) {
      try {
        this.ordersUnsubscribe();
      } catch (_) {}
      this.ordersUnsubscribe = null;
    }
    this.isListening = false;
    console.log('🛑 Firestore FCM Real-Time Listener stopped.');
  }

  async handleNewBooking(bookingId, booking) {
    const category = booking.title || booking.category || 'Appliance Service';
    const address = booking.address || 'Hassan, KA';

    await this.notifyAvailableTechnicians({
      title: '🔔 New Service Request Nearby!',
      body: `New ${category} request near ${address}. Tap to review details & accept job.`,
      data: { bookingId, type: 'NEW_BOOKING_ALERT', category }
    });

    if (booking.userId) {
      await this.sendToUser(booking.userId, {
        title: '📋 Booking Confirmed!',
        body: `Your request for ${category} (#${bookingId}) has been placed. Searching for nearby technicians...`,
        data: { bookingId, type: 'BOOKING_CONFIRMED' }
      });
    }

    await this.recordAdminNotification({
      title: '📋 New Booking Placed',
      body: `New ${category} request (#${bookingId}) placed in ${address}.`,
      data: { bookingId, type: 'NEW_BOOKING' }
    });
  }

  async handleStatusTransition(bookingId, booking) {
    const status = (booking.status || '').trim().toUpperCase();
    const userId = booking.userId || booking.customerId;
    const techId = booking.providerId;
    const techName = booking.providerName || 'Technician';
    const techPhone = booking.providerPhone || '';
    const quoteTotal = booking.quoteTotal || booking.additionalCost || 0;

    switch (status) {
      case 'ACCEPTED':
        if (userId) {
          await this.sendToUser(userId, {
            title: '⚡ Technician Assigned!',
            body: `${techName} (${techPhone}) has accepted your booking.`,
            data: { bookingId, type: 'TECHNICIAN_ASSIGNED' }
          });
        }
        await this.recordAdminNotification({
          title: '⚡ Job Accepted',
          body: `Technician ${techName} accepted Booking #${bookingId}.`,
          data: { bookingId, type: 'JOB_ACCEPTED' }
        });
        break;

      case 'IN_TRANSIT':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🚗 Technician On The Way',
            body: `${techName} has started moving towards your location. Tap to track live.`,
            data: { bookingId, type: 'ON_THE_WAY' }
          });
        }
        break;

      case 'ARRIVED':
        if (userId) {
          const otp = booking.startOtp || '1234';
          await this.sendToUser(userId, {
            title: '📍 Technician Arrived',
            body: `${techName} has reached your location. Share Start OTP: ${otp} when ready.`,
            data: { bookingId, type: 'TECHNICIAN_ARRIVED', startOtp: otp }
          });
        }
        break;

      case 'INSPECTION_IN_PROGRESS':
      case 'WORK_IN_PROGRESS':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🔍 Service Underway',
            body: `Start OTP verified. ${techName} is inspecting/servicing your appliance.`,
            data: { bookingId, type: 'INSPECTION_STARTED' }
          });
        }
        break;

      case 'QUOTATION_PENDING':
      case 'QUOTATION_PENDING_APPROVAL':
        if (userId) {
          await this.sendToUser(userId, {
            title: '📄 Repair Quotation Submitted',
            body: `Estimate of ₹${quoteTotal} submitted by ${techName}. Review and approve in app to start repair.`,
            data: { bookingId, type: 'QUOTATION_PENDING', quoteTotal: String(quoteTotal) }
          });
        }
        await this.recordAdminNotification({
          title: '📄 Quotation Submitted',
          body: `Quotation of ₹${quoteTotal} submitted by ${techName} for Booking #${bookingId}.`,
          data: { bookingId, type: 'QUOTATION_SUBMITTED' }
        });
        break;

      case 'REPAIR_IN_PROGRESS':
        if (techId) {
          await this.sendToTech(techId, {
            title: '✅ Quotation Approved!',
            body: `Customer approved repair estimate of ₹${quoteTotal}. You can begin repair work now.`,
            data: { bookingId, type: 'QUOTATION_APPROVED' }
          });
        }
        await this.recordAdminNotification({
          title: '✅ Quotation Approved',
          body: `Customer approved repair estimate (₹${quoteTotal}) for Booking #${bookingId}.`,
          data: { bookingId, type: 'QUOTATION_APPROVED' }
        });
        break;

      case 'VISIT_ONLY_COMPLETED':
      case 'QUOTATION_REJECTED':
        if (techId) {
          await this.sendToTech(techId, {
            title: '❌ Quotation Declined',
            body: `Customer declined repair estimate. Job closed as Visit-Only Completed.`,
            data: { bookingId, type: 'QUOTATION_REJECTED' }
          });
        }
        await this.recordAdminNotification({
          title: '❌ Quotation Declined',
          body: `Customer declined repair estimate for Booking #${bookingId}. Closed as Visit-Only.`,
          data: { bookingId, type: 'QUOTATION_REJECTED' }
        });
        break;

      case 'WORK_COMPLETED':
      case 'PAID_AND_CLOSED':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🎉 Service Completed!',
            body: `Your service for Booking #${bookingId} is complete. Tap to rate your experience!`,
            data: { bookingId, type: 'SERVICE_COMPLETED' }
          });
        }
        if (techId) {
          await this.sendToTech(techId, {
            title: '🎉 Job Completed Successfully!',
            body: `Job #${bookingId} finished. Payout recorded in your partner wallet.`,
            data: { bookingId, type: 'JOB_COMPLETED' }
          });
        }
        await this.recordAdminNotification({
          title: '🎉 Service Completed',
          body: `Booking #${bookingId} successfully completed by ${techName}.`,
          data: { bookingId, type: 'JOB_COMPLETED' }
        });

        // Trigger Wallet Engine logic
        await this.processWalletLedger(bookingId, booking);
        break;

      case 'REVIEWED':
        if (techId) {
          const rating = booking.rating || 5;
          const comment = booking.reviewComment || '';
          await this.sendToTech(techId, {
            title: '⭐ New Customer Review!',
            body: `Customer rated your service ${rating}★: "${comment}"`,
            data: { bookingId, type: 'NEW_RATING_RECEIVED' }
          });
        }
        break;

      case 'WARRANTY_CLAIMED':
        if (techId) {
          await this.sendToTech(techId, {
            title: '🛡️ Warranty Claim Filed',
            body: `Customer requested warranty inspection for Booking #${bookingId}.`,
            data: { bookingId, type: 'WARRANTY_CLAIMED' }
          });
        }
        await this.recordAdminNotification({
          title: '🛡️ Warranty Claim Filed',
          body: `Customer filed warranty claim for Booking #${bookingId}.`,
          data: { bookingId, type: 'WARRANTY_CLAIMED' }
        });
        break;

      default:
        console.log(`Unhandled or internal status: ${status}`);
    }
  }

  async handleOrderStatusTransition(orderId, orderData) {
    const status = (orderData.orderStatus || orderData.status || '').trim().toUpperCase();
    const userId = orderData.userId;
    const productName = orderData.productName || 'your product';

    switch (status) {
      case 'ADMINORDERSTATUS.PROCESSING':
      case 'PROCESSING':
        if (userId) {
          await this.sendToUser(userId, {
            title: '📦 Order Processing',
            body: `Your order for ${productName} is now being processed.`,
            data: { orderId, type: 'ORDER_PROCESSING' }
          });
        }
        break;

      case 'ADMINORDERSTATUS.SHIPPED':
      case 'SHIPPED':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🚚 Order Shipped',
            body: `Your order for ${productName} has been shipped!`,
            data: { orderId, type: 'ORDER_SHIPPED' }
          });
        }
        break;

      case 'ADMINORDERSTATUS.OUTFORDELIVERY':
      case 'OUTFORDELIVERY':
      case 'OUT_FOR_DELIVERY':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🛵 Out For Delivery',
            body: `Your order for ${productName} is out for delivery. Have your OTP ready: ${orderData.deliveryOtp || '1234'}`,
            data: { orderId, type: 'ORDER_OUT_FOR_DELIVERY' }
          });
        }
        break;

      case 'ADMINORDERSTATUS.DELIVERED':
      case 'DELIVERED':
        if (userId) {
          await this.sendToUser(userId, {
            title: '✅ Order Delivered',
            body: `Your order for ${productName} has been delivered successfully.`,
            data: { orderId, type: 'ORDER_DELIVERED' }
          });
        }
        break;

      case 'ADMINORDERSTATUS.CANCELLED':
      case 'CANCELLED':
        if (userId) {
          await this.sendToUser(userId, {
            title: '❌ Order Cancelled',
            body: `Your order for ${productName} has been cancelled.`,
            data: { orderId, type: 'ORDER_CANCELLED' }
          });
        }
        break;
    }
  }

  /**
   * Calculates platform commission and updates technician wallet balance or COD debt.
   */
  async processWalletLedger(bookingId, booking) {
    try {
      const providerId = booking.providerId;
      if (!providerId) return;

      const providerRef = this.db.collection('providers').doc(providerId);
      
      const quoteTotal = booking.quoteTotal || booking.visitingFee || 199.0;
      const commissionRate = 0.15; // 15% default platform commission
      const platformFee = quoteTotal * commissionRate;
      const technicianEarnings = quoteTotal - platformFee;

      const isCOD = booking.paymentMode === 'COD';

      await this.db.runTransaction(async (transaction) => {
        const providerDoc = await transaction.get(providerRef);
        if (!providerDoc.exists) return;

        // Check if ledger entry already exists to ensure idempotency
        const ledgerSnap = await transaction.get(providerRef.collection('walletLedger').where('jobId', '==', bookingId));
        if (!ledgerSnap.empty) {
          console.log(`Wallet ledger already processed for booking #${bookingId}`);
          return;
        }

        const currentData = providerDoc.data();
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

        // COD Safety Threshold check (₹5000)
        const codThreshold = 5000;
        const isDutyBlocked = newCodDebt >= codThreshold;

        transaction.update(providerRef, {
          walletBalance: newWalletBalance,
          codDebt: newCodDebt,
          isDutyBlocked: isDutyBlocked,
          updatedAt: this.admin.firestore.FieldValue.serverTimestamp(),
        });

        // Add ledger entry
        const ledgerRef = providerRef.collection('walletLedger').doc();
        transaction.set(ledgerRef, {
          jobId: bookingId,
          type: isCOD ? 'COD_COMMISSION_DEBIT' : 'JOB_EARNINGS_CREDIT',
          amount: isCOD ? -platformFee : technicianEarnings,
          grossAmount: quoteTotal,
          platformFee: platformFee,
          timestamp: this.admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`💰 Processed wallet ledger for provider ${providerId} on booking #${bookingId}`);
    } catch (error) {
      console.error(`❌ Failed to process wallet ledger for booking #${bookingId}:`, error);
    }
  }

  async recordAdminNotification(payload) {
    try {
      const notifId = `notif_admin_${Date.now()}`;
      await this.db.collection('admin_notifications').doc(notifId).set({
        id: notifId,
        title: payload.title,
        body: payload.body,
        data: payload.data || {},
        isRead: false,
        createdAt: this.admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {}
  }

  async sendToUser(userId, payload) {
    try {
      const notifId = `notif_u_${Date.now()}`;
      await this.db.collection('users').doc(userId).collection('notifications').doc(notifId).set({
        id: notifId,
        userId,
        title: payload.title,
        body: payload.body,
        data: payload.data || {},
        isRead: false,
        createdAt: this.admin.firestore.FieldValue.serverTimestamp()
      });

      const userDoc = await this.db.collection('users').doc(userId).get();
      const token = userDoc.data()?.fcmToken;

      if (token && token.trim().length > 0) {
        await this.messaging.send({
          token: token.trim(),
          notification: { title: payload.title, body: payload.body },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          },
          android: { priority: 'high', notification: { channelId: 'high_importance_channel', sound: 'default' } }
        });
      }
    } catch (error) {}
  }

  async sendToTech(techId, payload) {
    try {
      const notifId = `notif_t_${Date.now()}`;
      await this.db.collection('providers').doc(techId).collection('notifications').doc(notifId).set({
        id: notifId,
        techId,
        title: payload.title,
        body: payload.body,
        data: payload.data || {},
        isRead: false,
        createdAt: this.admin.firestore.FieldValue.serverTimestamp()
      });

      const techDoc = await this.db.collection('providers').doc(techId).get();
      const token = techDoc.data()?.fcmToken;

      if (token && token.trim().length > 0) {
        await this.messaging.send({
          token: token.trim(),
          notification: { title: payload.title, body: payload.body },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          },
          android: { priority: 'high', notification: { channelId: 'high_importance_channel', sound: 'default' } }
        });
      }
    } catch (error) {}
  }

  async notifyAvailableTechnicians(payload) {
    try {
      const snap = await this.db.collection('providers').get();
      const tokens = [];
      snap.docs.forEach((doc) => {
        const token = doc.data()?.fcmToken;
        if (token && token.trim().length > 0) tokens.push(token.trim());
      });

      if (tokens.length > 0) {
        await this.messaging.sendEachForMulticast({
          tokens,
          notification: { title: payload.title, body: payload.body },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          },
          android: { priority: 'high', notification: { channelId: 'high_importance_channel', sound: 'default', priority: 'max' } }
        });
      }
    } catch (error) {}
  }
}

module.exports = FcmEngine;
