// lib/services/hotspot_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/hotspot.dart';
import '../models/season_battle.dart';
import '../utils/geo_utils.dart';

class HotspotService {
  static HotspotService get instance => _instance;
  static final HotspotService _instance = HotspotService._();
  HotspotService._();

  final _client = Supabase.instance.client;

  // ─── HOTSPOTS ─────────────────────────────────────────────────────────────

  Future<List<Hotspot>> getActiveHotspots() async {
    try {
      final data = await _client
          .from('hotspots')
          .select()
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('expires_at');
      return data.map((m) => Hotspot.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Verifica se o polígono capturado contém algum hotspot ativo
  Future<Hotspot?> checkHotspotCapture({
    required List<LatLng> polygon,
    required String userId,
    required String userName,
  }) async {
    final hotspots = await getActiveHotspots();

    for (final hotspot in hotspots) {
      if (hotspot.isCaptured) continue;
      final inside = GeoUtils.isPointInPolygon(hotspot.position, polygon);
      if (inside) {
        // Marca hotspot como capturado
        await _client.from('hotspots').update({
          'captured_by_user_id': userId,
          'captured_by_name': userName,
        }).eq('id', hotspot.id);
        return hotspot;
      }
    }
    return null;
  }

  Stream<List<Hotspot>> hotspotsStream() {
    return _client
        .from('hotspots')
        .stream(primaryKey: ['id'])
        .gt('expires_at', DateTime.now().toIso8601String())
        .map((rows) => rows
            .map((m) => Hotspot.fromMap(m))
            .where((h) => h.isActive)
            .toList());
  }

  // ─── BATALHAS DE TEMPORADA ────────────────────────────────────────────────

  Future<List<SeasonBattle>> getActiveBattles() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await _client
          .from('season_battles')
          .select()
          .lte('starts_at', now)
          .gte('ends_at', now)
          .order('ends_at');
      return data.map((m) => SeasonBattle.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SeasonBattle>> getAllBattles() async {
    try {
      final data = await _client
          .from('season_battles')
          .select()
          .order('starts_at', ascending: false)
          .limit(10);
      return data.map((m) => SeasonBattle.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── SQL para criar tabelas (copiar no Supabase) ──────────────────────────
  // Veja o arquivo supabase/hotspots_migration.sql
}
