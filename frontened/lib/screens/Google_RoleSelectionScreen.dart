// import 'package:flutter/material.dart';
// import 'package:parent_teacher_meeting/screens/Student/Main_Screen.dart';
// import 'package:provider/provider.dart';

// import '../Provider/auth_provider.dart';
// import 'Teacher/TeacherPlaceholderScreen.dart';


// class GoogleRoleSelectionScreen extends StatefulWidget {
//   static const String routeName = '/Google_role-selection';

//   const GoogleRoleSelectionScreen({super.key});

//   @override
//   State<GoogleRoleSelectionScreen> createState() =>
//       _GoogleRoleSelectionScreenState();
// }

// class _GoogleRoleSelectionScreenState
//     extends State<GoogleRoleSelectionScreen> {


//   String? selectedRole;
//   bool isLoading = false;

//   Future<void> _selectRole(String role) async {
//     setState(() {
//       selectedRole = role;
//       isLoading = true;
//     });

//     final authProvider =
//         Provider.of<AuthProvider>(context, listen: false);

//     bool success = await authProvider.setRole(role);

//     setState(() => isLoading = false);

//     if (!success) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(authProvider.error ?? "Failed to set role"),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final user = authProvider.user;

//     if (user == null) return;

//     // ✅ Navigate based on role
//     if (user.role == "teacher") {
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         TeacherPlaceholderScreen.routeName,
//         (route) => false,
//       );
//     } else {
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         MainScreen.routeName,
//         (route) => false,
//       );
//     }
//   }

//   Widget _roleCard({
//     required String role,
//     required IconData icon,
//     required String title,
//   }) {
//     final isSelected = selectedRole == role;

//     return GestureDetector(
//       onTap: isLoading ? null : () => _selectRole(role),
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue.shade50 : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected ? Colors.blue : Colors.grey.shade300,
//             width: 2,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: 30, color: Colors.blue),
//             const SizedBox(width: 15),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const Spacer(),
//             if (isSelected)
//               const Icon(Icons.check_circle, color: Colors.blue),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Select Your Role"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             const Text(
//               "Choose how you want to continue",
//               style: TextStyle(fontSize: 16),
//             ),

//             const SizedBox(height: 30),

//             // 👨‍🏫 Teacher
//             _roleCard(
//               role: "teacher",
//               icon: Icons.school,
//               title: "I'm a Teacher",
//             ),

//             const SizedBox(height: 20),

//             // 🎓 Student
//             _roleCard(
//               role: "student",
//               icon: Icons.person,
//               title: "I'm a Student",
//             ),

//             const SizedBox(height: 40),

//             if (isLoading)
//               const CircularProgressIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }