import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontened/core/api.dart'; // Handles your baseUrl location

class SocketService {
  static IO.Socket? _socket;

  // 🔥 INITIALIZE CORE REAL-TIME SOCKET ECOSYSTEM
  static void initialize(BuildContext context, List<String> enrolledCourseIds) {
    if (_socket != null && _socket!.connected) return;

    // Connects safely to your local node.js instance running on port 5002
    _socket = IO.io(Api.baseUrl.replaceAll('/api', ''), IO.OptionBuilder()
        .setTransports(['websocket']) // Force clean high-speed protocol layer
        .enableAutoConnect()
        .build());

    _socket!.onConnect((_) {
      debugPrint("🔌 Real-time Notification Tunnel established successfully!");

      // Registers student device to all enrolled courses rooms instantly
      for (String courseId in enrolledCourseIds) {
        _socket!.emit("join_course_room", courseId);
      }
    });

    // 🔥 GLOBAL EVENT LISTENER: Catch events from your quiz/plan controller
    _socket!.on("new_notification", (data) {
      if (data != null) {
        String title = data['title'] ?? "Academic Update";
        String message = data['message'] ?? "New content published.";

        // Show real-time beautiful top overlay dialog instantly to user
        _showInAppPushNotification(context, title, message);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint("❌ Notification Tunnel disconnected safely.");
    });
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
              color: const Color(0xFF1E1B4B), // Premium dark theme matching your layout
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
                    Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
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