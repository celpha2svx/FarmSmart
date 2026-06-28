import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String locale;
  final bool dailyAdvisory;
  final bool pestAlerts;
  final bool marketAlerts;
  final bool weatherAlerts;
  final bool autoSync;
  final double cacheSizeMb;
  const SettingsState({
    this.locale = 'en',
    this.dailyAdvisory = true,
    this.pestAlerts = true,
    this.marketAlerts = false,
    this.weatherAlerts = true,
    this.autoSync = true,
    this.cacheSizeMb = 4.2,
  });
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      locale: prefs.getString('locale') ?? 'en',
      dailyAdvisory: prefs.getBool('daily_advisory') ?? true,
      pestAlerts: prefs.getBool('pest_alerts') ?? true,
      marketAlerts: prefs.getBool('market_alerts') ?? false,
      weatherAlerts: prefs.getBool('weather_alerts') ?? true,
      autoSync: prefs.getBool('auto_sync') ?? true,
    );
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    state = SettingsState(locale: locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: state.pestAlerts, marketAlerts: state.marketAlerts, weatherAlerts: state.weatherAlerts, autoSync: state.autoSync);
  }

  Future<void> setDailyAdvisory(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_advisory', v);
    state = SettingsState(locale: state.locale, dailyAdvisory: v, pestAlerts: state.pestAlerts, marketAlerts: state.marketAlerts, weatherAlerts: state.weatherAlerts, autoSync: state.autoSync);
  }

  Future<void> setPestAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pest_alerts', v);
    state = SettingsState(locale: state.locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: v, marketAlerts: state.marketAlerts, weatherAlerts: state.weatherAlerts, autoSync: state.autoSync);
  }

  Future<void> setMarketAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('market_alerts', v);
    state = SettingsState(locale: state.locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: state.pestAlerts, marketAlerts: v, weatherAlerts: state.weatherAlerts, autoSync: state.autoSync);
  }

  Future<void> setWeatherAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts', v);
    state = SettingsState(locale: state.locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: state.pestAlerts, marketAlerts: state.marketAlerts, weatherAlerts: v, autoSync: state.autoSync);
  }

  Future<void> setAutoSync(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', v);
    state = SettingsState(locale: state.locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: state.pestAlerts, marketAlerts: state.marketAlerts, weatherAlerts: state.weatherAlerts, autoSync: v);
  }

  Future<void> syncNow() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> clearCache() async {
    state = SettingsState(locale: state.locale, dailyAdvisory: state.dailyAdvisory, pestAlerts: state.pestAlerts, marketAlerts: state.marketAlerts, weatherAlerts: state.weatherAlerts, autoSync: state.autoSync, cacheSizeMb: 0);
  }

  Future<void> checkForUpdate(BuildContext context) async {
    // In production: call GET /api/version/latest
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ You have the latest version')),
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
