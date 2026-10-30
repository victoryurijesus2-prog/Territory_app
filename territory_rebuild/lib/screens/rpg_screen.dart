// lib/screens/rpg_screen.dart
// Tela de Nível, XP e Perks

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/xp_system.dart';
import '../services/xp_service.dart';
import '../widgets/level_up_dialog.dart';
import '../core/theme.dart';

class RpgScreen extends StatefulWidget {
  const RpgScreen({super.key});

  @override
  State<RpgScreen> createState() => _RpgScreenState();
}

class _RpgScreenState extends State<RpgScreen> {
  int _xp = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final xp = await XpService.instance.getMyXp();
    if (mounted) setState(() { _xp = xp; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final level = XpSystem.getLevelForXp(_xp);
    final color = Color(int.parse('FF${level.color.replaceFirst('#', '')}', radix: 16));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('🎮 Treinador'), backgroundColor: Colors.black),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card do nível atual
          Container(
            padding: const EdgeInsets.all(24),
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
                Text(level.emoji, style: const TextStyle(fontSize: 56))
                    .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 8),
                Text(
                  'Nível ${level.level} — ${level.title}',
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                XpProgressBar(xp: _xp),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // Perks do nível atual
          const Text('⚡ Perks Ativos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...level.perks.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          ).animate().slideX(begin: 0.2)),

          const SizedBox(height: 24),

          // Todos os níveis
          const Text('🏆 Jornada de Níveis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...XpSystem.levels.map((l) {
            final isUnlocked = _xp >= l.xpRequired;
            final isCurrent = l.level == level.level;
            final lColor = Color(int.parse('FF${l.color.replaceFirst('#', '')}', radix: 16));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? lColor.withOpacity(0.15)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(color: lColor.withOpacity(0.6), width: 2)
                    : Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Text(
                    isUnlocked ? l.emoji : '🔒',
                    style: TextStyle(fontSize: 24, color: isUnlocked ? null : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nível ${l.level} — ${l.title}',
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'ATUAL',
                                  style: TextStyle(color: lColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          isUnlocked ? '${l.xpRequired} XP' : 'Faltam ${l.xpRequired - _xp} XP',
                          style: TextStyle(
                            color: isUnlocked ? Colors.white38 : Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (l.perks.isNotEmpty)
                    Text(
                      '${l.perks.length} perks',
                      style: TextStyle(
                        color: isUnlocked ? lColor : Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ).animate().slideX(begin: 0.2, delay: Duration(milliseconds: l.level * 50));
          }),
        ],
      ),
    );
  }
}
