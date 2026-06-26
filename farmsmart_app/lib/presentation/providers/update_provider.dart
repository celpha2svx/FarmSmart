import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';

class UpdateState {
  final String? latestVersion;
  final String? apkUrl;
  final String? changelog;
  final bool mandatory;
  final bool isChecking;
  final bool isDownloading;
  final double downloadProgress;
  final bool hasUpdate;

  const UpdateState({
    this.latestVersion,
    this.apkUrl,
    this.changelog,
    this.mandatory = false,
    this.isChecking = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
    this.hasUpdate = false,
  });

  UpdateState copyWith({
    String? latestVersion,
    String? apkUrl,
    String? changelog,
    bool? mandatory,
    bool? isChecking,
    bool? isDownloading,
    double? downloadProgress,
    bool? hasUpdate,
  }) {
    return UpdateState(
      latestVersion: latestVersion ?? this.latestVersion,
      apkUrl: apkUrl ?? this.apkUrl,
      changelog: changelog ?? this.changelog,
      mandatory: mandatory ?? this.mandatory,
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      hasUpdate: hasUpdate ?? this.hasUpdate,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final FarmSmartApiClient _client;

  UpdateNotifier(this._client) : super(const UpdateState()) {
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true);
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final resp = await _client.get('/api/version/latest');
      final data = resp.data as Map;

      if (data['status'] == 'ok' && data['version_name'] != null) {
        final latest = data['version_name'] as String;
        final hasUpdate = _compareVersions(latest, currentVersion) > 0;

        state = state.copyWith(
          isChecking: false,
          hasUpdate: hasUpdate,
          latestVersion: latest,
          apkUrl: data['apk_url']?.toString(),
          changelog: data['changelog']?.toString(),
          mandatory: data['mandatory'] == true,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(isChecking: false);
  }

  void startDownload() {
    // In production, use flutter_downloader or dio to download APK
    // and trigger Android's package installer
    state = state.copyWith(isDownloading: true, downloadProgress: 0);
  }

  void updateProgress(double progress) {
    state = state.copyWith(downloadProgress: progress);
    if (progress >= 1.0) {
      state = state.copyWith(isDownloading: false, hasUpdate: false);
    }
  }

  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1 - p2;
    }
    return 0;
  }
}

final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier(FarmSmartApiClient());
});
