// lib/screens/battles_screen.dart
//
// Tela de Hotspots e Batalhas de Temporada

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/hotspot.dart';
import '../models/season_battle.dart';
import '../services/hotspot_service.dart';
import '../core/theme.dart';

class BattlesScreen extends StatefulWidget {
  const BattlesScreen({super.key});

  @override
  State<BattlesScreen> createState() => _BattlesScreenState();
}

class _BattlesScreenState extends State<BattlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = HotspotService.instance;

  List<Hotspot> _hotspots = [];
  List<SeasonBattle> _battles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hotspots = await _service.getActiveHotspots();
    final battles = await _service.getAllBattles();
    if (mounted) {
      setState(() {
        _hotspots = hotspots;
        _battles = battles;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('⚔️ Batalhas'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: '🔥 Hotspots'),
            Tab(text: '🏆 Temporadas'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _HotspotsTab(hotspots: _hotspots, onRefresh: _load),
                _BattlesTab(battles: _battles, onRefresh: _load),
              ],
            ),
    );
  }
}

// ─── Tab de Hotspots ──────────────────────────────────────────────────────────

class _HotspotsTab extends StatelessWidget {
  final List<Hotspot> hotspots;
  final VoidCallback onRefresh;

  const _HotspotsTab({required this.hotspots, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (hotspots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Nenhum hotspot ativo agora',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Novos hotspots aparecem toda hora!\nFique de olho no mapa.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: hotspots.length,
        itemBuilder: (ctx, i) =>
            _HotspotCard(hotspot: hotspots[i]).animate().slideX(
                  begin: 0.3,
                  delay: Duration(milliseconds: i * 80),
                ),
      ),
    );
  }
}

class _HotspotCard extends StatefulWidget {
  final Hotspot hotspot;
  const _HotspotCard({required this.hotspot});

  @override
  State<_HotspotCard> createState() => _HotspotCardState();
}

class _HotspotCardState extends State<_HotspotCard> {
  late String _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.hotspot.timeLeftText;
    // Atualiza o timer a cada segundo
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _timeLeft = widget.hotspot.timeLeftText);
      return widget.hotspot.isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hotspot;
    final color = _typeColor(h.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(h.typeEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          h.typeLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${h.pointsMultiplier}x pontos',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (h.isCaptured)
                    Text(
                      '✅ Capturado por ${h.capturedByName}',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 11),
                    )
                  else
                    Text(
                      '⏱️ Expira em $_timeLeft',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${h.radiusMeters.toStringAsFixed(0)}m',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
                const Text(
                  'raio',
                  style:
                      TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(HotspotType type) {
    switch (type) {
      case HotspotType.doublePoints: return Colors.yellow;
      case HotspotType.rareItem: return Colors.blue;
      case HotspotType.megaTerritory: return AppTheme.primary;
    }
  }
}

// ─── Tab de Batalhas ──────────────────────────────────────────────────────────

class _BattlesTab extends StatelessWidget {
  final List<SeasonBattle> battles;
  final VoidCallback onRefresh;

  const _BattlesTab({required this.battles, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (battles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nenhuma batalha ainda',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Batalhas de temporada acontecem\nnos finais de semana!',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: battles.length,
      itemBuilder: (ctx, i) => _BattleCard(battle: battles[i])
          .animate()
          .slideX(begin: 0.3, delay: Duration(milliseconds: i * 80)),
    );
  }
}

class _BattleCard extends StatelessWidget {
  final SeasonBattle battle;
  const _BattleCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final isActive = battle.isActive;
    final color = isActive ? AppTheme.primary : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive
                ? AppTheme.primary.withOpacity(0.5)
                : Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(battle.badgeEmoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        battle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        battle.regionName,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    battle.statusText,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress(battle),
                backgroundColor: Colors.white12,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏱️ ${battle.timeLeftText} restantes',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  if (battle.leaderName != null)
                    Text(
                      '👑 ${battle.leaderName}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                ],
              ),
            ],
            if (battle.isFinished && battle.leaderName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.gold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🥇', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      '${battle.leaderName} venceu!',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _progress(SeasonBattle b) {
    final total = b.endsAt.difference(b.startsAt).inSeconds;
    final elapsed = DateTime.now().difference(b.startsAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
