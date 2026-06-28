import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/l10n/locale_provider.dart';
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
    {'name': 'Maize', 'emoji': '\u{1F33D}'},
    {'name': 'Rice', 'emoji': '\u{1F33E}'},
    {'name': 'Cassava', 'emoji': '\u{1F331}'},
    {'name': 'Yam', 'emoji': '\u{1F360}'},
    {'name': 'Tomato', 'emoji': '\u{1F345}'},
    {'name': 'Pepper', 'emoji': '\u{1F336}'},
    {'name': 'Groundnut', 'emoji': '\u{1F95C}'},
    {'name': 'Sorghum', 'emoji': '\u{1F33F}'},
    {'name': 'Soybean', 'emoji': '\u{1FAD8}'},
  ];

  static const List<Map<String, String>> _sizes = [
    {'key': 'small', 'label': 'Small (<1ha)', 'emoji': '\u{1F331}', 'desc': 'Backyard or family garden'},
    {'key': 'medium', 'label': 'Medium (1-5ha)', 'emoji': '\u{1F33F}', 'desc': 'Smallholder farm'},
    {'key': 'large', 'label': 'Large (>5ha)', 'emoji': '\u{1F333}', 'desc': 'Commercial operation'},
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
      setState(() => _currentStep++);
    } else {
      await ref.read(onboardingProvider.notifier).complete(
        crops: _selectedCrops,
        lga: _lga,
        farmSize: _farmSize!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final state = ref.watch(onboardingProvider);

    ref.listen<OnboardingState>(onboardingProvider, (_, next) {
      if (next.isComplete) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });

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
            if (state.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.red500),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.red500, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.red500),
                      ),
                    ),
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
                        onPressed: state.isLoading
                            ? null
                            : () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        child: Text(t.t('cancel')),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: state.isLoading
                        ? Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.green600,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          )
                        : PrimaryButton(
                            label: _currentStep < 2
                                ? t.t('next')
                                : '\u{1F331} ${t.t('get_started')}',
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
    final container = ProviderScope.containerOf(context);
    final t = container.read(translationsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F33E} ${t.t('step_1_title')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            t.t('step_1_sub'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey600),
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
                    final parentState =
                        context.findAncestorStateOfType<_OnboardingScreenState>();
                    if (parentState != null) {
                      parentState._selectedCrops.clear();
                      parentState._selectedCrops.addAll(_selected);
                      parentState.setState(() {});
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.green50 : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.green600
                            : AppColors.grey300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(crop['emoji']!,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 6),
                        Text(
                          crop['name']!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.green800
                                    : AppColors.grey700,
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
    final container = ProviderScope.containerOf(context);
    final t = container.read(translationsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F4CD} ${t.t('step_2_title')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            t.t('step_2_sub'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'e.g. Zaria, Kaduna North, Ibadan...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) {
              final state =
                  context.findAncestorStateOfType<_OnboardingScreenState>();
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
            children: [
              'Zaria',
              'Kano',
              'Ibadan',
              'Abuja',
              'Kaduna',
              'Lagos',
              'Jos',
              'Enugu',
            ]
                .map((loc) => ActionChip(
                      label: Text(loc),
                      onPressed: () {
                        final state = context
                            .findAncestorStateOfType<_OnboardingScreenState>();
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
    final container = ProviderScope.containerOf(context);
    final t = container.read(translationsProvider);
    final selected =
        context.findAncestorStateOfType<_OnboardingScreenState>()?._farmSize;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '\u{1F4CF} ${t.t('step_3_title')}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            t.t('step_3_sub'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 20),
          ..._OnboardingScreenState._sizes.map((size) {
            final isSelected = selected == size['key'];
            return GestureDetector(
              onTap: () {
                final state =
                    context.findAncestorStateOfType<_OnboardingScreenState>();
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
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
                      const Icon(Icons.check_circle,
                          color: AppColors.green600, size: 24),
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
