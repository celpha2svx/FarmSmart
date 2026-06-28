import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/scanner_provider.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) _analyze(file.path);
  }

  Future<void> _pickGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) _analyze(file.path);
  }

  Future<void> _analyze(String path) async {
    try {
      final result = await ref.read(scannerProvider.notifier).analyze(path);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ScanResultScreen(imagePath: path, result: result),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t.t('scanner'), style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: CustomPaint(
                  painter: _FramePainter(),
                  child: Center(
                    child: state.isAnalyzing
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: AppColors.green400),
                              const SizedBox(height: 16),
                              Text(t.t('analyzing'), style: const TextStyle(color: Colors.white70)),
                            ],
                          )
                        : const Icon(Icons.camera_alt, size: 64, color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isAnalyzing ? null : _takePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(t.t('take_photo'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isAnalyzing ? null : _pickGallery,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                    ),
                    icon: const Icon(Icons.photo_library, color: Colors.white70),
                    label: Text(t.t('choose_gallery'), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const cornerLength = 24;
    final r = 24.0;

    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);

    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    canvas.drawLine(const Offset(0, size.height - cornerLength), const Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
