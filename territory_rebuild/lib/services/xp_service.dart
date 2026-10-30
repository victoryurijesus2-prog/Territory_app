// lib/services/xp_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/xp_system.dart';
import 'auth_service.dart';

class XpService {
  static XpService get instance => _instance;
  static final XpService _instance = XpService._();
  XpService._();

  final _client = Supabase.instance.client;

  // ─── Buscar XP atual ──────────────────────────────────────────────────────

  Future<int> getMyXp() async {
    try {
      final data = await _client
          .from('profiles')
          .select('xp')
          .eq('id', AuthService.userId)
          .maybeSingle();
      return (data?['xp'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Adicionar XP ─────────────────────────────────────────────────────────

  Future<XpGainResult> addXp({
    required int xpAmount,
    required String reason,
  }) async {
    try {
      final currentXp = await getMyXp();
      final newXp = currentXp + xpAmount;

      await _client
          .from('profiles')
          .update({'xp': newXp})
          .eq('id', AuthService.userId);

      final oldLevel = XpSystem.getLevelForXp(currentXp);
      final newLevel = XpSystem.getLevelForXp(newXp);
      final leveledUp = newLevel.level > oldLevel.level;

      return XpGainResult(
        xpGained: xpAmount,
        totalXp: newXp,
        oldLevel: oldLevel,
        newLevel: newLevel,
        leveledUp: leveledUp,
        reason: reason,
      );
    } catch (e) {
      return XpGainResult(
        xpGained: 0,
        totalXp: 0,
        oldLevel: XpSystem.levels.first,
        newLevel: XpSystem.levels.first,
        leveledUp: false,
        reason: reason,
      );
    }
  }

  // ─── XP de uma corrida completa ───────────────────────────────────────────

  Future<XpGainResult> addRunXp({
    required double distanceKm,
    required bool capturedTerritory,
    required bool stoledTerritory,
    required bool capturedHotspot,
    required int newAchievements,
    required double streakMultiplier,
  }) async {
    final xp = XpSystem.calculateRunXp(
      distanceKm: distanceKm,
      capturedTerritory: capturedTerritory,
      stoledTerritory: stoledTerritory,
      capturedHotspot: capturedHotspot,
      newAchievements: newAchievements,
      streakMultiplier: streakMultiplier,
    );

    return addXp(xpAmount: xp, reason: 'Corrida completada');
  }
}

class XpGainResult {
  final int xpGained;
  final int totalXp;
  final PlayerLevel oldLevel;
  final PlayerLevel newLevel;
  final bool leveledUp;
  final String reason;

  const XpGainResult({
    required this.xpGained,
    required this.totalXp,
    required this.oldLevel,
    required this.newLevel,
    required this.leveledUp,
    required this.reason,
  });
}
