import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/l10n/translations.dart';
import '../../../navigation/main_shell.dart';
import '../providers/advisory_provider.dart';
import '../providers/announcements_provider.dart';

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
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const OfflineBanner(),
                const _HomeHeader(),
                advisoryAsync.when(
                  data: (advisory) => _StatsRow(advisory: advisory, t: t),
                  loading: () => const _StatsRowShim(),
                  error: (_, __) => _StatsRowShim(),
                ),
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
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? t.t('good_morning') : hour < 17 ? t.t('good_afternoon') : t.t('good_evening');

    return FutureBuilder<String>(
      future: FlutterSecureStorage().read(key: 'user_name'),
      builder: (context, snap) {
        final name = snap.data;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting${name != null && name.isNotEmpty ? ',' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.green100),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (name != null && name.isNotEmpty) ? name : t.t('farmer'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.white),
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
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AdvisoryData advisory;
  final Translations t;
  const _StatsRow({required this.advisory, required this.t});

  String _temp() {
    if (advisory.weather.tempMaxC == null) return '—';
    return '${advisory.weather.tempMaxC!.round()}°';
  }
  String _humidity() {
    if (advisory.weather.humidityPct == null) return '—';
    return '${advisory.weather.humidityPct!.round()}%';
  }
  String _rain() {
    final r = advisory.weather.rainfallMm24h;
    if (r == null) return '—';
    return '${r.toStringAsFixed(1)}mm';
  }
  String _soil() {
    final s = advisory.soil.moisturePct;
    if (s == null) return '—';
    return '${s.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _StatBubble(emoji: '🌡️', label: t.t('temperature'), value: _temp(), color: AppColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: _StatBubble(emoji: '💧', label: t.t('humidity'), value: _humidity(), color: AppColors.info)),
          const SizedBox(width: 8),
          Expanded(child: _StatBubble(emoji: '🌧️', label: t.t('rainfall'), value: _rain(), color: AppColors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _StatBubble(emoji: '🌱', label: t.t('soil_moisture'), value: _soil(), color: AppColors.green600)),
        ],
      ),
    );
  }
}

class _StatsRowShim extends StatelessWidget {
  const _StatsRowShim();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(child: _StatBubble(emoji: '🌡️', label: '', value: '—', color: Colors.grey)),
        SizedBox(width: 8),
        Expanded(child: _StatBubble(emoji: '💧', label: '', value: '—', color: Colors.grey)),
        SizedBox(width: 8),
        Expanded(child: _StatBubble(emoji: '🌧️', label: '', value: '—', color: Colors.grey)),
        SizedBox(width: 8),
        Expanded(child: _StatBubble(emoji: '🌱', label: '', value: '—', color: Colors.grey)),
      ]),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _StatBubble({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
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
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(advisory.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('todays_advisory'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        advisory.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                if (advisory.warnings.isNotEmpty) ...[
                  ...advisory.warnings.take(2).map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(w, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
                if (advisory.actions.isNotEmpty) ...[
                  const Text('What to do today:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D1B20))),
                  const SizedBox(height: 6),
                  ...advisory.actions.take(4).map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.green600, fontWeight: FontWeight.w700)),
                        Expanded(
                          child: Text(action, style: const TextStyle(fontSize: 14, height: 1.4)),
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
                      label: _riskLabel(advisory.riskLevel, t),
                      variant: switch (advisory.riskLevel.toLowerCase()) {
                        'high' => ChipVariant.red,
                        'medium' => ChipVariant.amber,
                        _ => ChipVariant.green,
                      },
                    ),
                    Text(
                      advisory.growthStageLabel,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

  String _riskLabel(String level, Translations t) {
    switch (level.toLowerCase()) {
      case 'high': return t.t('risk_high');
      case 'medium': return t.t('risk_medium');
      default: return t.t('risk_low');
    }
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
            child: Text(t.t('quick_actions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  emoji: '📷',
                  label: t.t('scan_crop'),
                  onTap: () => Navigator.pushNamed(context, '/scanner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '📅',
                  label: t.t('plan'),
                  onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '💰',
                  label: t.t('market'),
                  onTap: () => ref.read(currentTabProvider.notifier).state = 2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  emoji: '🌱',
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
  const _ActionButton({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
            child: Text(t.t('recent_alerts'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...announcements.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  a.level == 'high' || a.level == 'warning' ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: a.level == 'high' || a.level == 'warning' ? AppColors.warning : AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(a.body, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
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
