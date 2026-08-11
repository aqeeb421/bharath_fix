"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onJobBooked = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
/**
 * Firestore Trigger: onJobBooked
 * Triggers whenever a job status transitions to 'BOOKED'.
 * Searches nearby available technicians and sends high-priority FCM notifications.
 */
exports.onJobBooked = functions.firestore
    .document('jobs/{jobId}')
    .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Trigger only when transitioning into BOOKED
    if (beforeData.status !== 'BOOKED' && afterData.status === 'BOOKED') {
        const jobId = context.params.jobId;
        const db = admin.firestore();
        const jobCategory = afterData.title || '';
        const jobLat = afterData.latitude;
        const jobLng = afterData.longitude;
        // Fetch online providers who offer this service category
        const providersSnap = await db
            .collection('providers')
            .where('isOnline', '==', true)
            .where('isApproved', '==', true)
            .get();
        const candidateTokens = [];
        providersSnap.docs.forEach((doc) => {
            const provider = doc.data();
            // Check if provider accepts job category and has FCM token
            if (provider.fcmToken) {
                if (jobLat && jobLng && provider.latitude && provider.longitude) {
                    const distanceKm = getDistanceFromLatLonInKm(jobLat, jobLng, provider.latitude, provider.longitude);
                    const workingRadius = provider.workingRadiusKm || 10;
                    if (distanceKm <= workingRadius) {
                        candidateTokens.push(provider.fcmToken);
                    }
                }
                else {
                    candidateTokens.push(provider.fcmToken);
                }
            }
        });
        if (candidateTokens.length > 0) {
            const payload = {
                tokens: candidateTokens,
                notification: {
                    title: `New Service Request: ${jobCategory}`,
                    body: `Location: ${afterData.address || 'Nearby'}. Visiting Fee: ₹${afterData.visitingFee || 199}`,
                },
                data: {
                    jobId: jobId,
                    type: 'JOB_BROADCAST',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                android: {
                    priority: 'high',
                    notification: {
                        sound: 'default',
                        channelId: 'job_alerts',
                    },
                },
            };
            await admin.messaging().sendEachForMulticast(payload);
            console.log(`Sent broadcast notification for job ${jobId} to ${candidateTokens.length} technicians.`);
        }
        else {
            console.log(`No active technician candidates found within radius for job ${jobId}.`);
        }
    }
});
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}
function deg2rad(deg) {
    return deg * (Math.PI / 180);
}
//# sourceMappingURL=broadcastEngine.js.map