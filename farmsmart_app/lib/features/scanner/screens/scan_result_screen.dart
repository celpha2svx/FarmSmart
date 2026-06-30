import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/scanner_provider.dart';

class ScanResultScreen extends ConsumerWidget {
  final String imagePath;
  final ScanResult result;
  const ScanResultScreen({super.key, required this.imagePath, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    if (result.isUnknown) return _UnknownView(t: t);

    final severityColor = switch (result.severity.toLowerCase()) {
      'high' => AppColors.red500,
      'medium' => AppColors.amber500,
      _ => AppColors.green500,
    };
    final severityVariant = switch (result.severity.toLowerCase()) {
      'high' => ChipVariant.red,
      'medium' => ChipVariant.amber,
      _ => ChipVariant.green,
    };

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.green800, AppColors.green700],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: Text('🔬', style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(height: 12),
                  Text(result.pestName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (result.scientificName != null) ...[
                    const SizedBox(height: 4),
                    Text(result.scientificName!,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppShadows.md],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.red100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(child: Text('🐛', style: TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.pestName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              AppChip(
                                label: '${result.severity.toUpperCase()} RISK',
                                variant: severityVariant,
                              ),
                            ],
                          ),
                        ),
                        Text('${result.confidence.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: severityColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t.t('confidence')}: ${(result.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    Text('💊 ${t.t('treatment')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(result.treatment, style: const TextStyle(fontSize: 14, height: 1.6)),

                    if (result.prevention != null) ...[
                      const SizedBox(height: 20),
                      const Text('🛡️ Prevention', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(result.prevention!, style: const TextStyle(fontSize: 14, height: 1.6)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                  label: Text(t.t('scan_crop'),
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _UnknownView extends ConsumerWidget {
  final Translations t;
  const _UnknownView({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(child: Text('🤔', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 24),
              Text(
                t.t('unknown_pest_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                t.t('unknown_pest_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('🔄'),
                  label: Text(t.t('try_again'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
