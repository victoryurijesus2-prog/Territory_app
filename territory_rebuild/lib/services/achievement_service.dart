import '../models/achievement.dart';
import '../models/run_session.dart';
import '../models/territory.dart';
import 'database_service.dart';

class AchievementService {
  final DatabaseService _db;
  AchievementService({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  Future<List<Achievement>> checkAndUnlock({required String userId, required RunSession session, required List<Territory> allTerritories, required List<RunSession> allRuns, bool didCapture = false, bool didStealTerritory = false}) async {
    final alreadyUnlocked = await _db.getUnlockedAchievements(userId);
    final newlyUnlocked = <Achievement>[];
    Future<void> tryUnlock(Achievement a) async { if (alreadyUnlocked.contains(a.id.name)) return; await _db.unlockAchievement(userId, a.id.name); newlyUnlocked.add(a.copyWith(unlockedAt: DateTime.now())); }
    final myT = allTerritories.where((t) => t.ownerId == userId).toList();
    final myR = allRuns.where((r) => r.status == RunStatus.finished).toList();
    if (myR.length >= 1) await tryUnlock(_find(AchievementId.firstRun));
    if (didCapture && myT.length >= 1) await tryUnlock(_find(AchievementId.firstTerritory));
    if (myT.length >= 10) await tryUnlock(_find(AchievementId.tenTerritories));
    if (myT.length >= 50) await tryUnlock(_find(AchievementId.fiftyTerritories));
    if ((session.avgSpeedKmh ?? 0) > 12) await tryUnlock(_find(AchievementId.speedDemon));
    final totalKm = myR.fold<double>(0, (sum, r) => sum + (r.pathLengthMeters ?? 0) / 1000);
    if (totalKm >= 42) await tryUnlock(_find(AchievementId.marathoner));
    if (myT.any((t) => t.areaSqMeters >= 100000)) await tryUnlock(_find(AchievementId.bigTerritory));
    if (didStealTerritory) await tryUnlock(_find(AchievementId.conqueror));
    if ((session.startedAt?.hour ?? 99) < 7) await tryUnlock(_find(AchievementId.earlyBird));
    if (_hasWeekStreak(myR)) await tryUnlock(_find(AchievementId.weekStreak));
    return newlyUnlocked;
  }

  Future<List<Achievement>> getAchievements(String userId) async {
    final unlocked = await _db.getUnlockedAchievements(userId);
    return Achievement.all.map((a) => unlocked.contains(a.id.name) ? a.copyWith(unlockedAt: DateTime.now()) : a).toList();
  }

  bool _hasWeekStreak(List<RunSession> runs) {
    if (runs.length < 7) return false;
    final dates = runs.where((r) => r.startedAt != null).map((r) => DateTime(r.startedAt!.year, r.startedAt!.month, r.startedAt!.day)).toSet().toList()..sort();
    int streak = 1;
    for (int i = 1; i < dates.length; i++) { if (dates[i].difference(dates[i-1]).inDays == 1) { streak++; if (streak >= 7) return true; } else if (dates[i].difference(dates[i-1]).inDays > 1) { streak = 1; } }
    return false;
  }

  Achievement _find(AchievementId id) => Achievement.all.firstWhere((a) => a.id == id);
}
