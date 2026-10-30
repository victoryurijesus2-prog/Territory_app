import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';
import '../models/player.dart';
import '../models/run_session.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/database_service.dart';
import '../services/xp_service.dart';
import '../models/xp_system.dart';
import '../widgets/level_up_dialog.dart';
import '../core/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseService.instance;
  final _achievements = AchievementService();
  Player? _player;
  List<Achievement> _achievementsList = [];
  List<RunSession> _recentRuns = [];
  int _xp = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = AuthService.userId;
    final player = await AuthService.getProfile(userId);
    final achievements = await _achievements.getAchievements(userId);
    final runs = await _db.getRunSessionsByUser(userId, limit: 5);
    final xp = await XpService.instance.getMyXp();
    if (mounted) setState(() { _player = player; _achievementsList = achievements; _recentRuns = runs; _xp = xp; _loading = false; });
  }

  Future<void> _editNickname() async {
    final ctrl = TextEditingController(text: _player?.nickname);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1E1E1E), title: const Text('Nickname', style: TextStyle(color: Colors.white)), content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Seu nickname'), autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Salvar'))]));
    if (result != null && result.isNotEmpty) { await AuthService.updateProfile(nickname: result); _load(); }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final path = 'avatars/${AuthService.userId}.jpg';
    try {
      await Supabase.instance.client.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      await AuthService.updateProfile(avatarUrl: url);
      _load();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar foto: $e'))); }
  }

  void _shareStats() {
    if (_player == null) return;
    Share.share('🏃 Estou no TerritoryApp!\n🗺️ ${_player!.territoryCount} territórios conquistados\n📐 ${_player!.formattedArea} de área\nBaixe e me desafie!');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    final level = XpSystem.getLevelForXp(_xp);
    final lColor = Color(int.parse('FF${level.color.replaceFirst('#', '')}', radix: 16));

    return Scaffold(backgroundColor: Colors.black, body: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Container(padding: const EdgeInsets.fromLTRB(24, 60, 24, 24), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.primary.withOpacity(0.2), Colors.transparent])), child: Column(children: [
        GestureDetector(onTap: _pickAvatar, child: Stack(children: [
          CircleAvatar(radius: 48, backgroundColor: AppTheme.primary.withOpacity(0.3), backgroundImage: _player?.avatarUrl != null ? CachedNetworkImageProvider(_player!.avatarUrl!) : null, child: _player?.avatarUrl == null ? Text(_player?.nickname.isNotEmpty == true ? _player!.nickname[0].toUpperCase() : '?', style: const TextStyle(fontSize: 36, color: Colors.white)) : null),
          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 16))),
        ])),
        const SizedBox(height: 12),
        GestureDetector(onTap: _editNickname, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_player?.nickname ?? 'Jogador', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(width: 6), const Icon(Icons.edit, color: Colors.white38, size: 16)])),
        const SizedBox(height: 8),
        // Nível
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: lColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: lColor.withOpacity(0.4))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(level.emoji), const SizedBox(width: 6), Text('Nível ${level.level} — ${level.title}', style: TextStyle(color: lColor, fontWeight: FontWeight.bold, fontSize: 13))])),
        const SizedBox(height: 16),
        XpProgressBar(xp: _xp),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatBadge(label: 'Territórios', value: '${_player?.territoryCount ?? 0}', icon: '🗺️'),
          _StatBadge(label: 'Área Total', value: _player?.formattedArea ?? '0 m²', icon: '📐'),
          _StatBadge(label: 'Corridas', value: '${_player?.runCount ?? 0}', icon: '🏃'),
        ]),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: _shareStats, icon: const Icon(Icons.share, size: 16), label: const Text('Compartilhar')),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: const Text('Conquistas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
      SliverToBoxAdapter(child: SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _achievementsList.length, itemBuilder: (ctx, i) {
        final a = _achievementsList[i];
        return Container(width: 80, margin: const EdgeInsets.only(right: 8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: a.isUnlocked ? AppTheme.primary.withOpacity(0.2) : Colors.white10, border: Border.all(color: a.isUnlocked ? AppTheme.primary : Colors.white12)), child: Center(child: Text(a.isUnlocked ? a.emoji : '🔒', style: const TextStyle(fontSize: 22)))),
          const SizedBox(height: 4),
          Text(a.title, style: TextStyle(color: a.isUnlocked ? Colors.white : Colors.white30, fontSize: 9), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]));
      }))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: const Text('Corridas Recentes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
      SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
        final r = _recentRuns[i];
        return Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle), child: Icon(r.isPersonalRecord == true ? Icons.star : Icons.directions_run, color: r.isPersonalRecord == true ? AppTheme.gold : AppTheme.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.formattedDistance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(r.formattedPace, style: const TextStyle(color: Colors.white38, fontSize: 12))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${r.estimatedCalories?.toStringAsFixed(0) ?? 0} kcal', style: const TextStyle(color: Colors.white60, fontSize: 13)), Text(r.startedAt != null ? '${r.startedAt!.day}/${r.startedAt!.month}' : '', style: const TextStyle(color: Colors.white30, fontSize: 11))]),
          ]));
      }, childCount: _recentRuns.length)),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: TextButton(onPressed: () async { await AuthService.signOut(); }, child: const Text('Sair da conta', style: TextStyle(color: Colors.red))))),
    ]));
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value, icon;
  const _StatBadge({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(children: [Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))]);
}
