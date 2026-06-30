import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../providers/onboarding_provider.dart';

class LgaSuggestion {
  final String name;
  final double lat;
  final double lon;
  const LgaSuggestion({required this.name, required this.lat, required this.lon});
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  /// Per-crop planting selection. Key = crop id (lowercase). Value = ISO date.
  final Map<String, String> _plantings = {};
  final List<String> _cropOrder = [];

  LgaSuggestion? _lga;
  String _lgaQuery = '';
  List<LgaSuggestion> _lgaSuggestions = [];
  bool _searchingLga = false;
  String? _farmSize;

  static const List<Map<String, String>> _crops = [
    {'id': 'maize',     'name': 'Maize',     'emoji': '🌽'},
    {'id': 'rice',      'name': 'Rice',      'emoji': '🌾'},
    {'id': 'cassava',   'name': 'Cassava',   'emoji': '🌱'},
    {'id': 'yam',       'name': 'Yam',       'emoji': '🍠'},
    {'id': 'tomato',    'name': 'Tomato',    'emoji': '🍅'},
    {'id': 'pepper',    'name': 'Pepper',    'emoji': '🌶️'},
    {'id': 'groundnut', 'name': 'Groundnut', 'emoji': '🥜'},
    {'id': 'sorghum',   'name': 'Sorghum',   'emoji': '🌾'},
    {'id': 'soybean',   'name': 'Soybean',   'emoji': '🫘'},
  ];

