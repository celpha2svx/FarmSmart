import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class MarketEntry {
  final String name;
  final double priceNgn;
  final String unit;
  final String priceDate;
  final String source;
  const MarketEntry({
    required this.name,
    required this.priceNgn,
    required this.unit,
    required this.priceDate,
    required this.source,
  });
}

class MarketData {
  final String crop;
  final double? currentPrice;
  final String? currentMarket;
  final String? currentUnit;
  final String? priceDate;
  final double changePercent;
  final List<double> weeklyPrices;
  final List<MarketEntry> markets;

  const MarketData({
    required this.crop,
    this.currentPrice,
    this.currentMarket,
    this.currentUnit,
    this.priceDate,
    required this.changePercent,
    required this.weeklyPrices,
    required this.markets,
  });
}

final marketPricesProvider = FutureProvider.family<MarketData, String>((ref, crop) async {
  final api = FarmSmartApiClient();
  final res = await api.get('/api/market/prices', params: {
    'crop': crop.toLowerCase(),
    'days': '7',
  });

  final prices = res['prices'] as List<dynamic>? ?? [];
  final latestRaw = res['latest_price'] as Map<String, dynamic>?;

  final entries = prices.map((p) {
    final m = p as Map<String, dynamic>;
    return MarketEntry(
      name: m['market'] as String? ?? 'Unknown Market',
      priceNgn: (m['price_ngn'] as num?)?.toDouble() ?? 0,
      unit: m['unit'] as String? ?? '50kg bag',
      priceDate: m['price_date'] as String? ?? '',
      source: m['source'] as String? ?? '',
    );
  }).toList();

  final sorted = List<MarketEntry>.from(entries)
    ..sort((a, b) => b.priceDate.compareTo(a.priceDate));

  final weeklyPrices = sorted.take(7).map((e) => e.priceNgn).toList().reversed.toList();

  double changePercent = 0;
  if (weeklyPrices.length >= 2) {
    final first = weeklyPrices.first;
    final last = weeklyPrices.last;
    if (first > 0) changePercent = ((last - first) / first) * 100;
  }

  final uniqueMarkets = <String, MarketEntry>{};
  for (final e in sorted) {
    uniqueMarkets.putIfAbsent(e.name, () => e);
  }

  return MarketData(
    crop: crop,
    currentPrice: latestRaw != null ? (latestRaw['price_ngn'] as num?)?.toDouble() : null,
    currentMarket: latestRaw?['market'] as String?,
    currentUnit: latestRaw?['unit'] as String?,
    priceDate: latestRaw?['price_date'] as String?,
    changePercent: changePercent,
    weeklyPrices: weeklyPrices,
    markets: uniqueMarkets.values.toList(),
  );
});
