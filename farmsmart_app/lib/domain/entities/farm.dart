class Farm {
  final String id;
  final String phone;
  final String crop;
  final String locationRaw;
  final double lat;
  final double lon;
  final String? farmSize;
  final int subscribed;
  final int dailyUpdate;
  final String registered;

  Farm({
    required this.id,
    required this.phone,
    required this.crop,
    required this.locationRaw,
    required this.lat,
    required this.lon,
    this.farmSize,
    this.subscribed = 1,
    this.dailyUpdate = 1,
    required this.registered,
  });

  String get cropDisplayName {
    return crop.replaceAll('_', ' ').split(' ').map((w) =>
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String get cropEmoji {
    // Return appropriate emoji based on crop
    return '🌱';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'crop': crop,
    'location_raw': locationRaw,
    'lat': lat,
    'lon': lon,
    'farm_size': farmSize,
    'subscribed': subscribed,
    'daily_update': dailyUpdate,
    'registered': registered,
  };

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    id: json['id'],
    phone: json['phone'],
    crop: json['crop'],
    locationRaw: json['location_raw'],
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    farmSize: json['farm_size'],
    subscribed: json['subscribed'] ?? 1,
    dailyUpdate: json['daily_update'] ?? 1,
    registered: json['registered'],
  );
}

class Advisory {
  final String id;
  final String farmId;
  final String advisoryType;
  final String title;
  final String message;
  final String? riskLevel;
  final String date;
  final bool read;

  Advisory({
    required this.id,
    required this.farmId,
    required this.advisoryType,
    required this.title,
    required this.message,
    this.riskLevel,
    required this.date,
    this.read = false,
  });
}

class WeatherForecast {
  final String date;
  final double tempMax;
  final double tempMin;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;

  WeatherForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['date'] ?? '',
      tempMax: (json['temp_max'] as num?)?.toDouble() ?? 0,
      tempMin: (json['temp_min'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0,
      condition: json['condition'] ?? 'sunny',
    );
  }

  String get conditionEmoji {
    switch (condition) {
      case 'sunny': return '☀️';
      case 'cloudy': return '⛅';
      case 'rainy': return '🌧️';
      case 'stormy': return '⛈️';
      case 'windy': return '💨';
      default: return '☀️';
    }
  }
}

class SoilMoisture {
  final double moisture;
  final double? temperature;
  final double? ph;
  final double critical;
  final double low;

  SoilMoisture({
    required this.moisture,
    this.temperature,
    this.ph,
    required this.critical,
    required this.low,
  });

  String get status {
    if (moisture < critical) return 'CRITICAL';
    if (moisture < low) return 'LOW';
    if (moisture < low * 1.5) return 'ADEQUATE';
    return 'OPTIMAL';
  }

  double get statusPercent {
    if (moisture >= low) return 1.0;
    if (moisture <= critical) return 0.0;
    return (moisture - critical) / (low - critical);
  }
}

class PestRisk {
  final String pestId;
  final String pestName;
  final String riskLevel; // 'HIGH' | 'MEDIUM' | 'LOW'
  final double? probability;

  PestRisk({
    required this.pestId,
    required this.pestName,
    required this.riskLevel,
    this.probability,
  });

  factory PestRisk.fromJson(Map<String, dynamic> json) {
    return PestRisk(
      pestId: json['pest_id'] ?? '',
      pestName: json['pest_name'] ?? '',
      riskLevel: json['risk_level'] ?? 'LOW',
      probability: (json['probability'] as num?)?.toDouble(),
    );
  }
}

class MarketPrice {
  final String crop;
  final String market;
  final double price;
  final String unit;
  final String date;

  MarketPrice({
    required this.crop,
    required this.market,
    required this.price,
    this.unit = 'kg',
    required this.date,
  });

  String get formattedPrice => '₦${price.toStringAsFixed(0)}/$unit';
}

class FarmingTask {
  final String id;
  final String farmId;
  final String taskDate;
  final String taskType;
  final String title;
  final String description;
  final bool done;

  FarmingTask({
    required this.id,
    required this.farmId,
    required this.taskDate,
    required this.taskType,
    required this.title,
    required this.description,
    this.done = false,
  });

  String get taskEmoji {
    switch (taskType) {
      case 'plant': return '🌱';
      case 'fertilize': return '🧪';
      case 'irrigate': return '💧';
      case 'spray': return '🧴';
      case 'harvest': return '🌾';
      default: return '📋';
    }
  }
}

class SatelliteData {
  final double ndvi; // Normalized Difference Vegetation Index
  final double evapotranspiration;
  final double biomass;
  final String date;

  SatelliteData({
    required this.ndvi,
    required this.evapotranspiration,
    required this.biomass,
    required this.date,
  });

  String get cropHealthStatus {
    if (ndvi < 0.2) return 'Poor';
    if (ndvi < 0.4) return 'Fair';
    if (ndvi < 0.6) return 'Good';
    return 'Excellent';
  }
}
