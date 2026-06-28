import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../features/home/screens/home_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/market/screens/market_screen.dart';
import '../features/settings/screens/settings_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = <Widget>[
    HomeScreen(),
    CalendarScreen(),
    MarketScreen(),
    SettingsScreen(),
  ];

  static const _labels = ['Home', 'Calendar', 'Market', 'Settings'];
  static const _icons = ['🏠', '📅', '📊', '⚙️'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
              children: List.generate(_labels.length, (i) {
                final selected = currentTab == i;
                return GestureDetector(
                  onTap: () => ref.read(currentTabProvider.notifier).state = i,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_icons[i], style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: GoogleFonts.inter(
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
