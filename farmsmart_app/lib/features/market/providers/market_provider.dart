import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class MarketEntry {
  final String name;
  final double pricePerBag;
  final String distanceKm;
  final String updatedAgo;
  const MarketEntry({required this.name, required this.pricePerBag, required this.distanceKm, required this.updatedAgo});
}

class MarketData {
  final String crop;
  final double currentPrice;
  final double changePercent;
  final List<double> weeklyPrices;
  final List<MarketEntry> markets;
  final String updatedAgo;
  const MarketData({
    required this.crop, required this.currentPrice, required this.changePercent,
    required this.weeklyPrices, required this.markets, required this.updatedAgo,
  });
}

final marketPricesProvider = FutureProvider.family<MarketData, String>((ref, crop) async {
  final api = FarmSmartApiClient();
  final res = await api.get('/market_prices', params: {'crop': crop});
  final data = res['data'] as Map<String, dynamic>? ?? {};
  final marketsList = (data['markets'] as List<dynamic>?)?.map((m) {
    final mm = m as Map<String, dynamic>;
    return MarketEntry(
      name: mm['name'] as String? ?? 'Unknown',
      pricePerBag: (mm['price_per_bag'] as num?)?.toDouble() ?? 0,
      distanceKm: mm['distance_km']?.toString() ?? '0',
      updatedAgo: mm['updated_ago'] as String? ?? 'Today',
    );
  }).toList() ?? [];
  final weekly = (data['weekly_prices'] as List<dynamic>?)?.map((p) => (p as num).toDouble()).toList() ?? [];

  return MarketData(
    crop: crop,
    currentPrice: (data['current_price'] as num?)?.toDouble() ?? 0,
    changePercent: (data['change_percent'] as num?)?.toDouble() ?? 0,
    weeklyPrices: weekly,
    markets: marketsList,
    updatedAgo: data['updated_ago'] as String? ?? '',
  );
});
