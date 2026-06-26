class ApiConstants {
  ApiConstants._();

  // FarmSmart backend
  static const String farmsmartBaseUrl = 'https://farmsmart-dlou.onrender.com';
  static const String healthEndpoint = '/health';
  static const String soilEndpoint = '/test/soil';
  static const String weatherEndpoint = '/test/weather';
  static const String pestEndpoint = '/test/pest';

  // FAO WaPOR API (free, no token needed for v3)
  static const String faoWaporBaseUrl = 'https://data.apps.fao.org/wapor/v3';
  static const String faoWaporApiPath = '/api';

  // FAO ASIS API
  static const String faoAsisBaseUrl = 'https://data.apps.fao.org/asis';

  // Digital Earth Africa
  static const String deAfricaBaseUrl = 'https://api.digitalearth.africa';

  // NASA POWER
  static const String nasaPowerUrl = 'https://power.larc.nasa.gov/api/temporal';
}

class StorageConstants {
  StorageConstants._();

  static const String dbName = 'farmsmart.db';
  static const String authTokenKey = 'auth_token';
  static const String localeKey = 'app_locale';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastSyncKey = 'last_sync_timestamp';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'FarmSmart';
  static const String appVersion = '1.0.0';
  static const int cacheExpiryDays = 14;
  static const int locationCacheKm = 50;
  static const int maxOfflineDays = 14;

  // Nigerian market constants
  static const String countryCode = 'NG';
  static const String currency = '₦';
  static const int smsLengthLimit = 160;

  // Timeouts — kept here for import convenience (referenced via AppConstants)
}
