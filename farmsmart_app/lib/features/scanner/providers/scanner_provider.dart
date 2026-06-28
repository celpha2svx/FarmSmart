import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

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
  final FarmSmartApiClient _api;
  ScannerNotifier(this._api) : super(const ScanResultState());

  Future<ScanResult> analyze(String imagePath) async {
    state = const ScanResultState(isAnalyzing: true);
    try {
      final res = await _api.uploadFile('/pest_detect', imagePath);
      final result = ScanResult.fromJson(res);
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
  return ScannerNotifier(FarmSmartApiClient());
});
