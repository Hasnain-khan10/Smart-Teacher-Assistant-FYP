const admin = require('firebase-admin');
const { getMessaging } = require('firebase-admin/messaging');

class NotificationService {
    /**
     * Sends an International Standard Heads-Up Notification (Top Popup with Sound)
     * Works when app is in Foreground, Background, or completely Closed/Killed.
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
            data: payloadData,
            notification: {
                title: title,
                body: body,
            },
            android: {
                priority: 'high', // Forces high priority delivery
                notification: {
                    channelId: 'smart_teacher_channel', // Maps precisely with Flutter main.dart
                    priority: 'high',                  // Max priority for heads-up popup
                    sound: 'smart_sound',               // Hits res/raw/smart_sound.mp3 track on device
                    defaultSound: false,
                    visibility: 'public',
                    icon: '@mipmap/ic_launcher'
                }
            }
        };

        try {
            // Using modern direct messaging engine instance
            const response = await getMessaging().send(message);
            console.log('🚀 International Standard Notification Sent Successfully:', response);
            return response;
        } catch (error) {
            console.error('❌ Error sending push notification globally:', error);
            throw error;
        }
    }
}

module.exports = NotificationService;