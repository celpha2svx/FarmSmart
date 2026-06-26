import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/presentation/screens/home/home_screen.dart';
import 'package:farmsmart_app/presentation/screens/scanner/crop_scanner_screen.dart';
import 'package:farmsmart_app/presentation/screens/calendar/farming_calendar_screen.dart';
import 'package:farmsmart_app/presentation/screens/market/market_prices_screen.dart';
import 'package:farmsmart_app/presentation/screens/settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CropScannerScreen(),
    FarmingCalendarScreen(),
    MarketPricesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up, color: AppColors.primary), label: 'Prices'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.primary), label: 'Settings'),
        ],
      ),
    );
  }
}
