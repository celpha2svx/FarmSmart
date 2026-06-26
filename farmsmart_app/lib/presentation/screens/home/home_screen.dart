import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/theme/colors.dart';
import 'package:farmsmart_app/core/constants/app_constants.dart';
import 'package:farmsmart_app/core/localization/app_localizations.dart';
import 'package:farmsmart_app/domain/entities/farm.dart';
import 'package:farmsmart_app/presentation/providers/connectivity_provider.dart';
import 'package:farmsmart_app/presentation/providers/advisory_provider.dart';
import 'package:farmsmart_app/presentation/providers/core_providers.dart';
import 'package:farmsmart_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:farmsmart_app/presentation/screens/scanner/crop_scanner_screen.dart';
import 'package:farmsmart_app/presentation/screens/calendar/farming_calendar_screen.dart';
import 'package:farmsmart_app/presentation/screens/market/market_prices_screen.dart';
import 'package:farmsmart_app/presentation/widgets/common/offline_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _mockFarm = Farm(
    id: 'farm_001',
    phone: '2348012345678',
    crop: 'maize',
    locationRaw: 'Zaria, Kaduna',
    lat: 11.078,
    lon: 7.702,
    farmSize: 'medium',
    registered: DateTime.now().toIso8601String(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load advisories after build
      ref.read(advisoryProvider.notifier).fetchAdvisories(_mockFarm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final advisoryState = ref.watch(advisoryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(advisoryProvider.notifier).fetchAdvisories(_mockFarm);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                _buildHeader(t),

                if (!isOnline) const OfflineBanner(),

                // ── Crop & Location Banner ──
                _buildFarmBanner(t),

                // ── Daily Advisory (农业日报) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    t.translate('today_advisory'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildAdvisoryCard(t, advisoryState),

                // ── Quick Stats Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        icon: '🌡️',
                        label: '32°C',
                        subtitle: t.translate('temperature'),
                        color: AppColors.warning,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard(
                        icon: '💧',
                        label: '65%',
                        subtitle: t.translate('humidity'),
                        color: AppColors.info,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard(
                        icon: '🌧️',
                        label: '0.2mm',
                        subtitle: t.translate('rainfall'),
                        color: AppColors.soilWet,
                      )),
                    ],
                  ),
                ),

                // ── Today's Task ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    t.translate('today_task'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildTodayTask(t),

                // ── Quick Actions ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildActionButton(
                            icon: '📷',
                            label: t.translate('scan_crop'),
                            onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const CropScannerScreen()),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(
                            icon: '📅',
                            label: t.translate('farming_calendar'),
                            onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const FarmingCalendarScreen()),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildActionButton(
                            icon: '💰',
                            label: t.translate('market_prices'),
                            onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const MarketPricesScreen()),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌱 FarmSmart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your farm, smarter.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date display
          Text(
            _formattedDate(),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmBanner(AppLocalizations t) {
    final cropEmoji = CropConstants.cropEmojis[_mockFarm.crop] ?? '🌱';
    final cropName = CropConstants.cropDisplayNames[_mockFarm.crop] ?? _mockFarm.crop;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(cropEmoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cropName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _mockFarm.locationRaw,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _mockFarm.farmSize == 'small'
                  ? AppColors.soilDry.withOpacity(0.1)
                  : _mockFarm.farmSize == 'medium'
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _mockFarm.farmSize?.toUpperCase() ?? 'MEDIUM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _mockFarm.farmSize == 'small'
                    ? AppColors.soilDry
                    : _mockFarm.farmSize == 'medium'
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(AppLocalizations t, AdvisoryState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final message = state.soilMessage ?? 'Pull down to refresh advisory.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Farm Advisory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (state.error == null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                label: const Text(
                  'View full advisory',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTodayTask(AppLocalizations t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('💧', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Irrigate maize field',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Soil moisture is low. Apply 20L/m² this morning.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Mark Done',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
