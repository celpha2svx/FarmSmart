import 'package:flutter/material.dart';
import 'package:farmsmart_app/core/constants/app_constants.dart';
import 'package:farmsmart_app/core/theme/colors.dart';

/// Market Prices — Chinese "今日粮价" (Today's Grain Price).
/// Shows current prices across Nigerian markets.
class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  String _selectedCrop = 'maize';
  String _selectedMarket = 'Dawanau';

  final List<String> _markets = ['Dawanau', 'Mile 12', 'Bodija', 'Kurmi', 'Ogbete', 'Singa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Crop selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryLight.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select crop',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: CropConstants.allCrops.map((crop) {
                      final isSelected = _selectedCrop == crop;
                      final emoji = CropConstants.cropEmojis[crop] ?? '🌱';
                      final name = CropConstants.cropDisplayNames[crop] ?? crop;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCrop = crop),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Market tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Text('Market: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedMarket,
                  items: _markets.map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedMarket = v);
                  },
                  underline: const SizedBox(),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Updated today',
                    style: TextStyle(fontSize: 11, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Prices
          Expanded(child: _buildPriceList()),
        ],
      ),
    );
  }

  Widget _buildPriceList() {
    final prices = _getMockPrices();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: prices.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = prices[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _priceColor(index).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  index == 0 ? Icons.trending_up : index == prices.length - 1 ? Icons.trending_down : Icons.trending_flat,
                  color: _priceColor(index),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['unit']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      p['note']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                p['price']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, String>> _getMockPrices() {
    // In production, fetched from backend API that scrapes Nigerian market data
    final cropName = _selectedCrop == 'maize' ? 'Maize' : 'Rice';

    return [
      {'unit': '1 kg', 'price': '₦850', 'note': 'Retail price'},
      {'unit': '50 kg bag', 'price': '₦38,500', 'note': 'Wholesale (Dawanau)'},
      {'unit': '100 kg bag', 'price': '₦74,000', 'note': 'Wholesale (Mile 12)'},
      {'unit': '1 tonne', 'price': '₦720,000', 'note': 'Bulk commercial'},
      {'unit': '1 bowl', 'price': '₦2,500', 'note': 'Local market unit'},
    ];
  }

  Color _priceColor(int index) {
    if (index == 0) return AppColors.warning;
    if (index == 2) return AppColors.success;
    if (index == 4) return AppColors.error;
    return AppColors.info;
  }
}
