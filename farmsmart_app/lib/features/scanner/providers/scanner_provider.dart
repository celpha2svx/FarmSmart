import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanResult {
  final String pestId;
  final String pestName;
  final double confidence;
  final String severity;
  final String treatment;
  final String? prevention;
  final bool isSimulated;
  const ScanResult({
    required this.pestId, required this.pestName, required this.confidence,
    required this.severity, required this.treatment, this.prevention,
    this.isSimulated = false,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    pestId: json['pest_id'] ?? '',
    pestName: json['pest_name'] ?? 'Unknown',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    severity: json['severity'] ?? 'low',
    treatment: json['treatment'] ?? 'No treatment data available',
    prevention: json['prevention'],
    isSimulated: json['is_simulated'] ?? false,
  );
}

class ScanResultState {
  final bool isAnalyzing;
  final ScanResult? result;
  final String? error;
  const ScanResultState({this.isAnalyzing = false, this.result, this.error});
}

class ScannerNotifier extends StateNotifier<ScanResultState> {
  ScannerNotifier() : super(const ScanResultState());

  Future<ScanResult> analyze(String imagePath) async {
    state = const ScanResultState(isAnalyzing: true);
    try {
      // In production: POST /api/pest/detect with image
      await Future.delayed(const Duration(seconds: 2));
      final result = ScanResult(
        pestId: 'fall_armyworm',
        pestName: 'Fall Armyworm',
        confidence: 87.3,
        severity: 'high',
        treatment: 'Apply Emamectin Benzoate 1.9% EC at 2ml/L water. Spray in the evening. Alternate with Chlorantraniliprole if re-infestation occurs after 7 days.',
        prevention: 'Scout fields weekly. Use neem extract as preventive spray every 2 weeks.',
      );
      state = ScanResultState(result: result);
      return result;
    } catch (e) {
      state = ScanResultState(error: e.toString());
      rethrow;
    }
  }

  void reset() => state = const ScanResultState();
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScanResultState>((ref) {
  return ScannerNotifier();
});
