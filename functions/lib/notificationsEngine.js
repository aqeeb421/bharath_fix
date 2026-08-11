"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onTechNotificationCreated = exports.onUserNotificationCreated = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
/**
 * Firestore Trigger: onUserNotificationCreated
 * Listens to new notification documents created in users/{userId}/notifications/{notifId}
 * and dispatches a high-priority FCM push notification to the user's device.
 */
exports.onUserNotificationCreated = functions.firestore
    .document('users/{userId}/notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
    const userId = context.params.userId;
    const notifData = snapshot.data();
    if (!notifData || !userId)
        return;
    try {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists)
            return;
        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log(`No fcmToken found for user ${userId}`);
            return;
        }
        const message = {
            token: fcmToken,
            notification: {
                title: notifData.title || 'BharatFix Alert',
                body: notifData.body || '',
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: notifData.data?.type || 'CUSTOMER_ALERT',
                jobId: notifData.data?.jobId || '',
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: 'job_alerts',
                },
            },
        };
        await admin.messaging().send(message);
        console.log(`Pushed FCM notification to user ${userId}: ${notifData.title}`);
    }
    catch (error) {
        console.error(`Error pushing FCM notification to user ${userId}:`, error);
    }
});
/**
 * Firestore Trigger: onTechNotificationCreated
 * Listens to new notification documents created in providers/{techId}/notifications/{notifId}
 * and dispatches a high-priority FCM push notification to the technician's device.
 */
exports.onTechNotificationCreated = functions.firestore
    .document('providers/{techId}/notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
    const techId = context.params.techId;
    const notifData = snapshot.data();
    if (!notifData || !techId)
        return;
    try {
        const techDoc = await admin.firestore().collection('providers').doc(techId).get();
        if (!techDoc.exists)
            return;
        const fcmToken = techDoc.data()?.fcmToken;
        if (!fcmToken) {
            console.log(`No fcmToken found for technician ${techId}`);
            return;
        }
        const message = {
            token: fcmToken,
            notification: {
                title: notifData.title || 'BharatFix Partner Alert',
                body: notifData.body || '',
            },
            data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                type: notifData.data?.type || 'TECHNICIAN_ALERT',
                jobId: notifData.data?.jobId || '',
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: 'job_alerts',
                },
            },
        };
        await admin.messaging().send(message);
        console.log(`Pushed FCM notification to technician ${techId}: ${notifData.title}`);
    }
    catch (error) {
        console.error(`Error pushing FCM notification to technician ${techId}:`, error);
    }
});
//# sourceMappingURL=notificationsEngine.js.map