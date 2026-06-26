import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:farmsmart_app/core/database/database.dart';
import 'package:farmsmart_app/domain/entities/farm.dart' as domain;
import 'package:uuid/uuid.dart';

/// Local SQLite operations using Drift.
/// All data is cached offline for 14 days.
class LocalDatasource {
  final FarmSmartDatabase _db;
  final _uuid = const Uuid();

  LocalDatasource(this._db);

  // ── Farm ──
  Future<void> saveFarm(domain.Farm farm) async {
    await _db.into(_db.farms).insertOnConflictUpdate(
      FarmsCompanion.insert(
        id: farm.id,
        phone: farm.phone,
        crop: farm.crop,
        locationRaw: farm.locationRaw,
        lat: farm.lat,
        lon: farm.lon,
        farmSize: Value(farm.farmSize),
        subscribed: Value(farm.subscribed),
        dailyUpdate: Value(farm.dailyUpdate),
        registered: farm.registered,
      ),
    );
  }

  Future<domain.Farm?> getFarm(String phone) async {
    final rows = await (_db.select(_db.farms)
      ..where((f) => f.phone.equals(phone))
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return domain.Farm(
      id: r.id,
      phone: r.phone,
      crop: r.crop,
      locationRaw: r.locationRaw,
      lat: r.lat,
      lon: r.lon,
      farmSize: r.farmSize,
      subscribed: r.subscribed,
      dailyUpdate: r.dailyUpdate,
      registered: r.registered,
    );
  }

  // ── Advisories ──
  Future<void> saveAdvisories(List<domain.Advisory> advisories) async {
    for (final a in advisories) {
      await _db.into(_db.advisories).insertOnConflictUpdate(
        AdvisoriesCompanion.insert(
          id: a.id,
          farmId: a.farmId,
          advisoryType: a.advisoryType,
          title: a.title,
          message: a.message,
          riskLevel: Value(a.riskLevel),
          date: a.date,
          read: Value(a.read ? 1 : 0),
        ),
      );
    }
  }

  Future<List<domain.Advisory>> getAdvisories(String farmId, {int limit = 10}) async {
    final rows = await (_db.select(_db.advisories)
      ..where((a) => a.farmId.equals(farmId))
      ..orderBy([(a) => OrderingTerm.asc(a.date)])
      ..limit(limit)
    ).get();
    return rows.map((r) => domain.Advisory(
      id: r.id,
      farmId: r.farmId,
      advisoryType: r.advisoryType,
      title: r.title,
      message: r.message,
      riskLevel: r.riskLevel,
      date: r.date,
      read: r.read == 1,
    )).toList();
  }

  // ── Weather ──
  Future<void> saveWeather(String farmId, List<domain.WeatherForecast> forecasts) async {
    for (final f in forecasts) {
      await _db.into(_db.weatherData).insertOnConflictUpdate(
        WeatherDataCompanion.insert(
          farmId: farmId,
          date: f.date,
          tempMax: f.tempMax,
          tempMin: f.tempMin,
          humidity: f.humidity,
          rainfall: f.rainfall,
          windSpeed: f.windSpeed,
          condition: f.condition,
        ),
      );
    }
  }

  Future<List<domain.WeatherForecast>> getWeather(String farmId) async {
    final rows = await (_db.select(_db.weatherData)
      ..where((w) => w.farmId.equals(farmId))
      ..orderBy([(w) => OrderingTerm.asc(w.date)])
    ).get();
    return rows.map((r) => domain.WeatherForecast(
      date: r.date,
      tempMax: r.tempMax,
      tempMin: r.tempMin,
      humidity: r.humidity,
      rainfall: r.rainfall,
      windSpeed: r.windSpeed,
      condition: r.condition,
    )).toList();
  }

  // ── Farming Calendar Tasks ──
  Future<void> saveTasks(List<domain.FarmingTask> tasks) async {
    for (final t in tasks) {
      await _db.into(_db.farmingCalendar).insertOnConflictUpdate(
        FarmingCalendarCompanion.insert(
          id: t.id,
          farmId: t.farmId,
          taskDate: t.taskDate,
          taskType: t.taskType,
          title: t.title,
          description: t.description,
          done: Value(t.done ? 1 : 0),
        ),
      );
    }
  }

  Future<List<domain.FarmingTask>> getTasksForDate(String farmId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final rows = await (_db.select(_db.farmingCalendar)
      ..where((t) => t.farmId.equals(farmId) & t.taskDate.equals(dateStr))
    ).get();
    return rows.map((r) => domain.FarmingTask(
      id: r.id,
      farmId: r.farmId,
      taskDate: r.taskDate,
      taskType: r.taskType,
      title: r.title,
      description: r.description,
      done: r.done == 1,
    )).toList();
  }

  Future<void> markTaskDone(String taskId) async {
    await (_db.update(_db.farmingCalendar)
      ..where((t) => t.id.equals(taskId))
    ).write(const FarmingCalendarCompanion(done: Value(1)));
  }

  // ── Market Prices ──
  Future<void> saveMarketPrices(List<domain.MarketPrice> prices) async {
    for (final p in prices) {
      await _db.into(_db.marketPrices).insertOnConflictUpdate(
        MarketPricesCompanion.insert(
          crop: p.crop,
          market: p.market,
          price: p.price,
          unit: p.unit,
          date: p.date,
        ),
      );
    }
  }

  Future<List<domain.MarketPrice>> getMarketPrices(String crop) async {
    final rows = await (_db.select(_db.marketPrices)
      ..where((m) => m.crop.equals(crop))
      ..orderBy([(m) => OrderingTerm.desc(m.date)])
    ).get();
    return rows.map((r) => domain.MarketPrice(
      crop: r.crop,
      market: r.market,
      price: r.price,
      unit: r.unit,
      date: r.date,
    )).toList();
  }

  // ── Sync Queue ──
  Future<void> addToSyncQueue(String entityType, String entityId, String action, Map<String, dynamic> payload) async {
    await _db.into(_db.syncLog).insert(
      SyncLogCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        action: action,
        payload: jsonEncode(payload),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}
