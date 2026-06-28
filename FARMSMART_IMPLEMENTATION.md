# FARMSMART IMPLEMENTATION GUIDE
## From UI Design → Working Flutter App

**Version:** 2.0  
**Stack:** Flutter + FastAPI + SQLite (Drift) + Riverpod  
**Target:** Nigerian smallholder farmers · Android-first · Offline-capable  
**Design:** Green + Earth palette · 4-tab bottom nav · Plus Jakarta Sans + DM Sans

---

## TABLE OF CONTENTS

1. [Design Tokens (Colors, Typography, Spacing)](#1-design-tokens)
2. [Project Structure](#2-project-structure)
3. [Shared Widgets](#3-shared-widgets)
4. [Navigation Setup](#4-navigation-setup)
5. [Screen 1 — Splash](#5-splash-screen)
6. [Screen 2 — Sign Up](#6-sign-up-screen)
7. [Screen 3 — OTP Verification](#7-otp-screen)
8. [Screen 4 — Onboarding (3 steps)](#8-onboarding)
9. [Screen 5 — Home Dashboard](#9-home-dashboard)
10. [Screen 6 — Farming Calendar](#10-farming-calendar)
11. [Screen 7 — Market Prices](#11-market-prices)
12. [Screen 8 — Crop Scanner](#12-crop-scanner)
13. [Screen 9 — Settings](#13-settings)
14. [State Management (Riverpod Providers)](#14-providers)
15. [API Client](#15-api-client)
16. [Offline Sync Service](#16-offline-sync)
17. [pubspec.yaml](#17-pubspec)

---

## 1. DESIGN TOKENS

Create this file first. Every color, font, radius, and spacing in the app comes from here.

### `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── COLORS ──────────────────────────────────────────────────────────────────

class AppColors {
  // Green scale
  static const green900 = Color(0xFF0D2B1A);
  static const green800 = Color(0xFF1A4A2E);
  static const green700 = Color(0xFF256B3F);
  static const green600 = Color(0xFF2E8B57);
  static const green500 = Color(0xFF3AAD6A);
  static const green400 = Color(0xFF5CC685);
  static const green100 = Color(0xFFD6F5E3);
  static const green50  = Color(0xFFF0FAF4);

  // Earth scale
  static const earth900 = Color(0xFF2C1A0E);
  static const earth700 = Color(0xFF7A4A28);
  static const earth500 = Color(0xFFC4813A);
  static const earth300 = Color(0xFFE8C49A);
  static const earth100 = Color(0xFFFBF0E3);

  // Semantic
  static const amber500 = Color(0xFFF5A623);
  static const amber100 = Color(0xFFFEF3D7);
  static const red500   = Color(0xFFE53E3E);
  static const red100   = Color(0xFFFEE2E2);

  // Neutral
  static const ink       = Color(0xFF111827);
  static const inkSoft   = Color(0xFF374151);
  static const inkMuted  = Color(0xFF6B7280);
  static const inkFaint  = Color(0xFF9CA3AF);
  static const surface   = Color(0xFFFFFFFF);
  static const bg        = Color(0xFFF5F7F2);
  static const border    = Color(0xFFE5EAE0);
}

// ── RADIUS ───────────────────────────────────────────────────────────────────

class AppRadius {
  static const sm = BorderRadius.all(Radius.circular(10));
  static const md = BorderRadius.all(Radius.circular(16));
  static const lg = BorderRadius.all(Radius.circular(24));
  static const xl = BorderRadius.all(Radius.circular(32));
  static const pill = BorderRadius.all(Radius.circular(100));
}

// ── SHADOWS ──────────────────────────────────────────────────────────────────

class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x12000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4,  offset: Offset(0, 2)),
  ];
}

// ── SPACING ──────────────────────────────────────────────────────────────────

class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

// ── THEME ────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green600,
        secondary: AppColors.earth500,
        error: AppColors.red500,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted,
          letterSpacing: 0.08),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inkSoft),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.inkSoft),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.inkMuted),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.green500, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.inkFaint, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      dividerColor: AppColors.border,
    );
  }
}
```

---

## 2. PROJECT STRUCTURE

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          ← Design tokens (above)
│   ├── network/
│   │   └── api_client.dart         ← Single HTTP client
│   ├── providers/
│   │   └── core_providers.dart     ← Shared provider instances
│   ├── sync/
│   │   └── sync_service.dart       ← Offline queue
│   └── widgets/
│       ├── app_card.dart
│       ├── shimmer_loader.dart
│       ├── error_state.dart
│       ├── empty_state.dart
│       ├── offline_banner.dart
│       ├── app_chip.dart
│       └── primary_button.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── otp_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── onboarding/
│   │   ├── screens/
│   │   │   └── onboarding_screen.dart
│   │   └── providers/
│   │       └── onboarding_provider.dart
│   │
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── providers/
│   │       ├── advisory_provider.dart
│   │       └── announcements_provider.dart
│   │
│   ├── calendar/
│   │   ├── screens/
│   │   │   └── calendar_screen.dart
│   │   └── providers/
│   │       └── tasks_provider.dart
│   │
│   ├── market/
│   │   ├── screens/
│   │   │   └── market_screen.dart
│   │   └── providers/
│   │       └── market_provider.dart
│   │
│   ├── scanner/
│   │   ├── screens/
│   │   │   ├── scanner_screen.dart
│   │   │   └── scan_result_screen.dart
│   │   └── providers/
│   │       └── scanner_provider.dart
│   │
│   └── settings/
│       ├── screens/
│       │   └── settings_screen.dart
│       └── providers/
│           └── settings_provider.dart
│
├── navigation/
│   └── main_shell.dart             ← Bottom nav shell
│
└── main.dart
```

---

## 3. SHARED WIDGETS

These are the building blocks used across every screen.

### `lib/core/widgets/offline_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/core_providers.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider);
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.amber100,
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No internet — showing last saved data',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/core/widgets/shimmer_loader.dart`

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppRadius.sm,
        ),
      ),
    );
  }
}

// Advisory card shimmer
class AdvisoryCardShimmer extends StatelessWidget {
  const AdvisoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 40, height: 40,
                borderRadius: BorderRadius.all(Radius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(height: 10, width: 100),
                    const SizedBox(height: 8),
                    ShimmerBox(height: 14,
                      width: MediaQuery.of(context).size.width * 0.6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerBox(height: 12),
          const SizedBox(height: 6),
          const ShimmerBox(height: 12, width: 250),
          const SizedBox(height: 6),
          const ShimmerBox(height: 12, width: 200),
        ],
      ),
    );
  }
}
```

### `lib/core/widgets/error_state.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: AppRadius.md,
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Text('❌', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.red500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.red500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `lib/core/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green600,
                side: const BorderSide(color: AppColors.green600),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
```

### `lib/core/widgets/app_chip.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum ChipVariant { green, amber, red, earth }

class AppChip extends StatelessWidget {
  final String label;
  final ChipVariant variant;

  const AppChip({
    super.key,
    required this.label,
    this.variant = ChipVariant.green,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (variant) {
      ChipVariant.green => (bg: AppColors.green100, fg: AppColors.green700),
      ChipVariant.amber => (bg: AppColors.amber100, fg: const Color(0xFF92400E)),
      ChipVariant.red   => (bg: AppColors.red100,   fg: AppColors.red500),
      ChipVariant.earth => (bg: AppColors.earth100,  fg: AppColors.earth700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w700, color: colors.fg),
      ),
    );
  }
}
```

### `lib/core/widgets/primary_button.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white12),
        ),
        child: isLoading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Text(icon!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                Text(label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
      ),
    );
  }
}
```

---

## 4. NAVIGATION SETUP

### `lib/navigation/main_shell.dart`

```dart
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

  static const _tabs = [
    HomeScreen(),
    CalendarScreen(),
    MarketScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (icon: '🏠', label: 'Home'),
    (icon: '📅', label: 'Calendar'),
    (icon: '💰', label: 'Market'),
    (icon: '⚙️', label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = i == currentTab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(currentTabProvider.notifier).state = i,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.icon,
                          style: TextStyle(
                            fontSize: 22,
                            color: isActive ? AppColors.green600 : null,
                          )),
                        const SizedBox(height: 3),
                        Text(item.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                            color: isActive
                              ? AppColors.green600
                              : AppColors.inkMuted,
                          )),
                        if (isActive) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4, height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.green500,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
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
```

---

## 5. SPLASH SCREEN

### `lib/features/auth/screens/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final isLoggedIn = await ref.read(authProvider.notifier).checkSession();
    if (!mounted) return;
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    // If not logged in, splash stays and shows buttons
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green900, AppColors.green800, AppColors.green700],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // App icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: const BorderRadius.all(Radius.circular(28)),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Center(
                        child: Text('🌱', style: TextStyle(fontSize: 36))),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Farm smarter,\nharvest more.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Weather, market prices, and pest advice —\nall for Nigerian farmers.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.65),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 2),
                    // CTA buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                          Navigator.pushNamed(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.green800,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.sm),
                          elevation: 0,
                        ),
                        child: Text('Get Started',
                          style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.green800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () =>
                        Navigator.pushNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.white.withOpacity(0.55)),
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 6. SIGN UP SCREEN

