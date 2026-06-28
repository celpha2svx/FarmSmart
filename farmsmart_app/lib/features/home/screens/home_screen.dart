import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/l10n/translations.dart';
import '../../../navigation/main_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/advisory_provider.dart';
import '../providers/announcements_provider.dart';
import '../providers/weather_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisoryAsync = ref.watch(advisoryProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final t = ref.watch(translationsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(advisoryProvider);
            ref.invalidate(announcementsProvider);
            ref.invalidate(weatherProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const OfflineBanner(),
                _HomeHeader(t: t),
                const SizedBox(height: 8),
                const _StatsRow(),
                advisoryAsync.when(
                  data: (advisory) => _AdvisoryCard(advisory: advisory, t: t),
                  loading: () => const AdvisoryCardShimmer(),
                  error: (e, _) => ErrorCard(
                    message: t.t('advisory_error'),
                    onRetry: () => ref.invalidate(advisoryProvider),
                  ),
                ),
                const SizedBox(height: 8),
                _QuickActionsGrid(t: t),
                announcementsAsync.when(
                  data: (announcements) => _RecentAlerts(announcements: announcements, t: t),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  final Translations t;
  const _HomeHeader({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t.t('good_morning')
        : hour < 17
            ? t.t('good_afternoon')
            : t.t('good_evening');

    final auth = ref.watch(authProvider);
    final name = auth.user?.name?.isNotEmpty == true ? auth.user!.name! : t.t('farmer');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green700, AppColors.green500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.green100,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                    ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final weather = weatherAsync.valueOrNull;

    String fmt(double? v, String unit) =>
        v != null ? '${v.toStringAsFixed(0)}$unit' : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatBubble(
              emoji: '\u{1F321}\u{FE0F}',
              label: 'Temp',
              value: fmt(weather?.temperature, '°C'),
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBubble(
              emoji: '\u{1F4A7}',
              label: 'Humidity',
              value: fmt(weather?.humidity, '%'),
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBubble(
              emoji: '\u{1F327}\u{FE0F}',
              label: 'Rain',
              value: fmt(weather?.precipitation, 'mm'),
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatBubble(
              emoji: '\u{1F32C}\u{FE0F}',
              label: 'Wind',
              value: fmt(weather?.windSpeed, 'km/h'),
              color: AppColors.green600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatBubble({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.grey500,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final AdvisoryData advisory;
  final Translations t;
  const _AdvisoryCard({required this.advisory, required this.t});

  @override
  Widget build(BuildContext context) {
    final displayActions = advisory.actionItems.isNotEmpty
        ? advisory.actionItems.map((a) => a['text'] ?? '').where((s) => s.isNotEmpty).toList()
        : advisory.tips;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [AppShadows.sm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Text('\u{1F33D}', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('todays_advisory'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.green700,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        advisory.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advisory.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (displayActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...displayActions.take(4).map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('\u{2022} ',
                                style: TextStyle(color: AppColors.green600)),
                            Expanded(
                              child: Text(
                                action,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                if (advisory.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...advisory.warnings.take(2).map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                w,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppChip(
                      label: advisory.riskLevel,
                      variant: switch (advisory.riskLevel.toLowerCase()) {
                        'high' => ChipVariant.red,
                        'medium' => ChipVariant.amber,
                        _ => ChipVariant.green,
                      },
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.t('full_advisory')),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  final Translations t;
  const _QuickActionsGrid({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t.t('quick_actions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  emoji: '\u{1F4F7}',
                  label: t.t('scan_crop'),
                  onTap: () => Navigator.pushNamed(context, '/scanner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '\u{1F4C5}',
                  label: t.t('calendar'),
                  onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '\u{1F4B0}',
                  label: t.t('market'),
                  onTap: () => ref.read(currentTabProvider.notifier).state = 2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '\u{1F33F}',
                  label: t.t('advisory'),
                  onTap: () => ref.read(currentTabProvider.notifier).state = 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  final List<Announcement> announcements;
  final Translations t;
  const _RecentAlerts({required this.announcements, required this.t});

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t.t('recent_alerts'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...announcements.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      a.level == 'warning'
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                      color:
                          a.level == 'warning' ? AppColors.warning : AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.body,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
