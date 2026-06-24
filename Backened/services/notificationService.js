const admin = require('firebase-admin');

class NotificationService {
    /**
     * Sends an International Standard Heads-Up Notification (Top Popup with Sound)
     * Works when app is in Foreground, Background, or completely Closed/Killed.
     * * @param {string} fcmToken - The target device FCM token
     * @param {string} title - The title of the notification (e.g., "New Quiz Uploaded!")
     * @param {string} body - The detailed description text (e.g., "AI Quiz 1 has been published for Mobile Computing.")
     * @param {Object} extraData - Optional key-value pairs for navigation inside app
     */
    static async sendPushNotification(fcmToken, title, body, extraData = {}) {
        if (!fcmToken) {
            console.log("❌ Notification skipped: No FCM Token provided.");
            return;
        }

        // Dynamic data fields inside payload to ensure full detail rendering in notification panel
        const payloadData = {
            title: title,
            message: body,
            body: body,
            ...extraData
        };

        const message = {
            token: fcmToken,
            // 1️⃣ DATA PAYLOAD: Crucial for Android Background/Kill State Interception
            data: payloadData,

            // 2️⃣ NOTIFICATION PAYLOAD: For system level rendering
            notification: {
                title: title,
                body: body,
            },

            // 3️⃣ NATIVE ANDROID OVERRIDES (Forces Snapchat/Facebook Top Popup Banner)
            android: {
                priority: 'high', // Forces immediate processing
                notification: {
                    channelId: 'smart_teacher_channel', // MUST match Flutter main.dart channel ID precisely
                    importance: 'max',                  // Forces the Heads-up overlay top popup
                    priority: 'high',
                    sound: 'smart_sound',               // Hits res/raw/smart_sound.mp3 track on device
                    defaultSound: false,
                    visibility: 'public',               // Visible on Lock screen too
                    icon: '@mipmap/ic_launcher'
                }
            }
        };

        try {
            const response = await admin.messaging().send(message);
            console.log('🚀 International Standard Notification Sent Successfully:', response);
            return response;
        } catch (error) {
            console.error('❌ Error sending push notification globally:', error);
            throw error;
        }
    }
}

module.exports = NotificationService;