  bool get _canContinue {
    switch (_currentStep) {
      case 0: return _plantings.isNotEmpty;
      case 1: return _lga != null;
      case 2: return _farmSize != null;
      case 3: return _plantings.values.every((d) => d.isNotEmpty);
      default: return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _searchLga(String q) async {
    _lgaQuery = q;
    if (q.trim().isEmpty) {
      setState(() {
        _lgaSuggestions = const [];
        _searchingLga = false;
      });
      return;
    }
    setState(() => _searchingLga = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.get('/api/locations/search', params: {'q': q, 'limit': '8'}) as Map;
      final results = (data['results'] as List<dynamic>?) ?? [];
      setState(() {
        _lgaSuggestions = results.map((j) {
          final m = Map<String, dynamic>.from(j);
          return LgaSuggestion(
            name: (m['name'] as String?) ?? '',
            lat: ((m['lat'] as num?) ?? 0).toDouble(),
            lon: ((m['lon'] as num?) ?? 0).toDouble(),
          );
        }).toList();
        _searchingLga = false;
      });
    } catch (e) {
      setState(() {
        _lgaSuggestions = const [];
        _searchingLga = false;
      });
    }
  }

  Future<void> _finish() async {
    if (_lga == null || _farmSize == null) return;
    final plantings = _cropOrder
        .where((c) => _plantings[c] != null)
        .map((c) => PlantingSelection(crop: c, plantingDate: _plantings[c]!))
        .toList();
    if (plantings.isEmpty) return;

    await ref.read(onboardingProvider.notifier).complete(
      plantings: plantings,
      lga: _lga!.name,
      lgaDisplayName: _lga!.name,
      lat: _lga!.lat,
      lon: _lga!.lon,
      farmSize: _farmSize!,
    );
    if (!mounted) return;
    final state = ref.read(onboardingProvider);
    if (state.isComplete) {
      // Refresh farm cache so the home screen reads the new data immediately
      ref.invalidate(farmCacheProvider);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Could not save farm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(steps: 4, current: _currentStep),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _StepCrops(
                    crops: _crops,
                    selected: _plantings,
                    onToggle: (id) {
                      setState(() {
                        if (_plantings.containsKey(id)) {
                          _plantings.remove(id);
                          _cropOrder.remove(id);
                        } else {
                          _plantings[id] = '';
                          _cropOrder.add(id);
                        }
                      });
                    },
                  ),
                  _StepLocation(
                    query: _lgaQuery,
                    selected: _lga,
                    suggestions: _lgaSuggestions,
                    searching: _searchingLga,
                    onSearch: _searchLga,
                    onPick: (s) => setState(() => _lga = s),
                  ),
                  _StepSize(
                    selected: _farmSize,
                    onPick: (s) => setState(() => _farmSize = s),
                  ),
                  _StepPlantingDates(
                    crops: _crops,
                    order: _cropOrder,
                    plantings: _plantings,
                    onChange: (crop, date) {
                      setState(() {
                        _plantings[crop] = date;
                      });
                    },
                  ),
                ],
              ),
            ),
            _BottomBar(
              canContinue: _canContinue,
              isLast: _currentStep == 3,
              onBack: _currentStep > 0
                  ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                  : null,
              onContinue: () {
                if (_currentStep < 3) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finish();
                }
              },
              loadingLabel: t.t('loading'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int steps;
  final int current;
  const _ProgressBar({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(steps, (i) {
          final filled = i <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: filled ? AppColors.green600 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepCrops extends StatelessWidget {
  final List<Map<String, String>> crops;
  final Map<String, String> selected;
  final void Function(String id) onToggle;
  const _StepCrops({required this.crops, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final t = context.read(translationsProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('🌱 ${t.t('select_crops_title')}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.t('select_crops_subtitle'),
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: crops.length,
              itemBuilder: (_, i) {
                final crop = crops[i];
                final id = crop['id']!;
                final isSelected = selected.containsKey(id);
                return GestureDetector(
                  onTap: () => onToggle(id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.green50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.green600 : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(crop['emoji']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(
                          crop['name']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLocation extends StatelessWidget {
  final String query;
  final LgaSuggestion? selected;
  final List<LgaSuggestion> suggestions;
  final bool searching;
  final void Function(String) onSearch;
  final void Function(LgaSuggestion) onPick;
  const _StepLocation({
    required this.query,
    required this.selected,
    required this.suggestions,
    required this.searching,
    required this.onSearch,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read(translationsProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('📍 ${t.t('select_lga_title')}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.t('select_lga_subtitle'),
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'e.g. Zaria, Ibadan, Bodija...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.green50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (searching) const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          if (!searching && suggestions.isEmpty && query.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No matches. Try a different spelling.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 12),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = suggestions[i];
                final isSelected = selected?.name == s.name;
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(s.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.green700)
                      : null,
                  onTap: () => onPick(s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepSize extends StatelessWidget {
  final String? selected;
  final void Function(String) onPick;
  const _StepSize({required this.selected, required this.onPick});

  static const List<Map<String, String>> _options = [
    {'key': 'small',  'emoji': '🌱'},
    {'key': 'medium', 'emoji': '🌾'},
    {'key': 'large',  'emoji': '🌳'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.read(translationsProvider);
    String label(String key) {
      switch (key) {
        case 'small': return '${t.t('farm_size_small')} · ${t.t('farm_size_small_desc')}';
        case 'medium': return '${t.t('farm_size_medium')} · ${t.t('farm_size_medium_desc')}';
        case 'large': return '${t.t('farm_size_large')} · ${t.t('farm_size_large_desc')}';
      }
      return key;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('🌾 ${t.t('farm_size_title')}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.t('farm_size_subtitle'),
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          ..._options.map((o) {
            final isSelected = selected == o['key'];
            return GestureDetector(
              onTap: () => onPick(o['key']!),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.green600 : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(o['emoji']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(label(o['key']!),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.green700),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepPlantingDates extends StatelessWidget {
  final List<Map<String, String>> crops;
  final List<String> order;
  final Map<String, String> plantings;
  final void Function(String crop, String date) onChange;
  const _StepPlantingDates({
    required this.crops,
    required this.order,
    required this.plantings,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read(translationsProvider);
    final today = DateTime.now();
    final selected = order
        .map((id) => crops.firstWhere((c) => c['id'] == id, orElse: () => const {}))
        .where((c) => c.isNotEmpty)
        .toList();

    Future<void> pickDate(String cropId, String cropName) async {
      final initial = plantings[cropId]?.isNotEmpty == true
          ? DateTime.parse(plantings[cropId]!)
          : today.subtract(const Duration(days: 30));
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(today.year - 2),
        lastDate: today,
      );
      if (picked != null) {
        final iso = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        onChange(cropId, iso);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('📅 ${t.t('planting_date_title', {'crop': ''}).trim()}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t.t('planting_date_subtitle'),
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: selected.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = selected[i];
                final id = c['id']!;
                final date = plantings[id] ?? '';
                return InkWell(
                  onTap: () => pickDate(id, c['name']!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: date.isNotEmpty ? AppColors.green50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: date.isNotEmpty ? AppColors.green600 : const Color(0xFFE5E7EB),
                        width: date.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c['emoji']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['name']!,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(
                                date.isEmpty ? 'Tap to pick a date' : date,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: date.isEmpty ? const Color(0xFF6B7280) : AppColors.green800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: AppColors.green700),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool canContinue;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onContinue;
  final String loadingLabel;
  const _BottomBar({
    required this.canContinue,
    required this.isLast,
    required this.onBack,
    required this.onContinue,
    required this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.read(translationsProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(t.t('cancel')),
              ),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green700,
                disabledBackgroundColor: AppColors.green200,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              child: Text(isLast ? '🌱 ${t.t('get_started')}' : t.t('next')),
            ),
          ),
        ],
      ),
    );
  }
}
