/**
 * BharathFix Centralized FCM Push Notification Engine
 * Listens to real-time Firestore booking state changes and dispatches automated FCM push alerts
 */

class FcmEngine {
  constructor(admin) {
    this.admin = admin;
    this.db = admin.firestore();
    this.messaging = admin.messaging();
    this.isListening = false;
    this.unsubscribe = null;
  }

  /**
   * Start real-time Firestore listener for booking status transitions
   */
  startListener() {
    if (this.isListening) return;

    console.log('🚀 Initializing Centralized FCM Real-Time Listener...');
    let isInitialLoad = true;

    this.unsubscribe = this.db.collection('bookings').onSnapshot(
      (snapshot) => {
        if (isInitialLoad) {
          isInitialLoad = false;
          console.log(`📡 FCM Engine synchronized with ${snapshot.size} existing active bookings.`);
          return;
        }

        snapshot.docChanges().forEach(async (change) => {
          const bookingData = change.doc.data();
          const bookingId = change.doc.id;

          if (change.type === 'added') {
            console.log(`📋 New Booking Created: #${bookingId}`);
            await this.handleNewBooking(bookingId, bookingData);
          } else if (change.type === 'modified') {
            console.log(`🔄 Booking #${bookingId} state updated to [${bookingData.status}]`);
            await this.handleStatusTransition(bookingId, bookingData);
          }
        });
      },
      (error) => {
        console.error('❌ Firestore FCM Listener Error:', error);
      }
    );

    this.isListening = true;
  }

  /**
   * Handle new booking creation -> Notify available technicians in category
   */
  async handleNewBooking(bookingId, booking) {
    const category = booking.title || booking.category || 'Appliance Service';
    const address = booking.address || 'Hassan, KA';

    // Broadcast to available technicians
    await this.notifyAvailableTechnicians({
      title: '🔔 New Service Request Nearby!',
      body: `New ${category} request near ${address}. Tap to review details & accept job.`,
      data: { bookingId, type: 'NEW_BOOKING_ALERT', category }
    });

    // Notify Customer confirmation
    if (booking.userId) {
      await this.sendToUser(booking.userId, {
        title: '📋 Booking Confirmed!',
        body: `Your request for ${category} (#${bookingId}) has been placed. Searching for nearby technicians...`,
        data: { bookingId, type: 'BOOKING_CONFIRMED' }
      });
    }
  }

