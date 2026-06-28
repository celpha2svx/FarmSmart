import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/translations.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'navigation/main_shell.dart';
import 'features/scanner/screens/scanner_screen.dart';
import 'features/settings/screens/ota_update_screen.dart';
import 'features/settings/screens/feedback_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: FarmSmartApp()));
}

class FarmSmartApp extends ConsumerWidget {
  const FarmSmartApp({super.key});

  Locale _resolveLocale(String code) {
    switch (code) {
      case 'ha': return const Locale('ha');
      case 'yo': return const Locale('yo');
      case 'ig': return const Locale('ig');
      case 'pcm': return const Locale('en');
      default: return const Locale('en');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(translationsProvider).locale;

    return MaterialApp(
      title: 'FarmSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _resolveLocale(localeCode),
      supportedLocales: const [
        Locale('en'),
        Locale('ha'),
        Locale('yo'),
        Locale('ig'),
      ],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/otp':
            final phone = settings.arguments as String? ?? '';
            return MaterialPageRoute(builder: (_) => OtpScreen(phone: phone));
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainShell());
          case '/scanner':
            return MaterialPageRoute(builder: (_) => const ScannerScreen());
          case '/ota':
            return MaterialPageRoute(builder: (_) => const OTAUpdateScreen());
          case '/feedback':
            return MaterialPageRoute(builder: (_) => const FeedbackScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
