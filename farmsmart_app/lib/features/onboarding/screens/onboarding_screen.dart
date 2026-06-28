import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<String> _selectedCrops = [];
  String _lga = '';
  String? _farmSize;

  static const List<Map<String, String>> _crops = [
    {'name': 'Maize', 'emoji': '🌽'},
    {'name': 'Rice', 'emoji': '🌾'},
    {'name': 'Cassava', 'emoji': '🌱'},
    {'name': 'Yam', 'emoji': '🍠'},
    {'name': 'Tomato', 'emoji': '🍅'},
    {'name': 'Pepper', 'emoji': '🌶'},
    {'name': 'Groundnut', 'emoji': '🥜'},
    {'name': 'Sorghum', 'emoji': '🌿'},
    {'name': 'Soybean', 'emoji': '🫘'},
  ];

  static const List<Map<String, String>> _sizes = [
    {'key': 'small', 'label': 'Small (<1ha)', 'emoji': '🌱', 'desc': 'Backyard or family garden'},
    {'key': 'medium', 'label': 'Medium (1-5ha)', 'emoji': '🌿', 'desc': 'Smallholder farm'},
    {'key': 'large', 'label': 'Large (>5ha)', 'emoji': '🌳', 'desc': 'Commercial operation'},
  ];

  bool get _canContinue {
    switch (_currentStep) {
      case 0: return _selectedCrops.isNotEmpty;
      case 1: return _lga.trim().isNotEmpty;
      case 2: return _farmSize != null;
      default: return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await ref.read(onboardingProvider.notifier).complete(
        crops: _selectedCrops,
        lga: _lga,
        farmSize: _farmSize!,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: List.generate(3, (i) {
                  final isFilled = i <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isFilled ? AppColors.green600 : AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: const [
                  _StepCrops(),
                  _StepLocation(),
                  _StepSize(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: PrimaryButton(
                      label: _currentStep < 2 ? 'Continue \u2192' : '\u{1F331} Start Farming',
                      onTap: _canContinue ? _onContinue : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCrops extends StatefulWidget {
  const _StepCrops();

  @override
  State<_StepCrops> createState() => _StepCropsState();
}

class _StepCropsState extends State<_StepCrops> {
  final List<String> _selected = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F33E} What crops do you grow?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Select all the crops on your farm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _OnboardingScreenState._crops.length,
              itemBuilder: (context, index) {
                final crop = _OnboardingScreenState._crops[index];
                final isSelected = _selected.contains(crop['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(crop['name']);
                      } else {
                        _selected.add(crop['name']!);
                      }
                    });
                    context.findAncestorStateOfType<_OnboardingScreenState>()?.setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.green50 : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isSelected ? AppColors.green600 : AppColors.grey300,
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.green800 : AppColors.grey700,
                          ),
                          textAlign: TextAlign.center,
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

  List<String> get selected => _selected;
}

class _StepLocation extends StatelessWidget {
  const _StepLocation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F4CD} Where is your farm located?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your Local Government Area (LGA)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'e.g. Zaria, Kaduna North, Ibadan...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) {
              final state = context.findAncestorStateOfType<_OnboardingScreenState>();
              if (state != null) {
                state._lga = v;
                state.setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Zaria', 'Kano', 'Ibadan', 'Abuja', 'Kaduna', 'Lagos']
                .map((loc) => ActionChip(
                      label: Text(loc),
                      onPressed: () {
                        final state = context.findAncestorStateOfType<_OnboardingScreenState>();
                        if (state != null) {
                          state._lga = loc;
                          state.setState(() {});
                        }
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StepSize extends StatelessWidget {
  const _StepSize();

  @override
  Widget build(BuildContext context) {
    final selected = context.findAncestorStateOfType<_OnboardingScreenState>()?._farmSize;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F4CF} What is your farm size?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Select the closest option',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 20),
          ..._OnboardingScreenState._sizes.map((size) {
            final isSelected = selected == size['key'];
            return GestureDetector(
              onTap: () {
                final state = context.findAncestorStateOfType<_OnboardingScreenState>();
                if (state != null) {
                  state._farmSize = size['key'];
                  state.setState(() {});
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green50 : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isSelected ? AppColors.green600 : AppColors.grey300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(size['emoji']!, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            size['label']!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            size['desc']!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.green600, size: 24),
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
