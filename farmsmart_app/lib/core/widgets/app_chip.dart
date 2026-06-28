import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ChipVariant { green, amber, red, earth }

class AppChip extends StatelessWidget {
  final String label;
  final ChipVariant variant;

  const AppChip({
    super.key,
    required this.label,
    this.variant = ChipVariant.green,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (variant) {
      ChipVariant.green => (AppColors.green100, AppColors.green800),
      ChipVariant.amber => (AppColors.warning.withValues(alpha: 0.15), AppColors.warning),
      ChipVariant.red => (AppColors.error.withValues(alpha: 0.15), AppColors.error),
      ChipVariant.earth => (AppColors.earth100, AppColors.earth800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
