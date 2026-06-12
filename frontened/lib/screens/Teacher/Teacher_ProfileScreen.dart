import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/screens/Teacher/Teacher_Login.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';



class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {

  final _nameController = TextEditingController();
final _fatherController = TextEditingController();
final _cnicController = TextEditingController();
final _departmentController = TextEditingController();
final _qualificationController = TextEditingController();
final _experienceController = TextEditingController();
final _specialityController = TextEditingController();
  

     File? _selectedProfileImage;

final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
void dispose() {
  _nameController.dispose();
  _fatherController.dispose();
  _cnicController.dispose();
  _departmentController.dispose();
  _qualificationController.dispose();
  _experienceController.dispose();
  _specialityController.dispose();
  super.dispose();
}

  Future<void> _pickProfileImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );

  if (image != null) {
    setState(() {
      _selectedProfileImage = File(image.path);
    });
  }
}

  /// ================= LOGOUT FUNCTION =================
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ICON
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                /// TITLE
                const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                /// SUBTITLE
                const Text(
                  "Are you sure you want to logout from your account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                /// BUTTONS
                Row(
                  children: [
                    /// CANCEL
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// LOGOUT
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    await StorageService.removeToken();

    if (!mounted) return;

    /// SNACKBAR
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: Colors.green,
        content: const Text(
          "Logged out successfully",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      TeacherLoginScreen.teacherRouteName,
      (route) => false,
    );
  }
  

  Future<void> _showEditProfileBottomSheet() async {
  final user =
      context.read<AuthProvider>().user;

  if (user == null) return;

  _nameController.text =
      user.name;

  _fatherController.text =
      user.fatherName ?? "";

  _cnicController.text =
      user.cnic ?? "";

  _departmentController.text =
      user.department ?? "";

  _qualificationController.text =
      user.qualification ?? "";

  _experienceController.text =
      user.experience ?? "";

  _specialityController.text =
      user.speciality ?? "";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(30),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  20,
        ),
        child: SingleChildScrollView(
          child:Column(
  mainAxisSize: MainAxisSize.min,
  children: [

    GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [

          CircleAvatar(
            radius: 50,

            backgroundImage:
                _selectedProfileImage != null
                    ? FileImage(
                        _selectedProfileImage!,
                      )
                    : (user.profileImage != null &&
                            user.profileImage!.isNotEmpty)
                        ? NetworkImage(
                            user.profileImage!,
                          )
                        : null,

            child: (_selectedProfileImage == null &&
                    (user.profileImage == null ||
                        user.profileImage!.isEmpty))
                ? Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 20),

              _buildTextField(
                "Full Name",
                _nameController,
              ),

              _buildTextField(
                "Father Name",
                _fatherController,
              ),

              _buildTextField(
                "CNIC",
                _cnicController,
              ),

              _buildTextField(
                "Department",
                _departmentController,
              ),

              _buildTextField(
                "Qualification",
                _qualificationController,
              ),

              _buildTextField(
                "Experience",
                _experienceController,
              ),

              _buildTextField(
                "Speciality",
                _specialityController,
              ),

              const SizedBox(height: 20),

              Consumer<AuthProvider>(
  builder: (context, provider, child) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () async {

                final success =
                    await provider.updateProfile(
                  profileImage: _selectedProfileImage,

                  name: _nameController.text.trim(),

                  fatherName:
                      _fatherController.text.trim(),

                  cnic:
                      _cnicController.text.trim(),

                  department:
                      _departmentController.text.trim(),

                  qualification:
                      _qualificationController.text.trim(),

                  experience:
                      _experienceController.text.trim(),

                  speciality:
                      _specialityController.text.trim(),
                );

                if (!mounted) return;

                if (success) {

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Profile Updated Successfully",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  await context
                      .read<AuthProvider>()
                      .loadProfile();

                } else {

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.error ??
                            "Update failed",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),

        child: provider.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Update Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  },
)
            ],
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Profile",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// PROFILE IMAGE
                      Center(
                        child: Stack(
                          children: [
                           CircleAvatar(
  radius: 45,
  backgroundColor: Colors.white,

  backgroundImage:
      user.profileImage != null &&
              user.profileImage!.isNotEmpty
          ? NetworkImage(
              user.profileImage!,
            )
          : null,

  child:
      user.profileImage == null ||
              user.profileImage!.isEmpty
          ? Text(
              user.name.isNotEmpty
                  ? user.name[0]
                      .toUpperCase()
                  : "T",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// PROFILE CARD
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _inputField("Full Name", user.name),
                                const SizedBox(height: 14),
                                _inputField("Email", user.email),
                                const SizedBox(height: 14),
                                _inputField("Role", user.role),
                                const SizedBox(height: 14),
                                _inputField(
                                    "Department", user.department ?? "N/A"),
                                const SizedBox(height: 14),
                                _inputField("Qualification",
                                    user.qualification ?? "N/A"),
                                const SizedBox(height: 14),
                                _inputField(
                                    "Experience", user.experience ?? "N/A"),
                                const SizedBox(height: 14),
                                _inputField(
                                    "Speciality", user.speciality ?? "N/A"),
                                const SizedBox(height: 14),
                                _inputField("CNIC", user.cnic ?? "N/A"),
                                const SizedBox(height: 14),
                                _inputField(
                                    "Father Name", user.fatherName ?? "N/A"),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// SAVE BUTTON
                      GestureDetector(
                        onTap: _showEditProfileBottomSheet,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// LOGOUT BUTTON
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(
  String label,
  TextEditingController controller,
) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom: 14,
    ),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),
    ),
  );
}

  /// ================= INPUT FIELD =================
  Widget _inputField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}