### `lib/features/auth/screens/signup_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+234${_phoneCtrl.text.trim()}';
    final name  = _nameCtrl.text.trim();
    await ref.read(authProvider.notifier).sendOtp(phone: phone, name: name);
    if (mounted) Navigator.pushNamed(context, '/otp', arguments: phone);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green900, AppColors.green800, AppColors.green700],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text('WELCOME',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 0.12,
                    )),
                  const SizedBox(height: 6),
                  Text('Create your account',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Enter your phone number to begin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: AppSpacing.xl),

                  // Phone field
                  Text('PHONE NUMBER',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: AppRadius.sm,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text('🇳🇬 +234',
                          style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '801 234 5678',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2))),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.sm,
                              borderSide: const BorderSide(
                                color: AppColors.green400, width: 1.5)),
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4)),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Name field
                  Text('FULL NAME',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ibrahim Musa',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2))),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: const BorderSide(
                          color: AppColors.green400, width: 1.5)),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.green800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.sm),
                      ),
                      child: auth.isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green800))
                        : Text('Send Verification Code →',
                            style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.green800)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'By continuing you agree to our Terms of Service and Privacy Policy',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.35)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55)),
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 7. OTP SCREEN

### `lib/features/auth/screens/otp_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
        if (_countdown <= 0) _canResend = true;
      });
      return _countdown > 0;
    });
  }

  Future<void> _verify(String pin) async {
    final success = await ref.read(authProvider.notifier)
      .verifyOtp(phone: widget.phone, otp: pin);
    if (!mounted) return;
    if (success) {
      final hasCompletedOnboarding = await ref.read(authProvider.notifier)
        .hasCompletedOnboarding();
      Navigator.pushReplacementNamed(
        context,
        hasCompletedOnboarding ? '/home' : '/onboarding',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong code. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    final defaultPinTheme = PinTheme(
      width: 44, height: 52,
      textStyle: Theme.of(context).textTheme.displayMedium
        ?.copyWith(color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppRadius.sm,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green900, AppColors.green800, AppColors.green700],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Text('📱', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Enter the code',
                  style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: 'We sent a 6-digit code to\n',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 13),
                    children: [
                      TextSpan(
                        text: widget.phone,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Center(
                  child: Pinput(
                    length: 6,
                    onCompleted: _verify,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(
                        color: AppColors.green400, width: 1.5),
                      color: Colors.white.withOpacity(0.18),
                    ),
                    submittedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(
                        color: AppColors.green400),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (auth.isLoading)
                  const Center(child: CircularProgressIndicator(
                    color: Colors.white)),

                const Spacer(),
                Center(
                  child: _canResend
                    ? GestureDetector(
                        onTap: () {
                          setState(() { _countdown = 60; _canResend = false; });
                          _startCountdown();
                          ref.read(authProvider.notifier)
                            .sendOtp(phone: widget.phone, name: '');
                        },
                        child: Text('Resend code',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                      )
                    : RichText(
                        text: TextSpan(
                          text: "Didn't get it? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Resend in ${_countdown}s',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 8. ONBOARDING

### `lib/features/onboarding/screens/onboarding_screen.dart`

```dart
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
  final _pageCtrl = PageController();
  int _step = 0;

  // Step 1 state
  final Set<String> _selectedCrops = {};

  // Step 2 state
  String? _selectedLga;

  // Step 3 state
  String? _farmSize;
  final _customSizeCtrl = TextEditingController();

  static const _crops = [
    (emoji: '🌽', name: 'Maize'),
    (emoji: '🍚', name: 'Rice'),
    (emoji: '🍅', name: 'Tomato'),
    (emoji: '🫛', name: 'Cassava'),
    (emoji: '🥜', name: 'Groundnut'),
    (emoji: '🧅', name: 'Onion'),
    (emoji: '🌾', name: 'Millet'),
    (emoji: '🍠', name: 'Yam'),
    (emoji: '🫘', name: 'Beans'),
  ];

  static const _sizes = [
    (label: 'Small', sub: 'Less than 1 hectare', value: 'small'),
    (label: 'Medium', sub: '1 – 5 hectares',     value: 'medium'),
    (label: 'Large',  sub: 'More than 5 hectares', value: 'large'),
  ];

  void _next() {
    if (_step < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut);
    setState(() => _step--);
  }

  Future<void> _submit() async {
    final state = ref.read(onboardingProvider);
    if (state.isLoading) return;

    await ref.read(onboardingProvider.notifier).complete(
      crops: _selectedCrops.toList(),
      lga: _selectedLga ?? '',
      farmSize: _farmSize ?? 'small',
    );

    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step
                        ? AppColors.green500
                        : AppColors.border,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepCrops(
                    selected: _selectedCrops,
                    crops: _crops,
                    onToggle: (name) => setState(() {
                      if (_selectedCrops.contains(name)) {
                        _selectedCrops.remove(name);
                      } else {
                        _selectedCrops.add(name);
                      }
                    }),
                  ),
                  _StepLocation(
                    selected: _selectedLga,
                    onSelect: (lga) => setState(() => _selectedLga = lga),
                  ),
                  _StepSize(
                    selected: _farmSize,
                    sizes: _sizes,
                    ctrl: _customSizeCtrl,
                    onSelect: (v) => setState(() => _farmSize = v),
                  ),
                ],
              ),
            ),

            // Nav buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green600,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.sm),
                        ),
                        child: const Text('← Back'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 4,
                    child: PrimaryButton(
                      label: _step == 2 ? '🌱 Start Farming' : 'Continue →',
                      isLoading: state.isLoading,
                      onTap: _next,
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

  @override
  void dispose() {
    _pageCtrl.dispose();
    _customSizeCtrl.dispose();
    super.dispose();
  }
}
```

---

## 9. HOME DASHBOARD

### `lib/features/home/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/app_chip.dart';
import '../providers/advisory_provider.dart';
import '../providers/announcements_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisory      = ref.watch(advisoryProvider);
    final announcements = ref.watch(announcementsProvider);
    final user          = ref.watch(authProvider).user;

    // Greeting based on time of day
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning ☀️'
      : hour < 17 ? 'Good afternoon 🌤'
      : 'Good evening 🌙';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Status bar + offline
          const OfflineBanner(),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.green600,
              onRefresh: () async {
                ref.invalidate(advisoryProvider);
                ref.invalidate(announcementsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── HEADER ──
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      greeting: greeting,
                      name: user?.name ?? '',
                      advisory: advisory,
                    ),
                  ),

                  // ── ADVISORY CARD ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: advisory.when(
                        loading: () => const AdvisoryCardShimmer(),
                        error: (e, _) => ErrorCard(
                          message: 'Could not load advisory',
                          onRetry: () => ref.invalidate(advisoryProvider),
                        ),
                        data: (data) => _AdvisoryCard(advisory: data),
                      ),
                    ),
                  ),

                  // ── QUICK ACTIONS ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: _QuickActionsGrid(),
                    ),
                  ),

                  // ── ANNOUNCEMENTS ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.md, 0),
                    sliver: SliverToBoxAdapter(
                      child: announcements.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : _RecentAlerts(alerts: list),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final AsyncValue advisory;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.advisory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green800, AppColors.green700],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md + 8,
        AppSpacing.md, AppSpacing.lg),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text(name,
                      style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    const Center(child: Text('🔔',
                      style: TextStyle(fontSize: 16))),
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.amber500,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green700, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              _StatBubble(value: '32°C',  label: 'Temp'),
              const SizedBox(width: 8),
              _StatBubble(value: '65%',   label: 'Humidity'),
              const SizedBox(width: 8),
              _StatBubble(value: '0 mm',  label: 'Rain'),
              const SizedBox(width: 8),
              _StatBubble(value: 'Wk 4',  label: 'Growth'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String value;
  final String label;
  const _StatBubble({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: AppRadius.sm,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value,
              style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
              style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final AdvisoryData advisory;
  const _AdvisoryCard({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          // Top section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: AppColors.green100)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Text('🌾', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TODAY'S ADVISORY",
                        style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(
                            color: AppColors.green600,
                            letterSpacing: 0.08)),
                      const SizedBox(height: 3),
                      Text(advisory.title,
                        style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advisory.message,
                  style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.6)),
                const SizedBox(height: AppSpacing.md),
                ...advisory.actions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.green500,
                          shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(action,
                          style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500))),
                    ],
                  ),
                )),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                AppChip(
                  label: '🟢 ${advisory.riskLevel} risk',
                  variant: ChipVariant.green,
                ),
                const Spacer(),
                Text('Full advisory →',
                  style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: AppColors.green600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 10. FARMING CALENDAR

### `lib/features/calendar/screens/calendar_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../providers/tasks_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider(_selectedDay));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.md + 8,
                            AppSpacing.md, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Farming Calendar',
                                style: Theme.of(context)
                                  .textTheme.headlineLarge),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  // These come from farmProvider
                                  AppChip(label: '🌽 Maize',
                                    variant: ChipVariant.green),
                                  SizedBox(width: 8),
                                  AppChip(label: 'Week 4 of 16',
                                    variant: ChipVariant.earth),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2027, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                          onDaySelected: (selected, focused) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: const BoxDecoration(
                              color: AppColors.green600,
                              shape: BoxShape.circle),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.green500,
                              shape: BoxShape.circle),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.green500,
                              shape: BoxShape.circle),
                            defaultTextStyle: Theme.of(context)
                              .textTheme.bodySmall!
                              .copyWith(fontWeight: FontWeight.w600),
                            weekendTextStyle: Theme.of(context)
                              .textTheme.bodySmall!
                              .copyWith(color: AppColors.inkMuted),
                          ),
                          headerStyle: HeaderStyle(
                            titleTextStyle: Theme.of(context)
                              .textTheme.headlineMedium!,
                            formatButtonVisible: false,
                            leftChevronIcon: const Icon(
                              Icons.chevron_left, color: AppColors.inkSoft),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right, color: AppColors.inkSoft),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ),

                // Tasks for selected day
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: tasksAsync.when(
                    loading: () => SliverList(
                      delegate: SliverChildListDelegate([
                        const ShimmerBox(height: 72,
                          borderRadius: AppRadius.md),
                        const SizedBox(height: 10),
                        const ShimmerBox(height: 72,
                          borderRadius: AppRadius.md),
                      ]),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: ErrorCard(
                        message: 'Could not load tasks',
                        onRetry: () =>
                          ref.invalidate(tasksProvider(_selectedDay)),
                      ),
                    ),
                    data: (tasks) => tasks.isEmpty
                      ? SliverToBoxAdapter(
                          child: EmptyState(
                            icon: '📅',
                            title: 'No tasks for this day',
                            subtitle: 'Add your own or check nearby dates.',
                            actionLabel: 'Add task',
                            onAction: () => _showAddTask(context),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                              child: _TaskItem(task: tasks[i]),
                            ),
                            childCount: tasks.length,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTask(context),
        backgroundColor: AppColors.green600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add task',
          style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Colors.white)),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    // Bottom sheet for adding a custom task
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

