import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TeacherScannerOverlay extends StatefulWidget {
  final String studentName;
  final String quizTitle;

  const TeacherScannerOverlay({
    super.key,
    required this.studentName,
    required this.quizTitle,
  });

  @override
  State<TeacherScannerOverlay> createState() => _TeacherScannerOverlayState();
}

class _TeacherScannerOverlayState extends State<TeacherScannerOverlay> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  final List<File> _capturedPages = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedPages.add(File(image.path));
        _isCapturing = false;
      });
    } catch (e) {
      setState(() => _isCapturing = false);
    }
  }

  void _finishScanning() {
    if (_capturedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Capture at least one page to evaluate."), backgroundColor: Colors.red));
      return;
    }
    // Return the captured files back to the Quiz Management Center to process via AI
    Navigator.pop(context, _capturedPages);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL SCREEN CAMERA
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // 2. SCANNING FRAME OVERLAY
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(borderColor: const Color(0xFF4F46E5), borderWidth: 3.0),
              ),
            ),
          ),

          // 3. TOP INFO BAR
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  Column(
                    children: [
                      const Text("Scanning Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("${widget.studentName} - ${widget.quizTitle}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(12)),
                    child: Text("${_capturedPages.length} Pages", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),

          // 4. BOTTOM CONTROLS & THUMBNAILS
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnails Row
                  if (_capturedPages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _capturedPages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                              image: DecorationImage(image: FileImage(_capturedPages[index]), fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Capture & Done Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 60), // Spacer to center the capture button
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: _capturedPages.isNotEmpty
                            ? IconButton(onPressed: _finishScanning, icon: const Icon(Icons.check_circle, color: Colors.green, size: 40))
                            : null,
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Custom Painter for the clear cutout in the middle of a dark overlay
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;

  const _ScannerOverlayShape({required this.borderColor, required this.borderWidth});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: rect.center, width: rect.width * 0.8, height: rect.height * 0.6),
          const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutoutRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: rect.width * 0.8, height: rect.height * 0.6),
        const Radius.circular(16));

    canvas.drawPath(getOuterPath(rect), paint);
    canvas.drawRRect(cutoutRect, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}