import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/territory.dart';
import '../models/run_session.dart';
import '../models/ranking_entry.dart';

class DatabaseService {
  static DatabaseService get instance => _instance;
  static final DatabaseService _instance = DatabaseService._();
  DatabaseService._();
  final _client = Supabase.instance.client;

  Future<List<Territory>> getAllTerritories() async { final data = await _client.from('territories').select().order('captured_at', ascending: false); return data.map((m) => Territory.fromMap(m)).toList(); }
  Future<List<Territory>> getTerritoriesByOwner(String userId) async { final data = await _client.from('territories').select().eq('owner_id', userId).order('captured_at', ascending: false); return data.map((m) => Territory.fromMap(m)).toList(); }
  Future<void> saveTerritory(Territory t) async { await _client.from('territories').upsert(t.toMap()); try { await _client.rpc('increment_player_stats', params: {'p_user_id': t.ownerId, 'p_area': t.areaSqMeters}); } catch (_) {} }
  Future<void> updateTerritory(Territory t) async => _client.from('territories').update(t.toMap()).eq('id', t.id);
  Future<double> getTotalAreaByOwner(String userId) async { final data = await _client.from('profiles').select('total_area_m2').eq('id', userId).maybeSingle(); return (data?['total_area_m2'] as num?)?.toDouble() ?? 0; }
  Future<void> saveRunSession(RunSession s) async => _client.from('run_sessions').upsert(s.toMap());
  Future<List<RunSession>> getRunSessionsByUser(String userId, {int limit = 20}) async { final data = await _client.from('run_sessions').select().eq('user_id', userId).order('started_at', ascending: false).limit(limit); return data.map((m) => RunSession.fromMap(m)).toList(); }
  Future<double?> getBestRunDistanceByUser(String userId) async { final data = await _client.from('run_sessions').select('path_length_meters').eq('user_id', userId).eq('status', 'finished').order('path_length_meters', ascending: false).limit(1).maybeSingle(); return (data?['path_length_meters'] as num?)?.toDouble(); }
  Future<List<RankingEntry>> getRanking({required RankingPeriod period, int limit = 50}) async { final viewName = switch (period) { RankingPeriod.weekly => 'ranking_weekly', RankingPeriod.monthly => 'ranking_monthly', RankingPeriod.allTime => 'ranking_all_time' }; final data = await _client.from(viewName).select().limit(limit); return data.asMap().entries.map((e) => RankingEntry.fromMap(e.value, e.key + 1)).toList(); }
  Future<List<String>> getUnlockedAchievements(String userId) async { final data = await _client.from('user_achievements').select('achievement_id').eq('user_id', userId); return data.map((m) => m['achievement_id'] as String).toList(); }
  Future<void> unlockAchievement(String userId, String achievementId) async => _client.from('user_achievements').upsert({'user_id': userId, 'achievement_id': achievementId, 'unlocked_at': DateTime.now().toIso8601String()}, onConflict: 'user_id,achievement_id');
  Stream<List<Territory>> territoriesStream() => _client.from('territories').stream(primaryKey: ['id']).order('captured_at').map((rows) => rows.map((m) => Territory.fromMap(m)).toList());
}

enum RankingPeriod { weekly, monthly, allTime }