class _TaskItem extends ConsumerWidget {
  final FarmTask task;
  const _TaskItem({required this.task});

  Color get _typeColor => switch (task.type) {
    'fertilizer' => AppColors.earth100,
    'pest'       => AppColors.red100,
    'water'      => const Color(0xFFEFF6FF),
    _            => AppColors.green100,
  };

  Color get _typeFg => switch (task.type) {
    'fertilizer' => AppColors.earth700,
    'pest'       => AppColors.red500,
    'water'      => const Color(0xFF1D4ED8),
    _            => AppColors.green700,
  };

  String get _typeLabel => switch (task.type) {
    'fertilizer' => 'Fertilizer',
    'pest'       => 'Pest',
    'water'      => 'Water',
    _            => 'Task',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(tasksProvider(task.date).notifier)
              .toggleComplete(task.id),
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: task.completed ? AppColors.green500 : Colors.transparent,
                border: Border.all(
                  color: task.completed
                    ? AppColors.green500
                    : AppColors.border,
                  width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(7)),
              ),
              child: task.completed
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: task.completed
                      ? TextDecoration.lineThrough : null,
                    color: task.completed
                      ? AppColors.inkMuted : AppColors.ink,
                  )),
                if (task.note != null) ...[
                  const SizedBox(height: 2),
                  Text(task.note!,
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor,
              borderRadius: AppRadius.sm,
            ),
            child: Text(_typeLabel,
              style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: _typeFg, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
```

---

## 11. MARKET PRICES

### `lib/features/market/screens/market_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/error_state.dart';
import '../providers/market_provider.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _selectedCrop = 'Maize';

  static const _crops = [
    (emoji: '🌽', name: 'Maize'),
    (emoji: '🍚', name: 'Rice'),
    (emoji: '🫘', name: 'Beans'),
    (emoji: '🌾', name: 'Millet'),
    (emoji: '🥜', name: 'Groundnut'),
  ];

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(marketPricesProvider(_selectedCrop));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const OfflineBanner(),

          // Header with crop selector
          Container(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md + 8,
                    AppSpacing.md, AppSpacing.sm),
                  child: Text('Market Prices',
                    style: Theme.of(context).textTheme.headlineLarge),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                    itemCount: _crops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final crop = _crops[i];
                      final isActive = crop.name == _selectedCrop;
                      return GestureDetector(
                        onTap: () =>
                          setState(() => _selectedCrop = crop.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                              ? AppColors.green600
                              : AppColors.bg,
                            borderRadius: AppRadius.pill,
                            border: Border.all(
                              color: isActive
                                ? AppColors.green600
                                : AppColors.border),
                          ),
                          child: Text(
                            '${crop.emoji} ${crop.name}',
                            style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: isActive
                                  ? Colors.white
                                  : AppColors.inkMuted,
                                fontWeight: FontWeight.w700,
                              ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
              ],
            ),
          ),

          Expanded(
            child: pricesAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const ShimmerBox(height: 140, borderRadius: AppRadius.md),
                    const SizedBox(height: AppSpacing.md),
                    const ShimmerBox(height: 72, borderRadius: AppRadius.md),
                    const SizedBox(height: 8),
                    const ShimmerBox(height: 72, borderRadius: AppRadius.md),
                  ],
                ),
              ),
              error: (e, _) => ErrorCard(
                message: 'Market prices unavailable',
                onRetry: () =>
                  ref.invalidate(marketPricesProvider(_selectedCrop)),
              ),
              data: (data) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Price hero + chart
                    _PriceHeroCard(data: data),
                    const SizedBox(height: AppSpacing.md),

                    // Compare markets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Compare Markets',
                          style: Theme.of(context)
                            .textTheme.headlineMedium),
                        Text('See all',
                          style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(color: AppColors.green600)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...data.markets.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MarketRow(market: m),
                    )),

                    Text(
                      'Source: AFEX · commodity.ng · Updated ${data.updatedAgo}',
                      style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.inkFaint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHeroCard extends StatelessWidget {
  final MarketData data;
  const _PriceHeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isUp = data.changePercent >= 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data.crop} · 50kg bag',
            style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('₦${data.currentPrice.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displayLarge
              ?.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Nearest market · ',
                style: Theme.of(context).textTheme.bodySmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp ? AppColors.green100 : AppColors.red100,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${isUp ? "▲" : "▼"} ${data.changePercent.abs().toStringAsFixed(1)}% this week',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isUp ? AppColors.green700 : AppColors.red500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bar chart using fl_chart
          SizedBox(
            height: 60,
            child: BarChart(
              BarChartData(
                barGroups: data.weeklyPrices.asMap().entries.map((e) =>
                  BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value / 1000,
                        color: e.key == 6
                          ? AppColors.green500
                          : AppColors.green100,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        ['M','T','W','T','F','S','Today'][v.toInt()],
                        style: const TextStyle(
                          fontSize: 9, color: AppColors.inkFaint)),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final MarketEntry market;
  const _MarketRow({required this.market});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.sm,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.name,
                  style: Theme.of(context).textTheme.titleMedium),
                Text('📍 ${market.distanceKm} km · Updated ${market.updatedAgo}',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('₦${market.pricePerBag.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: AppColors.green700)),
        ],
      ),
    );
  }
}
```

---

## 12. CROP SCANNER

### `lib/features/scanner/screens/scanner_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scanner_provider.dart';
import 'scan_result_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _capture(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 640,
    );
    if (file == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final result = await ref.read(scannerProvider.notifier)
        .analyze(file.path);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imagePath: file.path,
            result: result,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis failed. Check connection and try again.'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: AppRadius.sm,
                      ),
                      child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Crop Scanner',
                    style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(color: Colors.white)),
                ],
              ),
            ),

            // Viewfinder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
                child: ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: Container(
                    color: const Color(0xFF0D1117),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text('🌿',
                          style: TextStyle(
                            fontSize: 80, color: Colors.white12)),

                        // Corner frame
                        SizedBox(
                          width: 200, height: 200,
                          child: CustomPaint(
                            painter: _FramePainter()),
                        ),

                        if (_isAnalyzing)
                          Container(
                            color: Colors.black54,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.green400),
                                const SizedBox(height: AppSpacing.md),
                                Text('Analyzing...',
                                  style: Theme.of(context)
                                    .textTheme.headlineMedium
                                    ?.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),

                        // Hint
                        Positioned(
                          bottom: AppSpacing.md,
                          child: Text(
                            'Point camera at an affected leaf',
                            style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white60)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing
                        ? null
                        : () => _capture(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green500,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                      ),
                      icon: const Text('📸',
                        style: TextStyle(fontSize: 18)),
                      label: Text('Take Photo',
                        style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: Colors.white, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing
                        ? null
                        : () => _capture(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.12)),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                      ),
                      icon: const Text('🖼',
                        style: TextStyle(fontSize: 16)),
                      label: const Text('Choose from Gallery'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⚡ Works offline · On-device AI model',
                    style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white30),
                    textAlign: TextAlign.center,
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

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const corner = 24.0;
    final r = Radius.circular(4);

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(0, corner)..lineTo(0, 0)..arcToPoint(
        const Offset(corner, 0), radius: Radius.zero), paint);
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(size.width - corner, 0)..lineTo(size.width, 0)
      ..lineTo(size.width, corner), paint);
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, size.height - corner)..lineTo(0, size.height)
      ..lineTo(corner, size.height), paint);
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(size.width - corner, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 13. SETTINGS

### `lib/features/settings/screens/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md + 8,
                AppSpacing.md, AppSpacing.md),
              child: Text('Settings',
                style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Profile card
                _ProfileCard(user: user),
                const SizedBox(height: AppSpacing.sm),

                // Language
                _SettingsSection(
                  label: 'Language',
                  children: [
                    _LangOption(lang: 'English',          flag: '🇬🇧', code: 'en', selected: settings.locale == 'en'),
                    _LangOption(lang: 'Hausa',            flag: '🇳🇬', code: 'ha', selected: settings.locale == 'ha'),
                    _LangOption(lang: 'Yoruba',           flag: '🇳🇬', code: 'yo', selected: settings.locale == 'yo'),
                    _LangOption(lang: 'Igbo',             flag: '🇳🇬', code: 'ig', selected: settings.locale == 'ig'),
                    _LangOption(lang: 'Nigerian Pidgin',  flag: '🇳🇬', code: 'pcm', selected: settings.locale == 'pcm'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Notifications
                _SettingsSection(
                  label: 'Notifications',
                  children: [
                    _ToggleRow(
                      icon: '🌾', iconBg: AppColors.green50,
                      label: 'Daily advisory',
                      sub: 'Sent at 6:00 AM every morning',
                      value: settings.dailyAdvisory,
                      onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setDailyAdvisory(v),
                    ),
                    _ToggleRow(
                      icon: '🐛', iconBg: AppColors.earth100,
                      label: 'Pest alerts',
                      sub: 'Outbreak warnings for your area',
                      value: settings.pestAlerts,
                      onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setPestAlerts(v),
                    ),
                    _ToggleRow(
                      icon: '💰', iconBg: AppColors.amber100,
                      label: 'Market price changes',
                      sub: 'When price moves more than 10%',
                      value: settings.marketAlerts,
                      onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setMarketAlerts(v),
                    ),
                    _ToggleRow(
                      icon: '🌧', iconBg: const Color(0xFFEFF6FF),
                      label: 'Weather alerts',
                      sub: 'Rain, drought, and temperature warnings',
                      value: settings.weatherAlerts,
                      onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setWeatherAlerts(v),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Data & Sync
                _SettingsSection(
                  label: 'Data & Sync',
                  children: [
                    _ToggleRow(
                      icon: '☁️', iconBg: AppColors.green50,
                      label: 'Auto-sync',
                      sub: 'Last synced: Today at 6:00 AM',
                      value: settings.autoSync,
                      onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setAutoSync(v),
                    ),
                    _ActionRow(
                      icon: '🔄', iconBg: const Color(0xFFEFF6FF),
                      label: 'Sync now',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(settingsProvider.notifier).syncNow();
                        messenger.showSnackBar(const SnackBar(
                          content: Text('✅ Sync complete')));
                      },
                    ),
                    _ActionRow(
                      icon: '🗑', iconBg: AppColors.earth100,
                      label: 'Clear cache',
                      sub: '${settings.cacheSizeMb.toStringAsFixed(1)} MB',
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Clear cache?'),
                            content: const Text(
                              'This will remove locally saved data. It will be re-downloaded when you connect.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                  Navigator.pop(context, false),
                                child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                  Navigator.pop(context, true),
                                child: const Text('Clear',
                                  style: TextStyle(
                                    color: AppColors.red500))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(settingsProvider.notifier)
                            .clearCache();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // About
                _SettingsSection(
                  label: 'About',
                  children: [
                    _ActionRow(
                      icon: '📲', iconBg: AppColors.green50,
                      label: 'Version 1.0.1',
                      sub: 'Check for updates',
                      onTap: () => ref.read(settingsProvider.notifier)
                        .checkForUpdate(context),
                    ),
                    _ActionRow(
                      icon: '💬', iconBg: const Color(0xFFEFF6FF),
                      label: 'Send feedback',
                      onTap: () {},
                    ),
                    _ActionRow(
                      icon: '📋', iconBg: AppColors.earth100,
                      label: 'Terms & Privacy',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Log out?'),
                          content: const Text(
                            'You will need to sign in again. Your local data will be cleared.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                Navigator.pop(context, false),
                              child: const Text('Cancel')),
                            TextButton(
                              onPressed: () =>
                                Navigator.pop(context, true),
                              child: const Text('Log out',
                                style: TextStyle(
                                  color: AppColors.red500))),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref.read(authProvider.notifier).logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/splash', (_) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red500,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: AppColors.red100,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md),
                    ),
                    icon: const Text('🚪',
                      style: TextStyle(fontSize: 16)),
                    label: Text('Log out',
                      style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                          color: AppColors.red500,
                          fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon, required this.iconBg,
    required this.label, this.sub,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.sm,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: Theme.of(context).textTheme.titleMedium),
                if (sub != null)
                  Text(sub!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.green500,
            trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                ? AppColors.green100
                : AppColors.border),
          ),
        ],
      ),
    );
  }
}
```

---

## 14. PROVIDERS

### `lib/features/home/providers/advisory_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class AdvisoryData {
  final String title;
  final String message;
  final String riskLevel;
  final List<String> actions;

  const AdvisoryData({
    required this.title,
    required this.message,
    required this.riskLevel,
    required this.actions,
  });

  factory AdvisoryData.fromJson(Map<String, dynamic> json) => AdvisoryData(
    title:     json['title'],
    message:   json['message'],
    riskLevel: json['risk_level'],
    actions:   List<String>.from(json['actions']),
  );
}

final advisoryProvider = FutureProvider<AdvisoryData>((ref) async {
  final client = ref.read(apiClientProvider);
  final farm   = ref.read(farmProvider);

  // Try network
  try {
    final data = await client.generateAdvisory(
      crop:     farm.crop,
      lat:      farm.lat,
      lon:      farm.lon,
      farmId:   farm.id,
    );
    // Cache to local DB
    await ref.read(localDbProvider).saveAdvisory(data);
    return data;
  } catch (e) {
    // Fall back to cached
    final cached = await ref.read(localDbProvider).getLastAdvisory();
    if (cached != null) return cached;
    rethrow;
  }
});
```

### `lib/features/calendar/providers/tasks_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class FarmTask {
  final String id;
  final String name;
  final String type;
  final String? note;
  final DateTime date;
  final bool completed;

  const FarmTask({
    required this.id, required this.name,
    required this.type, this.note,
    required this.date, required this.completed,
  });
}

// Family provider keyed on selected date
final tasksProvider = AsyncNotifierProviderFamily<TasksNotifier,
    List<FarmTask>, DateTime>(TasksNotifier.new);

class TasksNotifier extends FamilyAsyncNotifier<List<FarmTask>, DateTime> {
  @override
  Future<List<FarmTask>> build(DateTime arg) async {
    final client = ref.read(apiClientProvider);
    final farm   = ref.read(farmProvider);

    try {
      return await client.getTasks(
        crop:         farm.crop,
        plantingDate: farm.plantingDate,
        date:         arg,
      );
    } catch (_) {
      return ref.read(localDbProvider).getTasksForDate(arg);
    }
  }

  Future<void> toggleComplete(String taskId) async {
    state = const AsyncLoading();
    final current = state.value ?? [];
    final updated = current.map((t) =>
      t.id == taskId ? FarmTask(
        id: t.id, name: t.name, type: t.type,
        note: t.note, date: t.date,
        completed: !t.completed,
      ) : t,
    ).toList();

    // Optimistic update
    state = AsyncData(updated);

    // Sync to backend
    try {
      await ref.read(apiClientProvider).updateTask(
        taskId: taskId,
        completed: updated.firstWhere((t) => t.id == taskId).completed,
      );
    } catch (_) {
      // Queue for offline sync
      ref.read(syncServiceProvider).enqueue(
        SyncAction(type: SyncActionType.updateTask,
          payload: {'taskId': taskId}));
    }
  }
}
```

---

## 15. API CLIENT

### `lib/core/network/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

class FarmSmartApiClient {
  // ← Replace with your actual Render URL
  static const _baseUrl = 'https://farmsmart-api.onrender.com';

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  FarmSmartApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Token expired — clear and redirect to login
          _storage.deleteAll();
        }
        handler.next(e);
      },
    ));
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phone, required String name}) async {
    await _dio.post('/api/auth/otp/send',
      data: {'phone': phone, 'name': name});
  }

  Future<String> verifyOtp({
    required String phone, required String otp}) async {
    final res = await _dio.post('/api/auth/otp/verify',
      data: {'phone': phone, 'otp': otp});
    final token = res.data['token'] as String;
    await _storage.write(key: 'auth_token', value: token);
    return token;
  }

  // ── FARM ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> registerFarm({
    required String phone, required List<String> crops,
    required String lga, required String farmSize,
  }) async {
    final res = await _dio.post('/api/farm/register',
      data: {
        'phone': phone, 'crops': crops,
        'lga': lga, 'farm_size': farmSize,
      });
    return res.data;
  }

  Future<Map<String, dynamic>> getFarm(String phone) async {
    final res = await _dio.get('/api/farm/$phone');
    return res.data;
  }

  // ── ADVISORY ──────────────────────────────────────────────────────────────

  Future<AdvisoryData> generateAdvisory({
    required String crop, required double lat,
    required double lon, required String farmId,
  }) async {
    final res = await _dio.post('/api/advisory/generate',
      data: {
        'crop': crop, 'lat': lat,
        'lon': lon, 'farm_id': farmId,
      });
    return AdvisoryData.fromJson(res.data);
  }

  // ── MARKET ────────────────────────────────────────────────────────────────

  Future<MarketData> getMarketPrices({
    required String crop, required String lga}) async {
    final res = await _dio.get('/api/market/prices',
      queryParameters: {'crop': crop, 'lga': lga});
    return MarketData.fromJson(res.data);
  }

  // ── TASKS ─────────────────────────────────────────────────────────────────

  Future<List<FarmTask>> getTasks({
    required String crop, required DateTime plantingDate,
    required DateTime date,
  }) async {
    final res = await _dio.get('/api/tasks',
      queryParameters: {
        'crop': crop,
        'planting_date': plantingDate.toIso8601String().split('T').first,
        'date': date.toIso8601String().split('T').first,
      });
    return (res.data['tasks'] as List)
      .map((t) => FarmTask(
        id:        t['id'],
        name:      t['task'],
        type:      t['type'],
        note:      t['note'],
        date:      DateTime.parse(t['date']),
        completed: t['completed'] ?? false,
      )).toList();
  }

  Future<void> updateTask({
    required String taskId, required bool completed}) async {
    await _dio.patch('/api/tasks/$taskId',
      data: {'completed': completed});
  }

  // ── PEST DETECTION ────────────────────────────────────────────────────────

  Future<ScanResult> detectPest(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
    });
    final res = await _dio.post('/api/pest/detect',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 30),
      ));
    return ScanResult.fromJson(res.data);
  }
}
```

---

## 16. OFFLINE SYNC

### `lib/core/sync/sync_service.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

