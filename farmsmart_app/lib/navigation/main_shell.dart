import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/locale_provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final t = ref.watch(translationsProvider);

    final labels = [t.t('my_farm'), t.t('calendar'), t.t('market'), t.t('settings')];
    const icons = ['\u{1F3E0}', '\u{1F4C5}', '\u{1F4B0}', '\u{2699}\u{FE0F}'];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [
          HomeScreen(),
          CalendarScreen(),
          MarketScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (i) {
                final selected = currentTab == i;
                return GestureDetector(
                  onTap: () => ref.read(currentTabProvider.notifier).state = i,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icons[i], style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
                        ),
                      ),
                      if (selected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          height: 4,
                          width: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
