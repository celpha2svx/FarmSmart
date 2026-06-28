import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('settings')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _ProfileCard(user: auth.user, t: t),
          const SizedBox(height: 24),
          _SettingsSection(
            label: t.t('language'),
            children: [
              _LangOption(label: 'English', flag: '🇬🇧', code: 'en', selected: settings.locale == 'en'),
              _LangOption(label: 'Hausa', flag: '🇳🇬', code: 'ha', selected: settings.locale == 'ha'),
              _LangOption(label: 'Yoruba', flag: '🇳🇬', code: 'yo', selected: settings.locale == 'yo'),
              _LangOption(label: 'Igbo', flag: '🇳🇬', code: 'ig', selected: settings.locale == 'ig'),
              _LangOption(label: 'Pidgin', flag: '🇳🇬', code: 'pcm', selected: settings.locale == 'pcm'),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            label: t.t('notifications'),
            children: [
              _ToggleRow(
                icon: Icons.article_outlined,
                label: t.t('daily_advisory'),
                sub: t.t('daily_advisory_sub'),
                value: settings.dailyAdvisory,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDailyAdvisory(v),
              ),
              _ToggleRow(
                icon: Icons.bug_report_outlined,
                label: t.t('pest_alerts'),
                sub: t.t('pest_alerts_sub'),
                value: settings.pestAlerts,
                onChanged: (v) => ref.read(settingsProvider.notifier).setPestAlerts(v),
              ),
              _ToggleRow(
                icon: Icons.trending_up_outlined,
                label: t.t('market_alerts'),
                sub: t.t('market_alerts_sub'),
                value: settings.marketAlerts,
                onChanged: (v) => ref.read(settingsProvider.notifier).setMarketAlerts(v),
              ),
              _ToggleRow(
                icon: Icons.wb_sunny_outlined,
                label: t.t('weather_alerts'),
                sub: t.t('weather_alerts_sub'),
                value: settings.weatherAlerts,
                onChanged: (v) => ref.read(settingsProvider.notifier).setWeatherAlerts(v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            label: t.t('data_sync'),
            children: [
              _ToggleRow(
                icon: Icons.sync_outlined,
                label: t.t('auto_sync'),
                sub: t.t('auto_sync_sub'),
                value: settings.autoSync,
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoSync(v),
              ),
              _ActionRow(
                icon: Icons.sync,
                label: t.t('sync_now'),
                sub: t.t('sync_now_sub'),
                onTap: () => ref.read(settingsProvider.notifier).syncNow(),
              ),
              _ActionRow(
                icon: Icons.delete_outline,
                label: t.t('clear_cache'),
                sub: '${t.t('clear_cache_sub')} (${settings.cacheSizeMb.toStringAsFixed(1)} MB)',
                onTap: () => ref.read(settingsProvider.notifier).clearCache(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            label: t.t('about'),
            children: [
              _ActionRow(
                icon: Icons.system_update_outlined,
                label: t.t('check_updates'),
                sub: '${t.t('version')} ${settings.appVersion}',
                onTap: () => Navigator.pushNamed(context, '/ota'),
              ),
              _ActionRow(
                icon: Icons.feedback_outlined,
                label: t.t('send_feedback'),
                sub: t.t('feedback_sub'),
                onTap: () => Navigator.pushNamed(context, '/feedback'),
              ),
              _ActionRow(
                icon: Icons.description_outlined,
                label: t.t('terms'),
                sub: t.t('terms_sub'),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(t.t('logout')),
                    content: Text(t.t('logout_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.t('cancel'))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.t('logout'))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Color(0xFFE11919)),
              label: Text(t.t('logout'), style: const TextStyle(color: Color(0xFFE11919))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE11919)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AppUser? user;
  final Translations t;
  const _ProfileCard({required this.user, required this.t});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? t.t('farmer');
    final phone = user?.phone ?? '+234 800 000 0000';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'F',
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D1B20))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(phone, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends ConsumerWidget {
  final String label;
  final String flag;
  final String code;
  final bool selected;
  const _LangOption({required this.label, required this.flag, required this.code, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref.read(settingsProvider.notifier).setLocale(code),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22)
            else
              const Icon(Icons.radio_button_unchecked, color: Color(0xFF9E9E9E), size: 22),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1D1B20))),
                Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2E7D32),
            activeTrackColor: const Color(0xFF2E7D32).withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF6B7280)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1D1B20))),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }
}
