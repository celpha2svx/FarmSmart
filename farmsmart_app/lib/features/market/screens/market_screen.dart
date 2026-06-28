import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/market_provider.dart';

final _crops = ['Maize', 'Rice', 'Beans', 'Millet', 'Groundnut'];
final _cropEmojis = {'Maize': '\u{1F33D}', 'Rice': '\u{1F33E}', 'Beans': '\u{1FAD8}', 'Millet': '\u{1F33F}', 'Groundnut': '\u{1F95C}'};
final _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _selectedCrop = 'Maize';

  @override
  Widget build(BuildContext context) {
    final marketAsync = ref.watch(marketPricesProvider(_selectedCrop));
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: OfflineBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _crops.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final crop = _crops[index];
                    final selected = crop == _selectedCrop;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCrop = crop),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.green600 : AppColors.surface,
                          borderRadius: AppRadius.full,
                          border: Border.all(color: selected ? AppColors.green600 : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(_cropEmojis[crop]!, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(crop,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                color: selected ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          marketAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: true,
              child: ShimmerLoader(),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: true,
              child: ErrorState(message: e.toString()),
            ),
            data: (data) => SliverList(
              delegate: SliverChildListDelegate([
                _PriceHeroCard(data: data),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(t.t('market_comparison'),
                    style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                ...data.markets.map((m) => _MarketRow(entry: m)),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHeroCard extends StatelessWidget {
  final MarketData data;
  const _PriceHeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final changeColor = data.changePercent >= 0 ? AppColors.green500 : AppColors.red500;
    return Container(
      margin: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.crop, style: Theme.of(context).textTheme.displayMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: AppRadius.full,
                ),
                child: Text('${data.changePercent >= 0 ? '+' : ''}${data.changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(color: changeColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('\u{20A6}${data.currentPrice.toStringAsFixed(0)}/bag',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.green800)),
          Text('Last 7 days', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.weeklyPrices.reduce((a, b) => a > b ? a : b) * 1.15,
                barGroups: data.weeklyPrices.asMap().entries.map((e) =>
                  BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: AppColors.green400,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]),
                ).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _dayLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_dayLabels[idx], style: const TextStyle(fontSize: 10, color: AppColors.inkMuted)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final MarketEntry entry;
  const _MarketRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sm,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store, color: AppColors.green700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('${entry.distanceKm} km away \u00B7 ${entry.updatedAgo}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
                ],
              ),
            ),
            Text('\u{20A6}${entry.pricePerBag.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.green800)),
          ],
        ),
      ),
    );
  }
}
