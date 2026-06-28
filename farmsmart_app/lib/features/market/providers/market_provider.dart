import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // In production: call GET /api/market/prices?crop=X
  return MarketData(
    crop: crop,
    currentPrice: crop == 'Maize' ? 38500 : crop == 'Rice' ? 57000 : crop == 'Beans' ? 40000 : 34500,
    changePercent: 5.4,
    weeklyPrices: [37000, 37200, 36800, 37500, 38000, 38200, 38500],
    markets: [
      MarketEntry(name: 'Dawanau (Kano)', pricePerBag: 38200, distanceKm: '0', updatedAgo: 'Today'),
      MarketEntry(name: 'Mile 12 (Lagos)', pricePerBag: 42000, distanceKm: '15', updatedAgo: 'Yesterday'),
      MarketEntry(name: 'Bodija (Ibadan)', pricePerBag: 40500, distanceKm: '8', updatedAgo: 'Today'),
    ],
    updatedAgo: 'Today 6:00 AM',
  );
});
