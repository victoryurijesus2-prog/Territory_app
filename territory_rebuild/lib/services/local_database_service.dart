import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/run_session.dart';
import '../models/territory.dart';

class LocalDatabaseService {
  static LocalDatabaseService get instance => _instance;
  static final LocalDatabaseService _instance = LocalDatabaseService._();
  LocalDatabaseService._();
  Database? _db;

  Future<Database> get db async { _db ??= await _initDb(); return _db!; }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'territory_local.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS pending_runs (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, path_json TEXT NOT NULL, timestamps_json TEXT NOT NULL, status TEXT NOT NULL, started_at TEXT, finished_at TEXT, max_speed_kmh REAL, avg_speed_kmh REAL, path_length_meters REAL, estimated_calories REAL, pace_min_per_km REAL, fraud_detected INTEGER DEFAULT 0, is_personal_record INTEGER DEFAULT 0, synced INTEGER DEFAULT 0)');
      await db.execute('CREATE TABLE IF NOT EXISTS cached_territories (id TEXT PRIMARY KEY, owner_id TEXT NOT NULL, owner_name TEXT NOT NULL, owner_avatar_url TEXT, polygon_json TEXT NOT NULL, area_sq_meters REAL NOT NULL, captured_at TEXT NOT NULL, color TEXT DEFAULT "#FF5722", level INTEGER DEFAULT 1, points_per_hour REAL DEFAULT 1.0, cached_at TEXT NOT NULL)');
    });
  }

  Future<void> saveRunLocally(RunSession session) async { final database = await db; await database.insert('pending_runs', {...session.toMap(), 'synced': 0}, conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<RunSession>> getPendingRuns() async { final database = await db; final rows = await database.query('pending_runs', where: 'synced = ?', whereArgs: [0]); return rows.map((r) => RunSession.fromMap(r)).toList(); }
  Future<List<RunSession>> getAllLocalRuns(String userId) async { final database = await db; final rows = await database.query('pending_runs', where: 'user_id = ?', whereArgs: [userId], orderBy: 'started_at DESC', limit: 20); return rows.map((r) => RunSession.fromMap(r)).toList(); }
  Future<void> markRunSynced(String runId) async { final database = await db; await database.update('pending_runs', {'synced': 1}, where: 'id = ?', whereArgs: [runId]); }
  Future<int> getPendingRunsCount() async { final database = await db; final result = await database.rawQuery('SELECT COUNT(*) as count FROM pending_runs WHERE synced = 0'); return result.first['count'] as int; }
  Future<void> cacheTerritories(List<Territory> territories) async { final database = await db; final batch = database.batch(); for (final t in territories) { batch.insert('cached_territories', {...t.toMap(), 'cached_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace); } await batch.commit(noResult: true); }
  Future<List<Territory>> getCachedTerritories() async { final database = await db; final rows = await database.query('cached_territories'); return rows.map((r) => Territory.fromMap(r)).toList(); }
  Future<bool> hasCachedTerritories() async { final database = await db; final result = await database.rawQuery('SELECT COUNT(*) as count FROM cached_territories'); return (result.first['count'] as int) > 0; }
}
