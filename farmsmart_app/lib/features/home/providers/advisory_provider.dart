import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdvisoryData {
  final String title;
  final String message;
  final String riskLevel;
  final List<String> actions;
  const AdvisoryData({
    required this.title, required this.message,
    required this.riskLevel, required this.actions,
  });
}

final advisoryProvider = FutureProvider<AdvisoryData>((ref) async {
  // In production: call API client
  // For now, return real-looking data
  return AdvisoryData(
    title: '🌽 Maize Advisory — Tasseling & Silking',
    message: 'Your maize is in the critical tasseling stage. Ensure adequate soil moisture for good grain fill. Apply potassium (MOP) at 100kg/ha for better yields.',
    riskLevel: 'Low',
    actions: [
      'Apply irrigation if no rain in 3 days',
      'Scout for fall armyworm in whorl leaves',
      'Side-dress with Urea if not done at 4 weeks',
    ],
  );
});
