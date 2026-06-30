import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class MarketEntry {
  final String name;
  final int priceNgn;        // per bag
  final int? perKgNgn;
  final String? distanceKm;
  final String? updatedAgo;
  const MarketEntry({
    required this.name,
    required this.priceNgn,
    this.perKgNgn,
    this.distanceKm,
    this.updatedAgo,
  });

  factory MarketEntry.fromJson(Map<String, dynamic> j) => MarketEntry(
        name: (j['name'] as String?) ?? 'Unknown',
        priceNgn: (j['price_ngn'] as num?)?.toInt() ?? 0,
        perKgNgn: (j['per_kg_ngn'] as num?)?.toInt(),
        distanceKm: j['distance_km']?.toString(),
        updatedAgo: j['updated_ago'] as String?,
      );
}

class MarketData {
  final String crop;
  final int? currentPriceNgn;
  final double? changePct24h;
  final List<int> weeklyPricesNgn;
  final List<MarketEntry> markets;
  final String? asOf;
  final bool noData;
  const MarketData({
    required this.crop,
    required this.currentPriceNgn,
    required this.changePct24h,
    required this.weeklyPricesNgn,
    required this.markets,
    required this.asOf,
    required this.noData,
  });
}

final marketPricesProvider = FutureProvider.family<MarketData, String>((ref, crop) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/api/market/prices', params: {'crop': crop.toLowerCase()}) as Map;
  final markets = (data['markets'] as List<dynamic>?)
          ?.map((m) => MarketEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList() ??
      const [];
  final weekly = (data['weekly_prices_ngn'] as List<dynamic>?)
          ?.map((p) => (p as num).toInt())
          .toList() ??
      const <int>[];
  return MarketData(
    crop: crop,
    currentPriceNgn: (data['current_price_ngn'] as num?)?.toInt(),
    changePct24h: (data['change_pct_24h'] as num?)?.toDouble(),
    weeklyPricesNgn: weekly,
    markets: markets,
    asOf: data['as_of'] as String?,
    noData: data['current_price_ngn'] == null,
  );
});
