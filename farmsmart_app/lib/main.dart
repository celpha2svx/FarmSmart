import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:farmsmart_app/core/theme/app_theme.dart';
import 'package:farmsmart_app/core/localization/app_localizations.dart';
import 'package:farmsmart_app/presentation/providers/locale_provider.dart';
import 'package:farmsmart_app/presentation/providers/connectivity_provider.dart';
import 'package:farmsmart_app/presentation/screens/splash/splash_screen.dart';

Locale _localeFromString(String code) {
  switch (code) {
    case 'ha': return const Locale('ha');
    case 'yo': return const Locale('yo');
    case 'ig': return const Locale('ig');
    default: return const Locale('en');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FarmSmartApp(),
    ),
  );
}

class FarmSmartApp extends ConsumerWidget {
  const FarmSmartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final connectivityStatus = ref.watch(connectivityProvider);

    return MaterialApp(
      title: 'FarmSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      locale: _localeFromString(locale),
      supportedLocales: const [
        Locale('en'),
        Locale('ha'),
        Locale('yo'),
        Locale('ig'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      home: const SplashScreen(),
    );
  }
}
