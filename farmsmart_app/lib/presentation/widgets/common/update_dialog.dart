import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/presentation/providers/update_provider.dart';

/// Shows a dialog when an update is available.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);

    if (!update.hasUpdate) return const SizedBox.shrink();

    return WillPopScope(
      onWillPop: () async => !update.mandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Update Available', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FarmSmart v${update.latestVersion} is available!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (update.changelog != null && update.changelog!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("What's new:", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                update.changelog!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (update.mandatory) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (update.isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: update.downloadProgress),
              const SizedBox(height: 8),
              Text(
                '${(update.downloadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          if (!update.mandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: update.isDownloading ? null : () {
              ref.read(updateProvider.notifier).startDownload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(update.isDownloading ? 'Downloading...' : 'Update Now'),
          ),
        ],
      ),
    );
  }
}
