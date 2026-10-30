// lib/services/clan_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/clan.dart';
import 'auth_service.dart';

class ClanService {
  static ClanService get instance => _instance;
  static final ClanService _instance = ClanService._();
  ClanService._();

  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─── Buscar clã do usuário ────────────────────────────────────────────────

  Future<Clan?> getMyClan() async {
    try {
      final userId = AuthService.userId;
      final member = await _client
          .from('clan_members')
          .select('clan_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null) return null;

      final clan = await _client
          .from('clans')
          .select()
          .eq('id', member['clan_id'])
          .maybeSingle();

      return clan != null ? Clan.fromMap(clan) : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Criar clã ────────────────────────────────────────────────────────────

  Future<Clan> createClan({
    required String name,
    required String tag,
    required String color,
    String? description,
  }) async {
    final userId = AuthService.userId;
    final userName = AuthService.currentUser?.userMetadata?['full_name'] ??
        AuthService.currentUser?.email?.split('@').first ??
        'Líder';

    final clan = Clan(
      id: _uuid.v4(),
      name: name,
      tag: tag,
      color: color,
      leaderId: userId,
      leaderName: userName,
      description: description,
      createdAt: DateTime.now(),
    );

    await _client.from('clans').insert(clan.toMap());

    await _client.from('clan_members').insert({
      'user_id': userId,
      'clan_id': clan.id,
      'role': 'leader',
      'nickname': userName,
      'joined_at': DateTime.now().toIso8601String(),
    });

    // Atualiza perfil com clan_id
    await _client
        .from('profiles')
        .update({'clan_id': clan.id, 'clan_tag': tag, 'clan_color': color})
        .eq('id', userId);

    return clan;
  }

  // ─── Entrar em clã ────────────────────────────────────────────────────────

  Future<void> joinClan(String clanId) async {
    final userId = AuthService.userId;
    final userName = AuthService.currentUser?.userMetadata?['full_name'] ??
        AuthService.currentUser?.email?.split('@').first ??
        'Jogador';

    // Verifica se já está em algum clã
    final existing = await _client
        .from('clan_members')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) throw Exception('Você já pertence a um clã!');

    await _client.from('clan_members').insert({
      'user_id': userId,
      'clan_id': clanId,
      'role': 'member',
      'nickname': userName,
      'joined_at': DateTime.now().toIso8601String(),
    });

    final clan = await _client
        .from('clans')
        .select()
        .eq('id', clanId)
        .maybeSingle();

    if (clan != null) {
      await _client.from('profiles').update({
        'clan_id': clanId,
        'clan_tag': clan['tag'],
        'clan_color': clan['color'],
      }).eq('id', userId);
    }
  }

  // ─── Sair do clã ─────────────────────────────────────────────────────────

  Future<void> leaveClan() async {
    final userId = AuthService.userId;
    await _client
        .from('clan_members')
        .delete()
        .eq('user_id', userId);
    await _client
        .from('profiles')
        .update({'clan_id': null, 'clan_tag': null, 'clan_color': null})
        .eq('id', userId);
  }

  // ─── Membros do clã ───────────────────────────────────────────────────────

  Future<List<ClanMember>> getClanMembers(String clanId) async {
    try {
      final data = await _client
          .from('clan_members')
          .select('*, profiles(nickname, avatar_url, total_area_m2)')
          .eq('clan_id', clanId)
          .order('role');

      return data.map((m) {
        final profile = m['profiles'] as Map<String, dynamic>? ?? {};
        return ClanMember.fromMap({
          ...m,
          'nickname': profile['nickname'],
          'avatar_url': profile['avatar_url'],
          'total_area_m2': profile['total_area_m2'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Ranking de clãs ─────────────────────────────────────────────────────

  Future<List<Clan>> getClanRanking() async {
    try {
      final data = await _client
          .from('clans')
          .select()
          .order('total_area_m2', ascending: false)
          .limit(50);
      return data.map((m) => Clan.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Buscar clãs ─────────────────────────────────────────────────────────

  Future<List<Clan>> searchClans(String query) async {
    try {
      final data = await _client
          .from('clans')
          .select()
          .ilike('name', '%$query%')
          .limit(20);
      return data.map((m) => Clan.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Expulsar membro (só líder) ───────────────────────────────────────────

  Future<void> kickMember(String memberId, String clanId) async {
    await _client
        .from('clan_members')
        .delete()
        .eq('user_id', memberId)
        .eq('clan_id', clanId);
    await _client
        .from('profiles')
        .update({'clan_id': null, 'clan_tag': null, 'clan_color': null})
        .eq('id', memberId);
  }
}
