import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ── Table Definitions ──────────────────────────────────────────────────────────

class Farms extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get phone => text().unique()();
  TextColumn get crop => text()();
  TextColumn get locationRaw => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get farmSize => text().nullable()();
  IntColumn get subscribed => integer().withDefault(const Constant(1))();
  IntColumn get dailyUpdate => integer().withDefault(const Constant(1))();
  TextColumn get registered => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Advisories extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  TextColumn get advisoryType => text()(); // 'daily' | 'soil' | 'weather' | 'pest'
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get riskLevel => text().nullable()(); // 'HIGH' | 'MEDIUM' | 'LOW' | null
  TextColumn get date => text()(); // ISO date
  IntColumn get read => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class WeatherData extends Table {
  TextColumn get farmId => text().references(Farms, #id)();
  TextColumn get date => text()();
  RealColumn get tempMax => real()();
  RealColumn get tempMin => real()();
  RealColumn get humidity => real()();
  RealColumn get rainfall => real()();
  RealColumn get windSpeed => real()();
  TextColumn get condition => text()(); // 'sunny' | 'cloudy' | 'rainy' | etc

  @override
  Set<Column> get primaryKey => {farmId, date};
}

class SoilData extends Table {
  TextColumn get farmId => text().references(Farms, #id)();
  TextColumn get date => text()();
  RealColumn get moisture => real()();
  RealColumn get temperature => real()();
  RealColumn get ph => real().nullable()();
  RealColumn get nitrogen => real().nullable()();
  RealColumn get phosphorus => real().nullable()();
  RealColumn get potassium => real().nullable()();

  @override
  Set<Column> get primaryKey => {farmId, date};
}

class PestData extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  TextColumn get pestId => text()();
  TextColumn get riskLevel => text()(); // 'HIGH' | 'MEDIUM' | 'LOW'
  RealColumn get probability => real().nullable()();
  TextColumn get date => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class MarketPrices extends Table {
  TextColumn get crop => text()();
  TextColumn get market => text()();
  RealColumn get price => real()();
  TextColumn get unit => text()(); // 'kg' | 'bag' | 'tonne'
  TextColumn get date => text()();

  @override
  Set<Column> get primaryKey => {crop, market, date};
}

class FarmingCalendar extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  TextColumn get taskDate => text()(); // ISO date
  TextColumn get taskType => text()(); // 'plant' | 'fertilize' | 'irrigate' | 'spray' | 'harvest'
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get done => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'create' | 'update' | 'delete'
  TextColumn get payload => text()();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
}

// ── Database Definition ───────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Farms,
    Advisories,
    WeatherData,
    SoilData,
    PestData,
    MarketPrices,
    FarmingCalendar,
    SyncLog,
  ],
)
class FarmSmartDatabase extends _$FarmSmartDatabase {
  FarmSmartDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Migration ──
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {},
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'farmsmart.db'));
    return NativeDatabase(file);
  });
}
