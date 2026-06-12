// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:parent_teacher_meeting/Provider/auth_provider.dart';
// import 'package:parent_teacher_meeting/screens/LoginScreen.dart';
// import 'package:parent_teacher_meeting/services/storage_service.dart';
// import 'package:provider/provider.dart';


// class AppColors {
//   static const Color primary = Color(0xFF4F46E5);
//   static const Color accent = Color(0xFF7C3AED);
//   static const Color background = Color(0xFFF8F9FD);
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color textPrimary = Color(0xFF1E1B4B);
//   static const Color textSecondary = Color(0xFF6B7280);
//   static const Color success = Color(0xFF22C55E);
//   static const Color error = Color(0xFFEF4444);
//   static const Color warning = Color(0xFFF59E0B);
// }

// enum StudentTab { home, courses, quizzes, profile }

// class Studentplaceholderscreen extends StatefulWidget {

//   static const String routeName = '/student-placeholder';

//   const Studentplaceholderscreen({super.key});

//   @override
//   State<Studentplaceholderscreen> createState() => _StudentplaceholderscreenState();
// }

// class _StudentplaceholderscreenState extends State<Studentplaceholderscreen> {

//   StudentTab _currentTab = StudentTab.home;
//   bool _showJoinCoursePage = false;

//   final TextEditingController _courseLinkController = TextEditingController(
//     text: 'https://example.com/course/12345',
//   );

//   @override
//   void dispose() {
//     _courseLinkController.dispose();
//     super.dispose();
//   }

//   void _selectTab(StudentTab tab) {
//     setState(() {
//       _currentTab = tab;
//       if (tab != StudentTab.home) {
//         _showJoinCoursePage = false;
//       }
//     });
//   }

//   void _openJoinCourse() {
//     setState(() {
//       _currentTab = StudentTab.home;
//       _showJoinCoursePage = true;
//     });
//   }

//   void _closeJoinCourse() {
//     setState(() {
//       _showJoinCoursePage = false;
//       _currentTab = StudentTab.home;
//     });
//   }

//   Future<void> _joinCourse() async {
//     if (_courseLinkController.text.trim().isEmpty) return;

