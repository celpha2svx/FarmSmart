import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class OTAState {
  final bool checking;
  final bool updateAvailable;
  final String? latestVersion;
  final String? currentVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final double downloadProgress;
  final bool downloading;
  final bool downloaded;
  final String? error;
  final String? localPath;

  const OTAState({
    this.checking = false,
    this.updateAvailable = false,
    this.latestVersion,
    this.currentVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.downloadProgress = 0,
    this.downloading = false,
    this.downloaded = false,
    this.error,
    this.localPath,
  });

  OTAState copyWith({
    bool? checking,
    bool? updateAvailable,
    String? latestVersion,
    String? currentVersion,
    String? downloadUrl,
    String? releaseNotes,
    double? downloadProgress,
    bool? downloading,
    bool? downloaded,
    String? error,
    String? localPath,
  }) {
    return OTAState(
      checking: checking ?? this.checking,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      latestVersion: latestVersion ?? this.latestVersion,
      currentVersion: currentVersion ?? this.currentVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloading: downloading ?? this.downloading,
      downloaded: downloaded ?? this.downloaded,
      error: error ?? this.error,
      localPath: localPath ?? this.localPath,
    );
  }
}

class OTANotifier extends StateNotifier<OTAState> {
  final Dio _dio;
  OTANotifier() : _dio = Dio(), super(const OTAState());

  Future<void> checkForUpdate() async {
    state = state.copyWith(checking: true, error: null);
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = '${info.version}+${info.buildNumber}';

      final response = await _dio.get(
        'https://api.github.com/repos/celpha2svx/FarmSmart/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      final data = response.data;
      final latestTag = data['tag_name'] as String? ?? '';
      final releaseNotes = data['body'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];

      String? downloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name == 'app-release.apk') {
          downloadUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      final available = _isNewer(latestTag, currentVersion);
      state = state.copyWith(
        checking: false,
        updateAvailable: available,
        latestVersion: latestTag,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
      );
    } catch (e) {
      state = state.copyWith(
        checking: false,
        error: e.toString(),
      );
    }
  }

  bool _isNewer(String latest, String current) {
    final latestClean = latest.replaceAll(RegExp(r'[^0-9.]'), '');
    final currentClean = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final latestParts = latestClean.split('.');
    final currentParts = currentClean.split('.');
    final len = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
    for (int i = 0; i < len; i++) {
      final l = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;
      final c = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  Future<void> downloadUpdate() async {
    if (state.downloadUrl == null) return;
    state = state.copyWith(downloading: true, downloadProgress: 0, error: null);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/farmsmart_update.apk';

      await _dio.download(
        state.downloadUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(downloadProgress: received / total);
          }
        },
      );

      state = state.copyWith(
        downloading: false,
        downloaded: true,
        downloadProgress: 1.0,
        localPath: filePath,
      );
    } catch (e) {
      state = state.copyWith(
        downloading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> installUpdate() async {
    if (state.localPath == null) return;
    final result = await OpenFilex.open(state.localPath!);
    if (result.type != ResultType.done) {
      state = state.copyWith(error: 'Failed to open file: ${result.message}');
    }
  }

  void reset() {
    state = const OTAState();
  }
}

final otaProvider = StateNotifierProvider<OTANotifier, OTAState>((ref) {
  return OTANotifier();
});
