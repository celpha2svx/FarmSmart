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
    final severityColor = switch (result.severity) {
      'high' => AppColors.red500,
      'medium' => AppColors.amber500,
      _ => AppColors.green500,
    };
    final severityVariant = switch (result.severity) {
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: Text('\u{1F52C}', style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(height: 12),
                  Text(t.t('analyzing'),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(t.t('scan_hint'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
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
                  borderRadius: AppRadius.md,
                  boxShadow: AppShadows.md,
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
                          child: const Center(child: Text('\u{1F41B}', style: TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.pestName,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20)),
                              const SizedBox(height: 4),
                              AppChip(label: '${result.severity.toUpperCase()} RISK', variant: severityVariant),
                            ],
                          ),
                        ),
                        Text('${result.confidence.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 24, color: severityColor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    Text('\u{1F48A} ${t.t('treatment')}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(result.treatment, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),

                    if (result.prevention != null) ...[
                      const SizedBox(height: 20),
                      Text('\u{1F6E1} Prevention', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(result.prevention!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                    ],
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
                      ),
                      icon: const Text('\u{1F504}', style: TextStyle(fontSize: 16)),
                      label: Text(t.t('scan_crop'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Text('\u{1F4DD}', style: TextStyle(fontSize: 14)),
                    label: Text('Report incorrect result',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
