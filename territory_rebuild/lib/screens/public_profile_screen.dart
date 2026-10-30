// lib/screens/public_profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';
import '../models/territory.dart';
import '../models/achievement.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/database_service.dart';
import '../core/theme.dart';

class PublicProfileScreen extends StatefulWidget {
  final Player player;
  const PublicProfileScreen({super.key, required this.player});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  List<Territory> _territories = [];
  List<Achievement> _achievements = [];
  bool _loading = true;
  bool _challengeSent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final territories = await DatabaseService.instance
        .getTerritoriesByOwner(widget.player.id);
    final achievements =
        await AchievementService().getAchievements(widget.player.id);
    if (mounted) {
      setState(() {
        _territories = territories;
        _achievements = achievements;
        _loading = false;
      });
    }
  }

  Future<void> _sendChallenge() async {
    final myId = AuthService.userId;
    final myName = AuthService.currentUser?.userMetadata?['full_name'] ??
        AuthService.currentUser?.email?.split('@').first ??
        'Jogador';

    try {
      await Supabase.instance.client.from('challenges').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'challenger_id': myId,
        'challenger_name': myName,
        'challenged_id': widget.player.id,
        'challenged_name': widget.player.nickname,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() => _challengeSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('⚔️ Desafio enviado para ${widget.player.nickname}!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.player.id == AuthService.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Botão voltar
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primary.withOpacity(0.3),
                    backgroundImage: widget.player.avatarUrl != null
                        ? CachedNetworkImageProvider(widget.player.avatarUrl!)
                        : null,
                    child: widget.player.avatarUrl == null
                        ? Text(
                            widget.player.nickname.isNotEmpty
                                ? widget.player.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 32, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    widget.player.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBadge(
                          label: 'Territórios',
                          value: '${widget.player.territoryCount}',
                          icon: '🗺️'),
                      _StatBadge(
                          label: 'Área',
                          value: widget.player.formattedArea,
                          icon: '📐'),
                      _StatBadge(
                          label: 'Corridas',
                          value: '${widget.player.runCount}',
                          icon: '🏃'),
                    ],
                  ),

                  // Botão desafiar (só para outros jogadores)
                  if (!isMe) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _challengeSent ? null : _sendChallenge,
                        icon: Icon(
                            _challengeSent ? Icons.check : Icons.sports_mma),
                        label: Text(
                          _challengeSent
                              ? 'Desafio Enviado!'
                              : '⚔️ Desafiar ${widget.player.nickname}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _challengeSent
                              ? Colors.green
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Conquistas
          if (!_loading) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Conquistas (${_achievements.where((a) => a.isUnlocked).length}/${_achievements.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _achievements.length,
                  itemBuilder: (ctx, i) {
                    final a = _achievements[i];
                    return Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: a.isUnlocked
                                  ? AppTheme.primary.withOpacity(0.2)
                                  : Colors.white10,
                              border: Border.all(
                                color: a.isUnlocked
                                    ? AppTheme.primary
                                    : Colors.white12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                a.isUnlocked ? a.emoji : '🔒',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.title,
                            style: TextStyle(
                              color: a.isUnlocked
                                  ? Colors.white
                                  : Colors.white30,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Territórios
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Territórios (${_territories.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            _territories.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhum território ainda',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = _territories[i];
                        final color = _hexToColor(t.color);
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.formattedArea,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      t.levelName,
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${t.capturedAt.day}/${t.capturedAt.month}',
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: _territories.length,
                    ),
                  ),
          ],

          if (_loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child:
                      CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatBadge(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
