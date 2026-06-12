import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';


class TeacherGenerateAIPlanScreen extends StatefulWidget {
  static const String generateAiPlan = '/generate-ai-plan';

  final String? courseId;

  const TeacherGenerateAIPlanScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<TeacherGenerateAIPlanScreen> createState() =>
      _TeacherGenerateAIPlanScreenState();
}

class _TeacherGenerateAIPlanScreenState
    extends State<TeacherGenerateAIPlanScreen> {
  final TextEditingController _promptController = TextEditingController();
  File? _selectedFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // ================= FILE PICK =================
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // ================= CAMERA =================
  Future<void> _takePhoto() async {
    try {
      final XFile? image =
      await _imagePicker.pickImage(source: ImageSource.camera);

      if (image == null) return;

      setState(() {
        _selectedFile = File(image.path);
      });
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  // ================= GENERATE =================
  Future<void> _generatePlan(WeekPlanProvider provider) async {
    if (widget.courseId == null) return;

    bool success = false;

    if (_selectedFile != null) {
      success = await provider.generateAIPlanFromBook(
        widget.courseId!,
        _selectedFile!,
      );
    } else {
      success = await provider.generateAIPlan(
        widget.courseId!,
        prompt: _promptController.text.trim(),
      );
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("18 Weekly AI Plan Generated Successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeekPlanProvider>(context);
    final isLoading =
        provider.isGeneratingAI || provider.isGeneratingFromBook;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7F8FC),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "AI Plan Generator",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Smart Curriculum Designer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Upload Book OR Enter Prompt → Generate 18-Week Plan",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [

                    // ================= PRO TIPS =================
                    _card(
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("💡 Pro Tips",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 8),
                          Text("• Upload Image or PDF for best AI accuracy"),
                          Text("• Use camera for quick book capture"),
                          Text("• Add specific prompt for better results"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ================= FILE CARD =================
                    _card(
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFile != null
                                  ? _selectedFile!.path.split('/').last
                                  : "No file selected",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedFile != null)
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedFile = null;
                              }),
                              child: const Icon(Icons.close,
                                  color: Colors.red),
                            )
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ================= INPUT =================
                    _card(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _promptController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _pickFile,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _takePhoto,
                          ),
                          hintText:
                          "Enter prompt OR attach file / capture image...",
                          hintStyle: TextStyle(
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(provider.error!,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    // ================= BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => _generatePlan(provider),
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : Text(
                              _selectedFile != null
                                  ? "Generate from Book"
                                  : "Generate from Prompt",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= REUSABLE CARD =================
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}