import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/providers/core_providers.dart';

class ScanResult {
  final String pestId;
  final String pestName;
  final String? scientificName;
  final double confidence;       // 0.0 - 1.0
  final String severity;         // 'low' | 'medium' | 'high' | 'unknown'
  final String treatment;
  final String? prevention;
  final bool isSimulated;        // always false now — but we keep the flag for forward-compat
  final String? modelVersion;
  final bool isUnknown;          // true when the server returns 'unable to identify'

  const ScanResult({
    required this.pestId,
    required this.pestName,
    this.scientificName,
    required this.confidence,
    required this.severity,
    required this.treatment,
    this.prevention,
    this.isSimulated = false,
    this.modelVersion,
    this.isUnknown = false,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final id = (json['pest_id'] as String?) ?? 'unknown';
    final unknown = id == 'unknown';
    return ScanResult(
      pestId: id,
      pestName: (json['pest_name'] as String?) ?? (unknown ? 'Unable to identify' : 'Unknown'),
      scientificName: json['scientific_name'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      severity: (json['severity'] as String?) ?? 'unknown',
      treatment: (json['treatment'] as String?) ?? 'No treatment data available',
      prevention: json['prevention'] as String?,
      isSimulated: json['is_simulated'] == true,
      modelVersion: json['model_version'] as String?,
      isUnknown: unknown,
    );
  }
}

class ScanResultState {
  final bool isAnalyzing;
  final ScanResult? result;
  final String? error;
  const ScanResultState({this.isAnalyzing = false, this.result, this.error});

  ScanResultState copyWith({bool? isAnalyzing, ScanResult? result, String? error}) =>
      ScanResultState(
        isAnalyzing: isAnalyzing ?? this.isAnalyzing,
        result: result ?? this.result,
        error: error,
      );
}

class ScannerNotifier extends StateNotifier<ScanResultState> {
  final dynamic _api;        // FarmSmartApiClient
  ScannerNotifier(this._api) : super(const ScanResultState());

  Future<ScanResult> analyze(String imagePath) async {
    state = const ScanResultState(isAnalyzing: true);
    try {
      final storage = FlutterSecureStorage();
      final phone = await storage.read(key: 'phone') ?? '';
      final data = await _api.uploadFile(
        '/api/pest/detect',
        imagePath,
        extraFields: {'phone': phone},
      ) as Map;
      final resultJson = (data['result'] as Map?) ?? {};
      final result = ScanResult.fromJson(Map<String, dynamic>.from(resultJson));
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
  return ScannerNotifier(ref.read(apiClientProvider));
});
