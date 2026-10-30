import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/ranking_entry.dart';
import '../services/database_service.dart';
import '../core/theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseService.instance;
  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(title: const Text('🏆 Ranking'), bottom: TabBar(controller: _tabController, indicatorColor: AppTheme.primary, labelColor: AppTheme.primary, unselectedLabelColor: Colors.white38, tabs: const [Tab(text: 'Semana'), Tab(text: 'Mês'), Tab(text: 'Geral')])),
      body: TabBarView(controller: _tabController, children: [_RankingTab(period: RankingPeriod.weekly, db: _db), _RankingTab(period: RankingPeriod.monthly, db: _db), _RankingTab(period: RankingPeriod.allTime, db: _db)]));
  }
}

class _RankingTab extends StatelessWidget {
  final RankingPeriod period; final DatabaseService db;
  const _RankingTab({required this.period, required this.db});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingEntry>>(future: db.getRanking(period: period), builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      if (snap.hasError) return const Center(child: Text('Erro ao carregar ranking', style: TextStyle(color: Colors.white38)));
      final entries = snap.data ?? [];
      if (entries.isEmpty) return const Center(child: Text('Nenhum jogador ainda.\nSeja o primeiro! 🏃', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 16)));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: entries.length, itemBuilder: (context, i) {
        final e = entries[i];
        return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: e.position <= 3 ? AppTheme.primary.withOpacity(0.1) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: e.position <= 3 ? Border.all(color: AppTheme.primary.withOpacity(0.3)) : null),
          child: Row(children: [
            SizedBox(width: 40, child: Text(e.medal, style: TextStyle(fontSize: e.position <= 3 ? 22 : 16, fontWeight: FontWeight.bold, color: e.position <= 3 ? null : Colors.white38))),
            CircleAvatar(radius: 20, backgroundColor: AppTheme.primary.withOpacity(0.3), backgroundImage: e.avatarUrl != null ? CachedNetworkImageProvider(e.avatarUrl!) : null, child: e.avatarUrl == null ? Text(e.nickname.isNotEmpty ? e.nickname[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.nickname, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)), Text('${e.territoryCount} territórios', style: const TextStyle(color: Colors.white38, fontSize: 12))])),
            Text(e.formattedArea, style: TextStyle(color: e.position <= 3 ? AppTheme.primary : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]));
      });
    });
  }
}
