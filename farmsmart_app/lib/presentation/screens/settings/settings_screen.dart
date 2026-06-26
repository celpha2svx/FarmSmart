import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/core/localization/app_localizations.dart';
import 'package:farmsmart_app/presentation/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('settings')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          _buildSectionHeader(t.translate('language')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(t.translate('language')),
              subtitle: Text(
                currentLocale == 'en' ? 'English' :
                currentLocale == 'ha' ? 'Hausa' :
                currentLocale == 'yo' ? 'Yoruba' :
                currentLocale == 'ig' ? 'Igbo' : 'English',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionHeader(t.translate('notifications')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily 6 AM Advisory'),
                  subtitle: const Text('Receive farm report every morning'),
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Pest Alerts'),
                  subtitle: const Text('Instant alerts when pest risk is HIGH'),
                  value: true,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Market Price Updates'),
                  subtitle: const Text('Weekly price notifications'),
                  value: false,
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          _buildSectionHeader(t.translate('about')),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.primary),
                  title: Text('FarmSmart'),
                  subtitle: Text('Version 1.0.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data & Storage
          _buildSectionHeader('Data & Storage'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.primary),
                  title: const Text('Cached Data'),
                  subtitle: const Text('Last synced: Today 6:00 AM'),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Sync Now'),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Clear Offline Cache'),
                  subtitle: const Text('14 days of advisories stored'),
                  onTap: () => _confirmClearCache(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                t.translate('logout'),
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              _languageOption(ctx, ref, '🇳🇬 English', 'en'),
              _languageOption(ctx, ref, '🇳🇬 Hausa', 'ha'),
              _languageOption(ctx, ref, '🇳🇬 Yoruba', 'yo'),
              _languageOption(ctx, ref, '🇳🇬 Igbo', 'ig'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(BuildContext ctx, WidgetRef ref, String label, String code) {
    final current = ref.watch(localeProvider);
    return ListTile(
      title: Text(label),
      trailing: current == code
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(code);
        Navigator.pop(ctx);
      },
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove offline advisories. You can re-sync when connected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