//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           insetPadding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Container(
//             padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [AppShadows.card],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 72,
//                   height: 72,
//                   decoration: BoxDecoration(
//                     color: AppColors.success.withOpacity(0.14),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.check_rounded,
//                     size: 42,
//                     color: AppColors.success,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Course Joined Successfully!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'You have successfully enrolled in Introduction to AI.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     height: 1.5,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 GradientButton(
//                   label: 'OK',
//                   onTap: () {
//                     Navigator.of(context).pop();
//                     _closeJoinCourse();
//                   },
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _pasteCourseLink() async {
//     final data = await Clipboard.getData('text/plain');
//     final pasted = data?.text?.trim();
//     if (pasted != null && pasted.isNotEmpty) {
//       setState(() {
//         _courseLinkController.text = pasted;
//       });
//     }
//   }

//   Widget _buildBody() {
//     if (_currentTab == StudentTab.home && _showJoinCoursePage) {
//       return JoinCourseScreen(
//         controller: _courseLinkController,
//         onBack: _closeJoinCourse,
//         onJoin: _joinCourse,
//         onPaste: _pasteCourseLink,
//       );
//     }

//     switch (_currentTab) {
//       case StudentTab.home:
//         return HomeScreen(
//           onJoinCourse: _openJoinCourse,
//           onViewAllCourses: () => _selectTab(StudentTab.courses),
//           onViewAllQuizzes: () => _selectTab(StudentTab.quizzes),
//         );
//       case StudentTab.courses:
//         return const CoursesScreen();
//       case StudentTab.quizzes:
//         return const QuizzesScreen();
//       case StudentTab.profile:
//         return const ProfileScreen();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppColors.background,
//               AppColors.surface,
//               AppColors.accent.withOpacity(0.06),
//             ],
//           ),
//         ),
//         child: SafeArea(child: _buildBody()),
//       ),
//       bottomNavigationBar: StudentBottomNavigation(
//         currentTab: _currentTab,
//         onChanged: _selectTab,
//       ),
//     );
//   }
// }

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({
//     super.key,
//     required this.onJoinCourse,
//     required this.onViewAllCourses,
//     required this.onViewAllQuizzes,
//   });

//   final VoidCallback onJoinCourse;
//   final VoidCallback onViewAllCourses;
//   final VoidCallback onViewAllQuizzes;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const DashboardHeader(),
//           const SizedBox(height: 24),
//           JoinCourseActionButton(onTap: onJoinCourse),
//           const SizedBox(height: 26),
//           SectionCard(
//             title: 'Current Courses',
//             actionLabel: 'View All',
//             onActionTap: onViewAllCourses,
//             child: const CoursePreviewTile(),
//           ),
//           const SizedBox(height: 20),
//           SectionCard(
//             title: 'Upcoming Quizzes',
//             actionLabel: 'View All',
//             onActionTap: onViewAllQuizzes,
//             child: const QuizPreviewTile(),
//           ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }
// }

// class JoinCourseScreen extends StatelessWidget {
//   const JoinCourseScreen({
//     super.key,
//     required this.controller,
//     required this.onBack,
//     required this.onJoin,
//     required this.onPaste,
//   });

//   final TextEditingController controller;
//   final VoidCallback onBack;
//   final VoidCallback onJoin;
//   final VoidCallback onPaste;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(18, 16, 24, 12),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: onBack,
//                 child: const Icon(
//                   Icons.arrow_back_ios_new_rounded,
//                   color: AppColors.accent,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Join Course',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Enter Course Link',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 TextField(
//                   controller: controller,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.accent,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   decoration: InputDecoration(
//                     hintText: 'https://example.com/course/12345',
//                     hintStyle: const TextStyle(
//                       fontSize: 16,
//                       color: AppColors.textSecondary,
//                     ),
//                     fillColor: AppColors.surface,
//                     filled: true,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 18,
//                       vertical: 18,
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(18),
//                       borderSide: BorderSide(
//                         color: AppColors.accent.withOpacity(0.06),
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(18),
//                       borderSide: BorderSide(
//                         color: AppColors.primary.withOpacity(0.18),
//                       ),
//                     ),
//                     suffixIcon: IconButton(
//                       onPressed: onPaste,
//                       icon: const Icon(
//                         Icons.content_paste_rounded,
//                         color: AppColors.accent,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 22),
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(28),
//                     boxShadow: [AppShadows.card],
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 84,
//                             height: 84,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(20),
//                               gradient: const LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [AppColors.primary, AppColors.accent],
//                               ),
//                               boxShadow: [AppShadows.button],
//                             ),
//                             child: const Icon(
//                               Icons.menu_book_rounded,
//                               size: 42,
//                               color: AppColors.surface,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           const Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Introduction to\nAI',
//                                   style: TextStyle(
//                                     fontSize: 22,
//                                     height: 1.0,
//                                     fontWeight: FontWeight.w700,
//                                     color: AppColors.textPrimary,
//                                   ),
//                                 ),
//                                 SizedBox(height: 12),
//                                 Text(
//                                   'Dr. Sarah Khan',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: AppColors.textSecondary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 18),
//                       Container(
//                         height: 1,
//                         color: AppColors.textSecondary.withOpacity(0.15),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Spacer(),
//                 GradientButton(
//                   label: 'Join Course',
//                   onTap: onJoin,
//                   height: 62,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class CoursesScreen extends StatelessWidget {
//   const CoursesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Courses',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'All your courses in one place',
//             style: TextStyle(
//               fontSize: 18,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface.withOpacity(0.92),
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [AppShadows.card],
//             ),
//             child: Column(
//               children: [
//                 SectionTopRow(
//                   icon: Icons.menu_book_rounded,
//                   title: 'Current Courses',
//                   subtitle: 'Courses you are currently learning',
//                   trailingCount: '2',
//                 ),
//                 const SizedBox(height: 16),
//                 const DetailedCourseTile(
//                   icon: Icons.psychology_alt_rounded,
//                   title: 'Introduction to AI',
//                   subtitle: 'Dr. Sarah Khan',
//                   trailingLabel: 'View PDF',
//                   progress: 0.75,
//                   progressText: '75% Complete',
//                   filledButton: true,
//                 ),
//                 const SizedBox(height: 14),
//                 const DetailedCourseTile(
//                   icon: Icons.code_rounded,
//                   title: 'Web Development Basics',
//                   subtitle: 'Prof. Ahmed Saeed',
//                   trailingLabel: 'View PDF',
//                   progress: 0.40,
//                   progressText: '40% Complete',
//                   filledButton: true,
//                   iconLight: true,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 22),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface.withOpacity(0.92),
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [AppShadows.card],
//             ),
//             child: Column(
//               children: [
//                 SectionTopRow(
//                   icon: Icons.history_rounded,
//                   title: 'Previous Courses',
//                   subtitle: 'Courses you have completed',
//                   trailingCount: '2',
//                 ),
//                 const SizedBox(height: 16),
//                 const PreviousCourseTile(
//                   icon: Icons.data_object_rounded,
//                   iconBackground: AppColors.primary,
//                   title: 'Data Structures & Algorithms',
//                   subtitle: 'Ms. Ayesha Ali',
//                   completedOn: 'Completed on Dec 10, 2024',
//                 ),
//                 const SizedBox(height: 14),
//                 const PreviousCourseTile(
//                   icon: Icons.storage_rounded,
//                   iconBackground: AppColors.warning,
//                   title: 'Database Management Systems',
//                   subtitle: 'Dr. Usman Khalid',
//                   completedOn: 'Completed on Oct 05, 2024',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class QuizzesScreen extends StatelessWidget {
//   const QuizzesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Quizzes',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Keep track of your assessments',
//             style: TextStyle(
//               fontSize: 18,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface.withOpacity(0.92),
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [AppShadows.card],
//             ),
//             child: Column(
//               children: const [
//                 SectionOnlyHeader(title: 'Upcoming Quizzes', trailingCount: '2 To Do'),
//                 SizedBox(height: 16),
//                 UpcomingQuizTile(
//                   title: 'Introduction to AI - Quiz 2',
//                   dueLabel: 'Due April 26',
//                 ),
//                 SizedBox(height: 14),
//                 UpcomingQuizTile(
//                   title: 'Web Development Basics - Quiz 3',
//                   dueLabel: 'Due April 29',
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 22),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface.withOpacity(0.92),
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [AppShadows.card],
//             ),
//             child: Column(
//               children: const [
//                 SectionOnlyHeader(title: 'Previous Quizzes', trailingCount: '4 Completed'),
//                 SizedBox(height: 16),
//                 PreviousQuizTile(
//                   title: 'Data Structures & Algorithms - Quiz 1',
//                   metaOne: 'Completed • April 10',
//                   metaTwo: 'Ms. Ayesha Katza',
//                 ),
//                 SizedBox(height: 14),
//                 PreviousQuizTile(
//                   title: 'Python Programming',
//                   metaOne: 'Completed • March 5',
//                   metaTwo: 'Mi. Rzzad',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text(
//             'Profile',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Manage your personal information',
//             style: TextStyle(
//               fontSize: 18,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           SizedBox(height: 22),
//           ProfileCard(),
//           SizedBox(height: 18),
//           ProfileInfoTile(
//             icon: Icons.email_outlined,
//             title: 'Email',
//             value: 'alihassan123@gmail.com',
//           ),
//           SizedBox(height: 16),
//           ProfileInfoTile(
//             icon: Icons.badge_outlined,
//             title: 'Roll Number',
//             value: '123456',
//           ),
//           SizedBox(height: 16),
//           ProfileInfoTile(
//             icon: Icons.school_rounded,
//             title: 'Class / Dept.',
//             value: 'BS Computer Science, 5th Semester',
//           ),
//           SizedBox(height: 16),
//           ProfileInfoTile(
//             icon: Icons.calendar_month_outlined,
//             title: 'Semester',
//             value: '5th Semester',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DashboardHeader extends StatelessWidget {
//   const DashboardHeader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Hello, Ahmed 👋',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   const Text(
//                     'Ready to learn today?',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: AppColors.textSecondary,
//                     ),
//                   ),
//                     Consumer<AuthProvider>(
//       builder: (context, authProvider, _) {
//         return IconButton(
//           icon: const Icon(Icons.logout, color: Colors.red),
//           onPressed: () async {
            
//             /// LOGOUT FROM PROVIDER
//             await authProvider.logout();

//             /// CLEAR TOKEN + ROLE
//             await StorageService.clearAll();

//             /// NAVIGATE TO LOGIN
//             Navigator.pushNamedAndRemoveUntil(
//               context,
//               LoginScreen.routeName,
//               (route) => false,
//             );

//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("Logged out successfully"),
//                 behavior: SnackBarBehavior.floating,
//               ),
//             );
//           },
//         );
//       },
//     ),
//                 ],
//               ),
          
//             ],
//           ),
//         ),
//         const SizedBox(width: 16),
//         Container(
//           width: 56,
//           height: 56,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 AppColors.primary.withOpacity(0.18),
//                 AppColors.accent.withOpacity(0.18),
//               ],
//             ),
//             boxShadow: [AppShadows.soft],
//           ),
//           child: const Icon(
//             Icons.person_rounded,
//             size: 30,
//             color: AppColors.textPrimary,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class JoinCourseActionButton extends StatelessWidget {
//   const JoinCourseActionButton({super.key, required this.onTap});

//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(28),
//           gradient: const LinearGradient(
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//             colors: [AppColors.primary, AppColors.accent],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.accent.withOpacity(0.30),
//               blurRadius: 22,
//               offset: const Offset(0, 14),
//               spreadRadius: -10,
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Positioned(
//               right: 34,
//               top: 6,
//               child: _SparkleCluster(opacity: 0.85),
//             ),
//             Row(
//               children: [
//                 Container(
//                   width: 56,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     color: AppColors.surface.withOpacity(0.88),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.add_rounded,
//                     size: 34,
//                     color: AppColors.primary,
//                   ),
//                 ),
//                 const SizedBox(width: 18),
//                 const Text(
//                   'Join Course',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.surface,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SectionCard extends StatelessWidget {
//   const SectionCard({
//     super.key,
//     required this.title,
//     required this.actionLabel,
//     required this.onActionTap,
//     required this.child,
//   });

//   final String title;
//   final String actionLabel;
//   final VoidCallback onActionTap;
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
//       decoration: BoxDecoration(
//         color: AppColors.surface.withOpacity(0.92),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [AppShadows.card],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//               GestureDetector(
//                 onTap: onActionTap,
//                 child: Row(
//                   children: [
//                     Text(
//                       actionLabel,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     const Icon(
//                       Icons.chevron_right_rounded,
//                       size: 20,
//                       color: AppColors.textSecondary,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }
// }

// class CoursePreviewTile extends StatelessWidget {
//   const CoursePreviewTile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Introduction to AI',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Dr. Sarah Khan',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: AppColors.accent.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Row(
//                   children: const [
//                     Icon(
//                       Icons.menu_book_rounded,
//                       size: 18,
//                       color: AppColors.primary,
//                     ),
//                     SizedBox(width: 6),
//                     Text(
//                       '75%',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           const AppProgressBar(progress: 0.78),
//         ],
//       ),
//     );
//   }
// }

// class QuizPreviewTile extends StatelessWidget {
//   const QuizPreviewTile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Midterm Quiz',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Introduction to AI',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Due in 2 days',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.warning,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           GradientSmallButton(label: 'Attempt'),
//         ],
//       ),
//     );
//   }
// }

// class SectionTopRow extends StatelessWidget {
//   const SectionTopRow({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.trailingCount,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final String trailingCount;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 70,
//           height: 70,
//           decoration: BoxDecoration(
//             color: AppColors.accent.withOpacity(0.08),
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [AppShadows.soft],
//           ),
//           child: Icon(icon, color: AppColors.primary, size: 34),
//         ),
//         const SizedBox(width: 14),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 subtitle,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: AppColors.accent.withOpacity(0.10),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Text(
//             trailingCount,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: AppColors.primary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class SectionOnlyHeader extends StatelessWidget {
//   const SectionOnlyHeader({
//     super.key,
//     required this.title,
//     required this.trailingCount,
//   });

//   final String title;
//   final String trailingCount;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             title,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           decoration: BoxDecoration(
//             color: AppColors.accent.withOpacity(0.10),
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Text(
//             trailingCount,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: AppColors.primary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class DetailedCourseTile extends StatelessWidget {
//   const DetailedCourseTile({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.trailingLabel,
//     required this.progress,
//     required this.progressText,
//     required this.filledButton,
//     this.iconLight = false,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final String trailingLabel;
//   final double progress;
//   final String progressText;
//   final bool filledButton;
//   final bool iconLight;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 74,
//                 height: 74,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   gradient: iconLight
//                       ? LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             AppColors.primary.withOpacity(0.20),
//                             AppColors.accent.withOpacity(0.20),
//                           ],
//                         )
//                       : const LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [AppColors.primary, AppColors.accent],
//                         ),
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 38,
//                   color: iconLight ? AppColors.primary : AppColors.surface,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       subtitle,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: AppColors.textSecondary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 14),
//               filledButton
//                   ? const GradientSmallButton(label: 'View PDF')
//                   : const OutlineSmallButton(label: 'View PDF'),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(child: AppProgressBar(progress: progress)),
//               const SizedBox(width: 10),
//               Text(
//                 progressText,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PreviousCourseTile extends StatelessWidget {
//   const PreviousCourseTile({
//     super.key,
//     required this.icon,
//     required this.iconBackground,
//     required this.title,
//     required this.subtitle,
//     required this.completedOn,
//   });

//   final IconData icon;
//   final Color iconBackground;
//   final String title;
//   final String subtitle;
//   final String completedOn;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 74,
//             height: 74,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               color: iconBackground.withOpacity(0.18),
//             ),
//             child: Icon(icon, size: 38, color: iconBackground),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   subtitle,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: AppColors.success.withOpacity(0.14),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     completedOn,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.success,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           const OutlineSmallButton(label: 'View PDF'),
//         ],
//       ),
//     );
//   }
// }

// class UpcomingQuizTile extends StatelessWidget {
//   const UpcomingQuizTile({
//     super.key,
//     required this.title,
//     required this.dueLabel,
//   });

//   final String title;
//   final String dueLabel;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 66,
//             height: 66,
//             decoration: BoxDecoration(
//               color: AppColors.accent.withOpacity(0.10),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: const Icon(
//               Icons.assignment_rounded,
//               size: 34,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   dueLabel,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           const GradientSmallButton(label: 'Attempt'),
//         ],
//       ),
//     );
//   }
// }

// class PreviousQuizTile extends StatelessWidget {
//   const PreviousQuizTile({
//     super.key,
//     required this.title,
//     required this.metaOne,
//     required this.metaTwo,
//   });

//   final String title;
//   final String metaOne;
//   final String metaTwo;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.soft],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 66,
//             height: 66,
//             decoration: BoxDecoration(
//               color: AppColors.success.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: const Icon(
//               Icons.check_circle_rounded,
//               size: 34,
//               color: AppColors.success,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   metaOne,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   metaTwo,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           const GradientSmallButton(label: 'See Result'),
//         ],
//       ),
//     );
//   }
// }

// class ProfileCard extends StatelessWidget {
//   const ProfileCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
//       decoration: BoxDecoration(
//         color: AppColors.surface.withOpacity(0.92),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [AppShadows.card],
//       ),
//       child: Column(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 116,
//                 height: 116,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       AppColors.primary.withOpacity(0.14),
//                       AppColors.accent.withOpacity(0.14),
//                     ],
//                   ),
//                   boxShadow: [AppShadows.soft],
//                 ),
//                 child: const Icon(
//                   Icons.person_rounded,
//                   size: 62,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               Positioned(
//                 right: -2,
//                 bottom: 2,
//                 child: Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: AppColors.accent.withOpacity(0.16),
//                     shape: BoxShape.circle,
//                     boxShadow: [AppShadows.soft],
//                   ),
//                   child: const Icon(
//                     Icons.camera_alt_rounded,
//                     size: 22,
//                     color: AppColors.primary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 18),
//           const Text(
//             'Ali Hassan',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Roll No. 123456',
//             style: TextStyle(
//               fontSize: 16,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'BS Computer Science, 5th Semester',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 16,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Align(
//             alignment: Alignment.centerRight,
//             child: Container(
//               width: 52,
//               height: 52,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: AppColors.surface,
//                 boxShadow: [AppShadows.soft],
//               ),
//               child: const Icon(
//                 Icons.edit_outlined,
//                 color: AppColors.textSecondary,
//                 size: 24,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ProfileInfoTile extends StatelessWidget {
//   const ProfileInfoTile({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.value,
//   });

//   final IconData icon;
//   final String title;
//   final String value;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//       decoration: BoxDecoration(
//         color: AppColors.surface.withOpacity(0.92),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [AppShadows.card],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(18),
//               color: AppColors.accent.withOpacity(0.10),
//             ),
//             child: Icon(icon, size: 32, color: AppColors.primary),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.surface,
//               boxShadow: [AppShadows.soft],
//             ),
//             child: const Icon(
//               Icons.edit_outlined,
//               color: AppColors.textSecondary,
//               size: 24,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class GradientButton extends StatelessWidget {
//   const GradientButton({
//     super.key,
//     required this.label,
//     required this.onTap,
//     this.height = 60,
//   });

//   final String label;
//   final VoidCallback onTap;
//   final double height;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: height,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: const LinearGradient(
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//             colors: [AppColors.primary, AppColors.accent],
//           ),
//           boxShadow: [AppShadows.button],
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           label,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: AppColors.surface,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class GradientSmallButton extends StatelessWidget {
//   const GradientSmallButton({super.key, required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         gradient: const LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [AppColors.primary, AppColors.accent],
//         ),
//         boxShadow: [AppShadows.button],
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//           color: AppColors.surface,
//         ),
//       ),
//     );
//   }
// }

// class OutlineSmallButton extends StatelessWidget {
//   const OutlineSmallButton({super.key, required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: AppColors.primary, width: 1.3),
//         color: AppColors.surface,
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//           color: AppColors.primary,
//         ),
//       ),
//     );
//   }
// }

// class AppProgressBar extends StatelessWidget {
//   const AppProgressBar({super.key, required this.progress});

//   final double progress;

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: LinearProgressIndicator(
//         minHeight: 10,
//         value: progress,
//         backgroundColor: AppColors.primary.withOpacity(0.15),
//         valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
//       ),
//     );
//   }
// }

// class StudentBottomNavigation extends StatelessWidget {
//   const StudentBottomNavigation({
//     super.key,
//     required this.currentTab,
//     required this.onChanged,
//   });

//   final StudentTab currentTab;
//   final ValueChanged<StudentTab> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
//       decoration: BoxDecoration(
//         color: AppColors.surface.withOpacity(0.95),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.textPrimary.withOpacity(0.06),
//             blurRadius: 22,
//             offset: const Offset(0, -6),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           BottomNavItem(
//             icon: Icons.home_rounded,
//             label: 'Home',
//             active: currentTab == StudentTab.home,
//             onTap: () => onChanged(StudentTab.home),
//           ),
//           BottomNavItem(
//             icon: Icons.menu_book_rounded,
//             label: 'Courses',
//             active: currentTab == StudentTab.courses,
//             onTap: () => onChanged(StudentTab.courses),
//           ),
//           BottomNavItem(
//             icon: Icons.fact_check_rounded,
//             label: 'Quizzes',
//             active: currentTab == StudentTab.quizzes,
//             onTap: () => onChanged(StudentTab.quizzes),
//           ),
//           BottomNavItem(
//             icon: Icons.person_rounded,
//             label: 'Profile',
//             active: currentTab == StudentTab.profile,
//             onTap: () => onChanged(StudentTab.profile),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BottomNavItem extends StatelessWidget {
//   const BottomNavItem({
//     super.key,
//     required this.icon,
//     required this.label,
//     required this.active,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final bool active;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final color = active ? AppColors.primary : AppColors.textSecondary;

//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, color: color, size: 30),
//               const SizedBox(height: 6),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: active ? FontWeight.w600 : FontWeight.w500,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SparkleCluster extends StatelessWidget {
//   const _SparkleCluster({required this.opacity});

//   final double opacity;

//   @override
//   Widget build(BuildContext context) {
//     return Opacity(
//       opacity: opacity,
//       child: SizedBox(
//         width: 74,
//         height: 36,
//         child: Stack(
//           children: [
//             Positioned(
//               top: 0,
//               left: 26,
//               child: _sparkle(10),
//             ),
//             Positioned(
//               top: 12,
//               left: 8,
//               child: _sparkle(7),
//             ),
//             Positioned(
//               top: 14,
//               left: 44,
//               child: _sparkle(7),
//             ),
//             Positioned(
//               top: 2,
//               left: 58,
//               child: _sparkle(8),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sparkle(double size) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: AppColors.surface.withOpacity(0.95),
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.surface.withOpacity(0.6),
//             blurRadius: 10,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class AppShadows {
//   static BoxShadow get card => BoxShadow(
//         color: AppColors.primary.withOpacity(0.06),
//         blurRadius: 22,
//         offset: const Offset(0, 10),
//         spreadRadius: -10,
//       );

//   static BoxShadow get soft => BoxShadow(
//         color: AppColors.textPrimary.withOpacity(0.05),
//         blurRadius: 18,
//         offset: const Offset(0, 8),
//         spreadRadius: -12,
//       );

//   static BoxShadow get button => BoxShadow(
//         color: AppColors.accent.withOpacity(0.24),
//         blurRadius: 16,
//         offset: const Offset(0, 8),
//         spreadRadius: -8,
//       ); 
// }



// //  static const String routeName = '/student-placeholder';