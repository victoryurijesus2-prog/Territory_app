import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/run_session.dart';
import '../models/territory.dart';
import 'local_database_service.dart';
import 'database_service.dart';
import 'auth_service.dart';

enum ConnectionStatus { online, offline }

class SyncService {
  static SyncService get instance => _instance;
  static final SyncService _instance = SyncService._();
  SyncService._();
  final _local = LocalDatabaseService.instance;
  final _remote = DatabaseService.instance;
  final _client = Supabase.instance.client;
  ConnectionStatus _status = ConnectionStatus.online;
  ConnectionStatus get status => _status;
  bool get isOnline => _status == ConnectionStatus.online;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Timer? _syncTimer;
  bool _syncing = false;

  void startMonitoring() { _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _trySyncPendingRuns()); _trySyncPendingRuns(); }
  void stopMonitoring() => _syncTimer?.cancel();

  Future<bool> checkConnection() async {
    try { await _client.from('territories').select('id').limit(1); _setStatus(ConnectionStatus.online); return true; } catch (_) { _setStatus(ConnectionStatus.offline); return false; }
  }

  void _setStatus(ConnectionStatus s) { if (_status != s) { _status = s; _statusController.add(s); if (s == ConnectionStatus.online) _trySyncPendingRuns(); } }

  Future<void> saveRun(RunSession session) async { await _local.saveRunLocally(session); if (isOnline) await _trySyncPendingRuns(); }

  Future<int> _trySyncPendingRuns() async {
    if (_syncing || !AuthService.isLoggedIn) return 0;
    _syncing = true; int synced = 0;
    try {
      final online = await checkConnection(); if (!online) return 0;
      final pending = await _local.getPendingRuns();
      for (final run in pending) { try { await _remote.saveRunSession(run); await _local.markRunSynced(run.id); synced++; } catch (e) { debugPrint('Erro sync: $e'); } }
    } catch (e) { debugPrint('Erro sync: $e'); } finally { _syncing = false; }
    return synced;
  }

  Future<int> forceSyncNow() async { _syncing = false; return _trySyncPendingRuns(); }

  Future<List<Territory>> getTerritories() async {
    try { final online = await checkConnection(); if (online) { final t = await _remote.getAllTerritories(); await _local.cacheTerritories(t); return t; } } catch (_) {}
    return _local.getCachedTerritories();
  }

  Future<List<RunSession>> getMyRuns(String userId) async {
    try { final online = await checkConnection(); if (online) return await _remote.getRunSessionsByUser(userId); } catch (_) {}
    return _local.getAllLocalRuns(userId);
  }

  Future<int> getPendingCount() => _local.getPendingRunsCount();
  void dispose() { _syncTimer?.cancel(); _statusController.close(); }
}
