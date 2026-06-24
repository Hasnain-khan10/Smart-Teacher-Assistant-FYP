import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontened/core/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 🔥 INITIALIZE CORE REAL-TIME SOCKET ECOSYSTEM
  static void initialize(BuildContext context, List<String> enrolledCourseIds) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(Api.baseUrl.replaceAll('/api', ''), IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build());

    _socket!.onConnect((_) {
      debugPrint("🔌 Real-time Notification Tunnel established successfully!");

      for (String courseId in enrolledCourseIds) {
        _socket!.emit("join_course_room", courseId);
      }
    });

    // 🔥 GLOBAL EVENT LISTENER
    _socket!.on("new_notification", (data) {
      if (data != null) {
        String title = data['title'] ?? "Academic Update";
        String message = data['message'] ?? "New content published.";

        // 🔥 FIXED: Direct trigger to system UI top banner bar instead of snackbar overlay
        _showNativeTopBannerNotification(title, message);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint("❌ Notification Tunnel disconnected safely.");
    });
  }

  // 🔥 NATIVE HEADS-UP POPUP DISPLAY ENGINE (Snapchat & Facebook Style Top Pop)
  static Future<void> _showNativeTopBannerNotification(String title, String message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_teacher_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for academic alerts.',
        importance: Importance.max, // Mandatory for Heads-up popups
        priority: Priority.high,    // Mandatory for top banner execution
        sound: RawResourceAndroidNotificationSound('smart_sound'),
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Dynamic ID to prevent overwriting updates
        title: title,
        body: message,
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint("Native Top Banner Audio Exception: $e");
    }
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}