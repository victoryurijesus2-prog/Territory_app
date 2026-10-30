// lib/widgets/level_up_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/xp_system.dart';
import '../core/theme.dart';

class LevelUpDialog extends StatefulWidget {
  final PlayerLevel newLevel;
  final int xpGained;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.xpGained,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(
        'FF${widget.newLevel.color.replaceFirst('#', '')}',
        radix: 16));

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone animado
                Text(
                  widget.newLevel.emoji,
                  style: const TextStyle(fontSize: 64),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .shimmer(duration: 1000.ms),

                const SizedBox(height: 8),

                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 4),

                Text(
                  'Nível ${widget.newLevel.level}',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                Text(
                  widget.newLevel.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),

                // XP ganho
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${widget.xpGained} XP',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 20),

                // Perks desbloqueados
                if (widget.newLevel.perks.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎁 Perks desbloqueados:',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.newLevel.perks.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Text('✓ ',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.3, delay: 700.ms),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Incrível! 🚀'),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),

        // Confetti
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: [color, AppTheme.gold, Colors.white, AppTheme.primary],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }
}

// Widget de XP inline para o perfil
class XpProgressBar extends StatelessWidget {
  final int xp;
  final bool showDetails;

  const XpProgressBar({super.key, required this.xp, this.showDetails = true});

  @override
  Widget build(BuildContext context) {
    final level = XpSystem.getLevelForXp(xp);
    final next = XpSystem.getNextLevel(xp);
    final progress = XpSystem.getProgressToNextLevel(xp);
    final color = Color(
        int.parse('FF${level.color.replaceFirst('#', '')}', radix: 16));

    return Column(
      children: [
        Row(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nível ${level.level}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      level.title,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                if (showDetails && next != null)
                  Text(
                    '${XpSystem.getXpToNextLevel(xp)} XP para ${next.title}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              '$xp XP',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
