import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/l10n/locale_provider.dart';
import '../providers/ota_provider.dart';

class OTAUpdateScreen extends ConsumerWidget {
  const OTAUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ota = ref.watch(otaProvider);
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('update_check')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(
              ota.updateAvailable ? Icons.system_update : Icons.check_circle_outline,
              size: 80,
              color: ota.updateAvailable ? AppColors.warning : AppColors.green600,
            ),
            const SizedBox(height: 24),
            Text(
              ota.checking
                  ? t.t('loading')
                  : ota.updateAvailable
                      ? t.t('update_available')
                      : t.t('update_not_available'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1D1B20)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${t.t('current_version')}: ${ota.currentVersion ?? '--'}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            if (ota.latestVersion != null) ...[
              const SizedBox(height: 4),
              Text(
                '${t.t('latest_version')}: ${ota.latestVersion}',
                style: TextStyle(
                  fontSize: 14,
                  color: ota.updateAvailable ? AppColors.green700 : const Color(0xFF6B7280),
                  fontWeight: ota.updateAvailable ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
            if (ota.releaseNotes != null && ota.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Release Notes',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1D1B20)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ota.releaseNotes!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            ],
            if (ota.error != null) ...[
              const SizedBox(height: 16),
              Text(
                ota.error!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (ota.downloading) ...[
              const SizedBox(height: 32),
              LinearProgressIndicator(
                value: ota.downloadProgress,
                backgroundColor: AppColors.green100,
                valueColor: const AlwaysStoppedAnimation(AppColors.green600),
              ),
              const SizedBox(height: 8),
              Text(
                '${(ota.downloadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, ref, ota, t),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, OTAState ota, Translations t) {
    if (ota.checking) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ota.downloaded) {
      return PrimaryButton(
        label: t.t('install'),
        icon: Icons.download_done,
        onTap: () => ref.read(otaProvider.notifier).installUpdate(),
      );
    }
    if (ota.downloading) {
      return PrimaryButton(
        label: t.t('downloading'),
        icon: Icons.downloading,
        onTap: null,
      );
    }
    if (ota.updateAvailable) {
      return PrimaryButton(
        label: t.t('install'),
        icon: Icons.download,
        onTap: () => ref.read(otaProvider.notifier).downloadUpdate(),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => ref.read(otaProvider.notifier).checkForUpdate(),
      icon: const Icon(Icons.refresh),
      label: Text(t.t('update_check')),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
