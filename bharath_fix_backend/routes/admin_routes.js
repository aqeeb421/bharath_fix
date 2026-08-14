/**
 * BharathFix Admin REST API Routes
 * Production API endpoints for web admin dashboard control & management
 */

const express = require('express');

function createAdminRoutes(admin, fcmEngine) {
  const router = express.Router();
  const db = admin.firestore();

  /**
   * GET /api/admin/stats
   * Returns real-time metrics summary for Admin Dashboard Cards
   */
  router.get('/stats', async (req, res) => {
    try {
      const [bookingsSnap, usersSnap, techsSnap] = await Promise.all([
        db.collection('bookings').get(),
        db.collection('users').get(),
        db.collection('providers').get()
      ]);

      let totalRevenue = 0;
      let activeBookings = 0;
      let completedBookings = 0;
      let pendingKYC = 0;
      let onlineTechs = 0;

      bookingsSnap.docs.forEach((doc) => {
        const data = doc.data();
        const status = (data.status || '').toLowerCase();
        const cost = data.finalAmountPaid || data.quoteTotal || data.visitingFee || 0;

        if (status === 'completed' || status === 'reviewed') {
          totalRevenue += Number(cost);
          completedBookings++;
        } else if (status !== 'cancelled') {
          activeBookings++;
        }
      });

      techsSnap.docs.forEach((doc) => {
        const data = doc.data();
        const status = (data.status || '').toLowerCase();
        if (status === 'pending_verification' || status === 'pending') {
          pendingKYC++;
        }
        if (data.isOnline === true) {
          onlineTechs++;
        }
      });

      res.json({
        success: true,
        data: {
          totalRevenue,
          totalBookings: bookingsSnap.size,
          activeBookings,
          completedBookings,
          totalCustomers: usersSnap.size,
          totalTechnicians: techsSnap.size,
          onlineTechnicians: onlineTechs,
          pendingKycApprovals: pendingKYC
        }
      });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  /**
   * GET /api/admin/bookings
   * Fetch system bookings with optional status filter
   */
  router.get('/bookings', async (req, res) => {
    try {
      const { status, limit = 50 } = req.query;
      let query = db.collection('bookings').limit(Number(limit));

      if (status) {
        query = query.where('status', '==', status);
      }

      const snap = await query.get();
      const bookings = snap.docs.map((doc) => ({
        id: doc.id,
        ...doc.data()
      }));

      res.json({ success: true, count: bookings.length, data: bookings });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  /**
   * POST /api/admin/bookings/:id/status
   * Override/update booking status from Admin Panel & trigger FCM
   */
  router.post('/bookings/:id/status', async (req, res) => {
    try {
      const { id } = req.params;
      const { status, note } = req.body;

      if (!status) {
        return res.status(400).json({ success: false, error: 'Status field is required' });
      }

      const bookingRef = db.collection('bookings').doc(id);
      await bookingRef.set(
        {
          status,
          adminNote: note || '',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        { merge: true }
      );

      res.json({ success: true, message: `Booking #${id} status updated to ${status}` });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  /**
   * GET /api/admin/technicians
   * Fetch all technician partner applications & profiles
   */
  router.get('/technicians', async (req, res) => {
    try {
      const snap = await db.collection('providers').get();
      const technicians = snap.docs.map((doc) => ({
        uid: doc.id,
        ...doc.data()
      }));

      res.json({ success: true, count: technicians.length, data: technicians });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  /**
   * POST /api/admin/technicians/:id/verify
   * Approve or Reject technician KYC verification
   */
  router.post('/technicians/:id/verify', async (req, res) => {
    try {
      const { id } = req.params;
      const { action } = req.body; // 'approve' or 'reject'

      if (action !== 'approve' && action !== 'reject') {
        return res.status(400).json({ success: false, error: "Action must be 'approve' or 'reject'" });
      }

      const newStatus = action === 'approve' ? 'active' : 'rejected';
      await db.collection('providers').doc(id).update({
        status: newStatus,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Notify technician via FCM
      await fcmEngine.sendToTech(id, {
        title: action === 'approve' ? 'Account Approved! 🎉' : 'Account Status Update',
        body: action === 'approve'
          ? 'Congratulations! Your partner account has been verified and activated.'
          : 'Your partner application requires updated documents. Please contact support.',
        data: { type: 'KYC_STATUS_UPDATE', status: newStatus }
      });

      res.json({ success: true, message: `Technician ${id} marked as ${newStatus}` });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  /**
   * POST /api/admin/notifications/broadcast
   * Send custom broadcast FCM notification to all customers or technicians
   */
  router.post('/notifications/broadcast', async (req, res) => {
    try {
      const { target, title, body } = req.body; // target: 'customers', 'technicians', 'all'

      if (!title || !body) {
        return res.status(400).json({ success: false, error: 'Title and body are required' });
      }

      if (target === 'technicians' || target === 'all') {
        await fcmEngine.notifyAvailableTechnicians({ title, body, data: { type: 'BROADCAST_ALERT' } });
      }

      res.json({ success: true, message: 'Broadcast notification dispatched successfully' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  });

  return router;
}

module.exports = createAdminRoutes;
