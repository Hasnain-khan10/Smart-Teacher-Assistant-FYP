import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  // ✅ SAVE TOKEN + ROLE + LOGIN TIME
  static Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    await prefs.setString("role", role);

    // 🔥 Login hote hi current time save karein
    await prefs.setInt("login_time", DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);
  }

  // ✅ GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ✅ GET ROLE
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  // 🔥 CHECK IF SESSION IS EXPIRED (e.g., 24 Hours)
  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt("login_time");

    if (loginTime == null) return true; // Agar time nahi mila to matlab expired ya logged out hai

    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - loginTime;

    // Testing ke liye 30 seconds set hai
    const int sessionDuration = 259200000;

    if (difference > sessionDuration) {
      return true; // Session expire ho gayi hai
    }
    return false; // Session abhi valid hai
  }

  // ✅ ONLY CLEAR TOKEN & TIME (ROLE IS PRESERVED FOR UX) 🔥
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    // ❌ Yahan se role remove karne wali line mita di hai taake login screen yaad rahe
    await prefs.remove("login_time");
  }
}