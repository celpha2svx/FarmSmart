import 'package:flutter/material.dart';
import 'package:farmsmart_app/core/theme/colors.dart';

/// AI Crop Scanner — take a photo of plant leaves,
/// and AI identifies pests/diseases (TensorFlow Lite).
class CropScannerScreen extends StatefulWidget {
  const CropScannerScreen({super.key});

  @override
  State<CropScannerScreen> createState() => _CropScannerScreenState();
}

class _CropScannerScreenState extends State<CropScannerScreen> {
  bool _isScanning = false;
  String? _result;
  String? _confidence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Scanner'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isScanning
                  ? _buildScanningView()
                  : _result != null
                      ? _buildResultView()
                      : _buildIdleView(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildIdleView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          'Take a photo of your crop',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Point camera at leaves or fruit\nto detect pests & diseases',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Sample pest quick info
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI identifies 17 common pests & diseases in Nigerian crops.',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanningView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 24),
        const Text(
          'Analyzing your crop...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Step indicators
        _scanStep('Capturing image', true),
        _scanStep('Processing with AI', false),
        _scanStep('Identifying pests', false),
        _scanStep('Generating advice', false),
      ],
    );
  }

  Widget _scanStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? AppColors.success : AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: done ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: done ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Result icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _result?.contains('No pest') == true
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _result?.contains('No pest') == true
                  ? Icons.check_circle
                  : Icons.warning,
              size: 40,
              color: _result?.contains('No pest') == true
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _result ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_confidence != null) ...[
            const SizedBox(height: 8),
            Text(
              'Confidence: $_confidence',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _result = null;
                  _confidence = null;
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Again'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: Icon(_isScanning ? Icons.hourglass_top : Icons.camera_alt),
            label: Text(_isScanning ? 'Scanning...' : 'Take Photo'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      ),
    );
  }

  void _startScan() async {
    setState(() => _isScanning = true);

    // Simulate AI processing (replace with actual TFLite inference)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _result = 'Fall Armyworm detected';
        _confidence = '87%';
      });
    }
  }
}