  /**
   * Handle booking status transitions across the state machine
   */
  async handleStatusTransition(bookingId, booking) {
    const status = (booking.status || '').toLowerCase().trim();
    const userId = booking.userId || booking.customerId;
    const techId = booking.providerId;
    const techName = booking.providerName || 'Technician';
    const techPhone = booking.providerPhone || '';
    const quoteTotal = booking.quoteTotal || booking.additionalCost || 0;

    switch (status) {
      case 'accepted':
        if (userId) {
          await this.sendToUser(userId, {
            title: '⚡ Technician Assigned!',
            body: `${techName} (${techPhone}) has accepted your booking.`,
            data: { bookingId, type: 'TECHNICIAN_ASSIGNED' }
          });
        }
        break;

      case 'on_the_way':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🚗 Technician On The Way',
            body: `${techName} has started moving towards your location. Tap to track live.`,
            data: { bookingId, type: 'ON_THE_WAY' }
          });
        }
        break;

      case 'arrived':
        if (userId) {
          const otp = booking.startOtp || '1234';
          await this.sendToUser(userId, {
            title: '📍 Technician Arrived',
            body: `${techName} has reached your location. Share Start OTP: ${otp} when ready.`,
            data: { bookingId, type: 'TECHNICIAN_ARRIVED', startOtp: otp }
          });
        }
        break;

      case 'inspection_in_progress':
      case 'in_progress':
        if (userId) {
          await this.sendToUser(userId, {
            title: '🔍 Inspection Underway',
            body: `Start OTP verified. ${techName} is inspecting your appliance.`,
            data: { bookingId, type: 'INSPECTION_STARTED' }
          });
        }
        break;

      case 'quotation_pending':
        if (userId) {
          await this.sendToUser(userId, {
            title: '📄 Repair Quotation Submitted',
            body: `Estimate of ₹${quoteTotal} submitted by ${techName}. Review and approve in app to start repair.`,
            data: { bookingId, type: 'QUOTATION_PENDING', quoteTotal: String(quoteTotal) }
          });
        }
        break;

      case 'repair_in_progress':
        if (techId) {
          await this.sendToTech(techId, {
            title: '✅ Quotation Approved!',
            body: `Customer approved repair estimate of ₹${quoteTotal}. You can begin repair work now.`,
            data: { bookingId, type: 'QUOTATION_APPROVED' }
          });
        }
        break;

      case 'visit_only_completed':
        if (techId) {
          await this.sendToTech(techId, {
            title: '❌ Quotation Declined',
            body: `Customer declined repair estimate. Job closed as Visit-Only Completed.`,
            data: { bookingId, type: 'QUOTATION_REJECTED' }
          });
        }
        break;

      case 'completed':
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
        break;

      case 'reviewed':
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

      case 'warranty_claimed':
        if (techId) {
          await this.sendToTech(techId, {
            title: '🛡️ Warranty Claim Filed',
            body: `Customer requested warranty inspection for Booking #${bookingId}.`,
            data: { bookingId, type: 'WARRANTY_CLAIMED' }
          });
        }
        break;

      default:
        console.log(`Unhandled or internal status: ${status}`);
    }
  }

  /**
   * Send FCM Push Notification to a Customer
   */
  async sendToUser(userId, payload) {
    try {
      // 1. Record in-app notification document
      const notifId = `notif_u_${Date.now()}`;
      await this.db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notifId)
        .set({
          id: notifId,
          userId,
          title: payload.title,
          body: payload.body,
          data: payload.data || {},
          isRead: false,
          createdAt: this.admin.firestore.FieldValue.serverTimestamp()
        });

      // 2. Fetch Customer FCM Token & Dispatch Push
      const userDoc = await this.db.collection('users').doc(userId).get();
      const token = userDoc.data()?.fcmToken;

      if (token && token.trim().length > 0) {
        await this.messaging.send({
          token: token.trim(),
          notification: {
            title: payload.title,
            body: payload.body
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
              sound: 'default'
            }
          }
        });
        console.log(`✅ FCM Push sent to User [${userId}]`);
      }
    } catch (error) {
      console.error(`❌ FCM Send to User [${userId}] failed:`, error.message);
    }
  }

  /**
   * Send FCM Push Notification to a Technician
   */
  async sendToTech(techId, payload) {
    try {
      // 1. Record in-app notification document
      const notifId = `notif_t_${Date.now()}`;
      await this.db
        .collection('providers')
        .doc(techId)
        .collection('notifications')
        .doc(notifId)
        .set({
          id: notifId,
          techId,
          title: payload.title,
          body: payload.body,
          data: payload.data || {},
          isRead: false,
          createdAt: this.admin.firestore.FieldValue.serverTimestamp()
        });

      // 2. Fetch Tech FCM Token & Dispatch Push
      const techDoc = await this.db.collection('providers').doc(techId).get();
      const token = techDoc.data()?.fcmToken;

      if (token && token.trim().length > 0) {
        await this.messaging.send({
          token: token.trim(),
          notification: {
            title: payload.title,
            body: payload.body
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'high_importance_channel',
              sound: 'default'
            }
          }
        });
        console.log(`✅ FCM Push sent to Technician [${techId}]`);
      }
    } catch (error) {
      console.error(`❌ FCM Send to Tech [${techId}] failed:`, error.message);
    }
  }

  /**
   * Broadcast notification to all active technicians
   */
  async notifyAvailableTechnicians(payload) {
    try {
      const snap = await this.db.collection('providers').get();
      const tokens = [];

      snap.docs.forEach((doc) => {
        const token = doc.data()?.fcmToken;
        if (token && token.trim().length > 0) {
          tokens.push(token.trim());
        }
      });

      if (tokens.length > 0) {
        await this.messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: payload.title,
            body: payload.body
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            title: payload.title,
            body: payload.body,
            ...(payload.data || {})
          }
        });
        console.log(`📢 Broadcasted FCM to ${tokens.length} technicians.`);
      }
    } catch (error) {
      console.error('❌ Broadcast to Technicians failed:', error.message);
    }
  }
}

module.exports = FcmEngine;