enum SyncActionType { updateTask, saveScan, updateSettings }

class SyncAction {
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncAction({
    required this.type,
    required this.payload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SyncService {
  final FarmSmartApiClient _api;
  final Ref _ref;
  final List<SyncAction> _queue = [];

  SyncService(this._api, this._ref) {
    // Listen for reconnection
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) =>
        r != ConnectivityResult.none);
      if (hasNetwork && _queue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  void enqueue(SyncAction action) {
    _queue.add(action);
    // Try immediately if online
    Connectivity().checkConnectivity().then((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _processQueue();
      }
    });
  }

  Future<void> _processQueue() async {
    final toProcess = List<SyncAction>.from(_queue);
    for (final action in toProcess) {
      try {
        switch (action.type) {
          case SyncActionType.updateTask:
            await _api.updateTask(
              taskId:    action.payload['taskId'],
              completed: action.payload['completed'],
            );
          case SyncActionType.saveScan:
            await _api.detectPest(action.payload['imagePath']);
          case SyncActionType.updateSettings:
            // sync prefs to backend if needed
            break;
        }
        _queue.remove(action);
      } catch (_) {
        // Keep in queue, try again next connection
        break;
      }
    }
  }

  Future<void> syncAll() async {
    await _processQueue();
  }

  int get pendingCount => _queue.length;
}
```

---

## 17. PUBSPEC.YAML

```yaml
name: farmsmart
description: Advisory app for Nigerian smallholder farmers
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Fonts
  google_fonts: ^6.2.1

  # Navigation
  go_router: ^13.2.0

  # Networking
  dio: ^5.4.3+1

  # Local storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.3

  # Database (Drift)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.22
  path_provider: ^2.1.3
  path: ^1.9.0

  # Calendar
  table_calendar: ^3.1.1

  # Charts
  fl_chart: ^0.67.0

  # Camera / Image
  image_picker: ^1.1.1
  camera: ^0.10.5+9

  # OTP input
  pinput: ^3.0.1

  # Connectivity
  connectivity_plus: ^6.0.3

  # Shimmer loading
  shimmer: ^3.0.0

  # HTTP download (OTA update)
  open_file: ^3.3.2
  package_info_plus: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.9
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```

---

## IMPLEMENTATION ORDER

Follow this exact order. Do not skip ahead.

```
WEEK 1 — Foundation
☐ W1.1  Set up app_theme.dart (colors, fonts, spacing)
☐ W1.2  Create shared widgets (shimmer, error, empty, chip, button)
☐ W1.3  Set up bottom nav shell (main_shell.dart)
☐ W1.4  Wire splash → signup → OTP → onboarding → home routing
☐ W1.5  Build splash, signup, OTP screens

WEEK 2 — Core Screens
☐ W2.1  Onboarding 3-step flow → POST /api/farm/register
☐ W2.2  Home dashboard with all 4 states (loading/data/empty/error/offline)
☐ W2.3  Wire advisoryProvider to real backend
☐ W2.4  Farming Calendar with task list and toggle complete
☐ W2.5  Remove all _mockFarm, _getSampleTasks(), _getMockPrices()

WEEK 3 — Features
☐ W3.1  Market Prices screen with fl_chart bar chart
☐ W3.2  Crop Scanner — real camera + POST /api/pest/detect
☐ W3.3  Scan Result screen with treatment steps
☐ W3.4  Settings — all toggles persist to shared_prefs
☐ W3.5  Offline banner + connectivity_plus wiring

WEEK 4 — Polish
☐ W4.1  Sync service — queue offline actions, flush on reconnect
☐ W4.2  Announcement banner on home screen
☐ W4.3  dart run build_runner build (generate Drift files)
☐ W4.4  flutter analyze — fix all warnings
☐ W4.5  QA checklist — every tap has a reaction, no dead callbacks
☐ W4.6  flutter build apk --release
```

---

## QA CHECKLIST (Before Release)

**Every screen:**
- [ ] Loading state shows shimmer (not blank screen)
- [ ] Error state shows message + retry button
- [ ] Empty state shows helpful message + action
- [ ] Offline banner appears when no internet
- [ ] Pull-to-refresh works on scrollable screens

**Every button:**
- [ ] Disabled while loading (no double-tap bugs)
- [ ] Shows spinner when async action is running
- [ ] Shows success/error toast on completion

**Auth flow:**
- [ ] OTP is verified against real backend
- [ ] Farm data persists after app restart
- [ ] Logout clears all local storage

**Scanner:**
- [ ] Camera opens on Android (check permissions)
- [ ] Gallery picker works
- [ ] Offline model works without internet
- [ ] Feedback thumbs up/down records to backend

**Settings:**
- [ ] All notification toggles persist after app restart
- [ ] Sync Now shows progress, success message
- [ ] Clear Cache actually clears SQLite tables
- [ ] Language switch changes app language immediately
- [ ] Logout clears secure storage and navigates to splash

---

*FarmSmart Implementation Guide v2.0 · Based on UI design spec · Green + Earth palette*
