// lib/services/streak_service.dart
//
// Gerencia o Daily Streak do jogador.
// Streak = dias consecutivos com pelo menos 1 corrida válida.

import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static StreakService get instance => _instance;
  static final StreakService _instance = StreakService._();
  StreakService._();

  static const _keyStreak = 'streak_count';
  static const _keyLastRun = 'streak_last_run_date';
  static const _keyBestStreak = 'streak_best';

  // ─── Registra corrida do dia ──────────────────────────────────────────────

  Future<StreakResult> registerRun() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastRun = prefs.getString(_keyLastRun) ?? '';
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;
    final bestStreak = prefs.getInt(_keyBestStreak) ?? 0;

    // Já correu hoje
    if (lastRun == today) {
      return StreakResult(
        streak: currentStreak,
        bestStreak: bestStreak,
        isNewDay: false,
        multiplier: _multiplier(currentStreak),
      );
    }

    final yesterday = _yesterdayKey();
    int newStreak;

    if (lastRun == yesterday) {
      // Continuou o streak
      newStreak = currentStreak + 1;
    } else if (lastRun.isEmpty) {
      // Primeira corrida
      newStreak = 1;
    } else {
      // Quebrou o streak
      newStreak = 1;
    }

    final newBest = newStreak > bestStreak ? newStreak : bestStreak;

    await prefs.setInt(_keyStreak, newStreak);
    await prefs.setString(_keyLastRun, today);
    await prefs.setInt(_keyBestStreak, newBest);

    return StreakResult(
      streak: newStreak,
      bestStreak: newBest,
      isNewDay: true,
      isNewRecord: newStreak > bestStreak,
      multiplier: _multiplier(newStreak),
    );
  }

  // ─── Lê streak atual ──────────────────────────────────────────────────────

  Future<StreakData> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final yesterday = _yesterdayKey();
    final lastRun = prefs.getString(_keyLastRun) ?? '';
    final streak = prefs.getInt(_keyStreak) ?? 0;
    final best = prefs.getInt(_keyBestStreak) ?? 0;

    // Verifica se streak está ativo (correu hoje ou ontem)
    final isActive = lastRun == today || lastRun == yesterday;
    final ranToday = lastRun == today;

    return StreakData(
      streak: isActive ? streak : 0,
      bestStreak: best,
      isActive: isActive,
      ranToday: ranToday,
      multiplier: _multiplier(isActive ? streak : 0),
    );
  }

  // ─── Multiplier de pontos baseado no streak ───────────────────────────────

  double _multiplier(int streak) {
    if (streak >= 30) return 3.0;
    if (streak >= 14) return 2.5;
    if (streak >= 7) return 2.0;
    if (streak >= 3) return 1.5;
    return 1.0;
  }

  // ─── Helpers de data ──────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }
}

class StreakResult {
  final int streak;
  final int bestStreak;
  final bool isNewDay;
  final bool isNewRecord;
  final double multiplier;

  const StreakResult({
    required this.streak,
    required this.bestStreak,
    this.isNewDay = false,
    this.isNewRecord = false,
    required this.multiplier,
  });
}

class StreakData {
  final int streak;
  final int bestStreak;
  final bool isActive;
  final bool ranToday;
  final double multiplier;

  const StreakData({
    required this.streak,
    required this.bestStreak,
    required this.isActive,
    required this.ranToday,
    required this.multiplier,
  });

  String get streakEmoji {
    if (streak >= 30) return '🏆';
    if (streak >= 14) return '🔥';
    if (streak >= 7) return '⚡';
    if (streak >= 3) return '✨';
    return '💪';
  }

  String get multiplierText => '${multiplier}x pontos';
}
