import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsState {
  final String locale;
  final bool dailyAdvisory;
  final bool pestAlerts;
  final bool marketAlerts;
  final bool weatherAlerts;
  final bool autoSync;
  final double cacheSizeMb;
  final String appVersion;
  const SettingsState({
    this.locale = 'en',
    this.dailyAdvisory = true,
    this.pestAlerts = true,
    this.marketAlerts = false,
    this.weatherAlerts = true,
    this.autoSync = true,
    this.cacheSizeMb = 4.2,
    this.appVersion = '2.0.0+3',
  });
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final version = '${info.version}+${info.buildNumber}';
    state = SettingsState(
      locale: prefs.getString('locale') ?? 'en',
      dailyAdvisory: prefs.getBool('daily_advisory') ?? true,
      pestAlerts: prefs.getBool('pest_alerts') ?? true,
      marketAlerts: prefs.getBool('market_alerts') ?? false,
      weatherAlerts: prefs.getBool('weather_alerts') ?? true,
      autoSync: prefs.getBool('auto_sync') ?? true,
      appVersion: version,
    );
  }

  SettingsState _merged({String? locale, bool? dailyAdvisory, bool? pestAlerts, bool? marketAlerts, bool? weatherAlerts, bool? autoSync, double? cacheSizeMb}) {
    return SettingsState(
      locale: locale ?? state.locale,
      dailyAdvisory: dailyAdvisory ?? state.dailyAdvisory,
      pestAlerts: pestAlerts ?? state.pestAlerts,
      marketAlerts: marketAlerts ?? state.marketAlerts,
      weatherAlerts: weatherAlerts ?? state.weatherAlerts,
      autoSync: autoSync ?? state.autoSync,
      cacheSizeMb: cacheSizeMb ?? state.cacheSizeMb,
      appVersion: state.appVersion,
    );
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    state = _merged(locale: locale);
  }

  Future<void> setDailyAdvisory(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_advisory', v);
    state = _merged(dailyAdvisory: v);
  }

  Future<void> setPestAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pest_alerts', v);
    state = _merged(pestAlerts: v);
  }

  Future<void> setMarketAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('market_alerts', v);
    state = _merged(marketAlerts: v);
  }

  Future<void> setWeatherAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts', v);
    state = _merged(weatherAlerts: v);
  }

  Future<void> setAutoSync(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', v);
    state = _merged(autoSync: v);
  }

  Future<void> syncNow() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> clearCache() async {
    state = _merged(cacheSizeMb: 0);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
