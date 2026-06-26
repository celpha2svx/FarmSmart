import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/constants/app_constants.dart';
import 'package:farmsmart_app/core/localization/app_localizations.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/app.dart';

/// 3-step farm setup: Crop → Location → Farm Size
/// Conversation-style (one question per screen, big visual cards)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _selectedCrop;
  String? _selectedLocation;
  String? _selectedSize;

  final List<String> _steps = ['crop', 'location', 'size'];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(t),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations t) {
    switch (_step) {
      case 0: return _buildCropStep(t);
      case 1: return _buildLocationStep(t);
      case 2: return _buildSizeStep(t);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildCropStep(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '🌱',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            t.translate('select_crop'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose from 20 crops',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: CropConstants.cropCategories.entries.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            CropConstants.categoryIcons[category.key] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CropConstants.categoryLabels[category.key] ?? category.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...category.value.map((crop) => _buildCropCard(crop)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(String crop) {
    final isSelected = _selectedCrop == crop;
    final displayName = CropConstants.cropDisplayNames[crop] ?? crop;
    final emoji = CropConstants.cropEmojis[crop] ?? '🌱';

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCrop = crop);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _step = 1);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('📍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            t.translate('select_location'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your LGA or nearest town',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'e.g., Zaria, Ibadan North, Sabon Gari',
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) => _selectedLocation = v,
          ),
          const SizedBox(height: 16),
          // Quick-select common locations
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Zaria', 'Kano', 'Ibadan', 'Abuja', 'Lagos', 'Kaduna']
                .map((loc) => ActionChip(
                  label: Text(loc),
                  onPressed: () {
                    setState(() => _selectedLocation = loc);
                  },
                ))
                .toList(),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedLocation != null && _selectedLocation!.isNotEmpty
                ? () => setState(() => _step = 2)
                : null,
            child: Text(t.translate('next')),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeStep(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('📏', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            t.translate('select_size'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSizeCard('small', '🌱', t.translate('small'), 'Best for backyard farms'),
          _buildSizeCard('medium', '🌿', t.translate('medium'), 'Most common for Nigerian farmers'),
          _buildSizeCard('large', '🌳', t.translate('large'), 'Commercial farming'),
          const Spacer(),
          ElevatedButton(
            onPressed: _selectedSize != null ? _finishOnboarding : null,
            child: Text(t.translate('done')),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeCard(String value, String emoji, String title, String subtitle) {
    final isSelected = _selectedSize == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding() {
    ref.read(onboardingCompleteProvider.notifier).complete();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }
}
