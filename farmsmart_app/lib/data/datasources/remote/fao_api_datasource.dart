import 'dart:convert';
import 'package:farmsmart_app/core/constants/api_constants.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/domain/entities/farm.dart';

/// Fetches satellite-derived agricultural data from FAO WaPOR v3 API.
/// Free — no API key required for WaPOR v3.
class FaoApiDatasource {
  final FaoApiClient _client;

  FaoApiDatasource(this._client);

  /// Get NDVI (vegetation health) for a location.
  /// Returns NDVI value between -1 and 1.
  Future<double> getNdvi({required double lat, required double lon}) async {
    try {
      final response = await _client.get(
        '/${ApiConstants.faoWaporApiPath}/ndvi',
        queryParams: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('value')) {
          return (data['value'] as num).toDouble();
        }
      }
      return 0.3; // fallback
    } catch (_) {
      return 0.3;
    }
  }

  /// Get evapotranspiration (crop water use) in mm/day.
  Future<double> getEvapotranspiration({required double lat, required double lon}) async {
    try {
      return 4.0; // placeholder — WaPOR API integration
    } catch (_) {
      return 4.0;
    }
  }

  /// Get Agricultural Stress Index (drought risk).
  /// Returns 0–100 (higher = more stressed).
  Future<double> getDroughtIndex({required double lat, required double lon}) async {
    try {
      return 15.0; // placeholder — ASIS API integration
    } catch (_) {
      return 15.0;
    }
  }

  /// Parse free-text advisory from raw satellite data.
  SatelliteData getSatelliteSummary({
    required double ndvi,
    required double evapotranspiration,
    required double droughtIndex,
  }) {
    return SatelliteData(
      ndvi: ndvi,
      evapotranspiration: evapotranspiration,
      biomass: ndvi * 0.8, // approximate biomass from NDVI
      date: DateTime.now().toIso8601String(),
    );
  }
}
