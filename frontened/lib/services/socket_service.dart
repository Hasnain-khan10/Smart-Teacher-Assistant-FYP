import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 🔥 Required to play native sound instantly in-app
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontened/core/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 🔥 INITIALIZE CORE REAL-TIME SOCKET ECOSYSTEM
  static void initialize(BuildContext context, List<String> enrolledCourseIds) {
    if (_socket != null && _socket!.connected) return;

    // Connects safely to your Node.js instance
    _socket = IO.io(Api.baseUrl.replaceAll('/api', ''), IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());

    _socket!.onConnect((_) {
      debugPrint("🔌 Real-time Notification Tunnel established successfully!");

      // Registers device to all enrolled courses rooms instantly
      for (String courseId in enrolledCourseIds) {
        _socket!.emit("join_course_room", courseId);
      }
    });

    // 🔥 GLOBAL EVENT LISTENER: Catch events from your controllers
    _socket!.on("new_notification", (data) {
      if (data != null) {
        String title = data['title'] ?? "Academic Update";
        String message = data['message'] ?? "New content published.";

        // 🔥 TRIGGER NATIVE AUDIO CONTEXT ALONG WITH OVERLAY
        _playInAppNotificationSound();

        // Show real-time beautiful top overlay dialog instantly to user
        _showInAppPushNotification(context, title, message);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint("❌ Notification Tunnel disconnected safely.");
    });
  }

  // 🔥 NATIVE AUDIO SYSTEM PLAYER FOR IN-APP FOREGROUND (Facebook/Snapchat Vibe)
  static Future<void> _playInAppNotificationSound() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_teacher_channel', // Must map exactly with your channel definitions
        'High Importance Notifications',
        channelDescription: 'This channel is used for academic alerts.',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('smart_sound'), // 🎵 Hits your native custom mp3 asset track
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      // 🔥 FIXED ERROR: Passed all values as explicit named arguments (`id:`, `title:`, etc.)
      await _localNotifications.show(
        id: 999,
        title: null,
        body: null,
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint("Audio Engine Exception Error: $e");
    }
  }

  // 🔥 CUSTOM TOP BAR OVERLAY NOTIFICATION DISPLAY ENGINE
  static void _showInAppPushNotification(BuildContext context, String title, String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(top: 10, left: 15, right: 10),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              border: Border.all(color: const Color(0xFF4F46E5), width: 1.5)
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications_active, color: Color(0xFF22C55E), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => scaffoldMessenger.hideCurrentSnackBar(),
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              )
            ],
          ),
        ),
      ),
    );
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}