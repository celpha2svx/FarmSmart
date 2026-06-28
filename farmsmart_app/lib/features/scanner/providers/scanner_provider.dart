import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
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
    required this.pestId,
    required this.pestName,
    required this.confidence,
    required this.severity,
    required this.treatment,
    this.prevention,
    this.isSimulated = false,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        pestId: json['pest_id'] as String? ?? '',
        pestName: json['pest_name'] as String? ?? 'Unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        severity: json['severity'] as String? ?? 'low',
        treatment: json['treatment'] as String? ?? 'No treatment data available.',
        prevention: json['prevention'] as String?,
        isSimulated: json['is_simulated'] as bool? ?? false,
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
  final FlutterSecureStorage _storage;

  ScannerNotifier(this._api, this._storage) : super(const ScanResultState());

  Future<ScanResult> analyze(String imagePath) async {
    state = const ScanResultState(isAnalyzing: true);

    final phone = await _storage.read(key: 'phone') ?? '';
    final token = await _storage.read(key: 'auth_token') ?? '';

    if (phone.isEmpty || token.isEmpty) {
      const err = 'Not authenticated. Please sign in again.';
      state = const ScanResultState(error: err);
      throw Exception(err);
    }

    try {
      final res = await _api.uploadFile(
        '/api/pest/detect',
        imagePath,
        fields: {'phone': phone, 'token': token},
      );
      final resultData = res['result'] as Map<String, dynamic>? ?? res;
      final result = ScanResult.fromJson(resultData);
      state = ScanResultState(result: result);
      return result;
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 401
          ? 'Session expired. Please sign in again.'
          : 'Analysis failed. Please try again.';
      state = ScanResultState(error: msg);
      throw Exception(msg);
    } catch (e) {
      const msg = 'Analysis failed. Please try again.';
      state = const ScanResultState(error: msg);
      throw Exception(msg);
    }
  }

  void reset() => state = const ScanResultState();
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScanResultState>((ref) {
  return ScannerNotifier(FarmSmartApiClient(), const FlutterSecureStorage());
});
