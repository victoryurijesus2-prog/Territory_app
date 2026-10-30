// lib/screens/clan_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/clan.dart';
import '../services/clan_service.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class ClanScreen extends StatefulWidget {
  const ClanScreen({super.key});

  @override
  State<ClanScreen> createState() => _ClanScreenState();
}

class _ClanScreenState extends State<ClanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ClanService.instance;
  Clan? _myClan;
  List<ClanMember> _members = [];
  List<Clan> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final clan = await _service.getMyClan();
    final ranking = await _service.getClanRanking();
    List<ClanMember> members = [];
    if (clan != null) {
      members = await _service.getClanMembers(clan.id);
    }
    if (mounted) {
      setState(() {
        _myClan = clan;
        _members = members;
        _ranking = ranking;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('👥 Clãs'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Meu Clã'),
            Tab(text: 'Ranking'),
            Tab(text: 'Buscar'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _MyClanTab(
                    clan: _myClan,
                    members: _members,
                    onRefresh: _load,
                    service: _service),
                _ClanRankingTab(ranking: _ranking),
                _SearchClanTab(service: _service, onJoin: _load),
              ],
            ),
    );
  }
}

// ─── Meu Clã ─────────────────────────────────────────────────────────────────

class _MyClanTab extends StatelessWidget {
  final Clan? clan;
  final List<ClanMember> members;
  final VoidCallback onRefresh;
  final ClanService service;

  const _MyClanTab({
    required this.clan,
    required this.members,
    required this.onRefresh,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (clan == null) {
      return _NoClanView(onRefresh: onRefresh);
    }

    final color = _hexToColor(clan!.color);
    final isLeader = clan!.leaderId == AuthService.userId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header do clã
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(
                '[${clan!.tag}]',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                clan!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (clan!.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  clan!.description!,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ClanStat(
                      label: 'Membros',
                      value: '${clan!.memberCount}',
                      icon: '👥'),
                  _ClanStat(
                      label: 'Área Total',
                      value: clan!.formattedArea,
                      icon: '📐'),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Membros
        const Text(
          'Membros',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...members.map((m) => _MemberCard(
              member: m,
              isLeader: isLeader,
              clanId: clan!.id,
              service: service,
              onKick: onRefresh,
            )),

        const SizedBox(height: 16),

        // Botão sair
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text('Sair do clã?',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Tem certeza que quer sair do clã?',
                  style: TextStyle(color: Colors.white54),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sair',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await service.leaveClan();
              onRefresh();
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red30),
          ),
          icon: const Icon(Icons.exit_to_app, size: 16),
          label: const Text('Sair do Clã'),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _MemberCard extends StatelessWidget {
  final ClanMember member;
  final bool isLeader;
  final String clanId;
  final ClanService service;
  final VoidCallback onKick;

  const _MemberCard({
    required this.member,
    required this.isLeader,
    required this.clanId,
    required this.service,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withOpacity(0.3),
            backgroundImage: member.avatarUrl != null
                ? CachedNetworkImageProvider(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.nickname.isNotEmpty
                        ? member.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.nickname,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 4),
                      const Text('👑',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                Text(
                  '${(member.totalAreaM2 / 1000).toStringAsFixed(1)}k m²',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isLeader &&
              !member.isLeader &&
              member.userId != AuthService.userId)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 18),
              onPressed: () async {
                await service.kickMember(member.userId, clanId);
                onKick();
              },
            ),
        ],
      ),
    );
  }
}

class _NoClanView extends StatefulWidget {
  final VoidCallback onRefresh;
  const _NoClanView({required this.onRefresh});

  @override
  State<_NoClanView> createState() => _NoClanViewState();
}

class _NoClanViewState extends State<_NoClanView> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedColor = '#FF5722';
  bool _creating = false;

  static const List<String> _colors = [
    '#FF5722', '#2196F3', '#4CAF50', '#9C27B0',
    '#FF9800', '#00BCD4', '#F44336', '#E91E63',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.isEmpty || _tagCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e tag')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      await ClanService.instance.createClan(
        name: _nameCtrl.text.trim(),
        tag: _tagCtrl.text.trim().toUpperCase(),
        color: _selectedColor,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('👥', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Você não tem clã',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Crie seu clã ou busque um para entrar',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text('Criar Clã', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Nome do clã'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tagCtrl,
            style: const TextStyle(color: Colors.white),
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Tag (ex: TER)',
              helperText: 'Máx 4 letras',
              helperStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
          ),
          const SizedBox(height: 16),
          const Text('Cor do clã', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colors.map((c) {
              final color = Color(int.parse('FF${c.replaceFirst('#', '')}', radix: 16));
              final selected = c == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Criar Clã'),
          ),
        ],
      ),
    );
  }
}

// ─── Ranking de clãs ─────────────────────────────────────────────────────────

class _ClanRankingTab extends StatelessWidget {
  final List<Clan> ranking;
  const _ClanRankingTab({required this.ranking});

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) {
      return const Center(
        child: Text('Nenhum clã ainda.\nCrie o primeiro! 👥',
            style: TextStyle(color: Colors.white38), textAlign: TextAlign.center),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (ctx, i) {
        final clan = ranking[i];
        final color = Color(int.parse('FF${clan.color.replaceFirst('#', '')}', radix: 16));
        final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '#${i + 1}';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i < 3 ? color.withOpacity(0.1) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: i < 3 ? Border.all(color: color.withOpacity(0.3)) : null,
          ),
          child: Row(
            children: [
              Text(medal, style: TextStyle(fontSize: i < 3 ? 22 : 14, color: Colors.white38)),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('[${clan.tag}] ${clan.name}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${clan.memberCount} membros', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Text(clan.formattedArea,
                  style: TextStyle(color: i < 3 ? color : Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate().slideX(begin: 0.3, delay: Duration(milliseconds: i * 60));
      },
    );
  }
}

// ─── Buscar clã ───────────────────────────────────────────────────────────────

class _SearchClanTab extends StatefulWidget {
  final ClanService service;
  final VoidCallback onJoin;
  const _SearchClanTab({required this.service, required this.onJoin});

  @override
  State<_SearchClanTab> createState() => _SearchClanTabState();
}

class _SearchClanTabState extends State<_SearchClanTab> {
  final _ctrl = TextEditingController();
  List<Clan> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _loading = true);
    final results = await widget.service.searchClans(q.trim());
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  Future<void> _join(Clan clan) async {
    try {
      await widget.service.joinClan(clan.id);
      widget.onJoin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrou no clã ${clan.name}! 👥'), backgroundColor: Colors.green),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar clã...',
              hintStyle: const TextStyle(color: Colors.white38),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.primary),
                onPressed: () => _search(_ctrl.text),
              ),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _results.isEmpty
                  ? const Center(child: Text('Busque um clã para entrar', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final clan = _results[i];
                        final color = Color(int.parse('FF${clan.color.replaceFirst('#', '')}', radix: 16));
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 40,
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('[${clan.tag}] ${clan.name}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text('${clan.memberCount} membros • ${clan.formattedArea}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _join(clan),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                child: const Text('Entrar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ClanStat extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _ClanStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
