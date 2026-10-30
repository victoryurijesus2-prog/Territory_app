// lib/screens/search_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';
import '../core/theme.dart';
import 'public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _client = Supabase.instance.client;
  List<Player> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _searched = true; });

    try {
      final data = await _client
          .from('profiles')
          .select()
          .ilike('nickname', '%${query.trim()}%')
          .limit(20);
      setState(() => _results = data.map((m) => Player.fromMap(m)).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar jogador...',
            hintStyle: const TextStyle(color: Colors.white38),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white38),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() { _results = []; _searched = false; });
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() {}),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primary),
            onPressed: () => _search(_ctrl.text),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : !_searched
              ? _buildSuggestions()
              : _results.isEmpty
                  ? _buildEmpty()
                  : _buildResults(),
    );
  }

  Widget _buildSuggestions() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Busque por nickname',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encontre jogadores e veja\nseus territórios',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Nenhum jogador com "${_ctrl.text}"',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente outro nickname',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final player = _results[i];
        return _PlayerCard(player: player)
            .animate()
            .slideX(begin: 0.3, delay: Duration(milliseconds: i * 60));
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(player: player),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withOpacity(0.3),
              backgroundImage: player.avatarUrl != null
                  ? CachedNetworkImageProvider(player.avatarUrl!)
                  : null,
              child: player.avatarUrl == null
                  ? Text(
                      player.nickname.isNotEmpty
                          ? player.nickname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${player.territoryCount} territórios • ${player.formattedArea}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
