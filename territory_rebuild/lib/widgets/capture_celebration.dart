import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement.dart';
import '../core/theme.dart';

class CaptureCelebration extends StatefulWidget {
  final bool isSteal;
  const CaptureCelebration({super.key, this.isSteal = false});
  @override
  State<CaptureCelebration> createState() => _CaptureCelebrationState();
}

class _CaptureCelebrationState extends State<CaptureCelebration> {
  late ConfettiController _confettiController;
  @override
  void initState() { super.initState(); _confettiController = ConfettiController(duration: const Duration(seconds: 3)); _confettiController.play(); }
  @override
  void dispose() { _confettiController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Stack(children: [
    Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, colors: const [AppTheme.primary, AppTheme.secondary, AppTheme.gold, Colors.white, Colors.pink, Colors.green], numberOfParticles: 40, gravity: 0.3)),
    Center(child: Text(widget.isSteal ? '⚔️' : '🏆', style: const TextStyle(fontSize: 72)).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut).then().shake(duration: 300.ms)),
  ]);
}

class AchievementToast extends StatelessWidget {
  final Achievement achievement;
  const AchievementToast({super.key, required this.achievement});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.2), AppTheme.primary.withOpacity(0.2)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.gold.withOpacity(0.5)), boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.2), blurRadius: 16, spreadRadius: 2)]),
    child: Row(children: [Text(achievement.emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('Conquista Desbloqueada!', style: TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)), Text(achievement.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)), Text(achievement.description, style: const TextStyle(color: Colors.white54, fontSize: 12))]))]),
  ).animate().slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut).then(delay: 2500.ms).slideY(end: -1, duration: 300.ms, curve: Curves.easeIn);
}

void showAchievementToasts(BuildContext context, List<Achievement> achievements) {
  if (achievements.isEmpty) return;
  for (int i = 0; i < achievements.length; i++) {
    Future.delayed(Duration(milliseconds: i * 3500), () {
      if (!context.mounted) return;
      late OverlayEntry entry;
      entry = OverlayEntry(builder: (ctx) => Positioned(top: 60, left: 0, right: 0, child: AchievementToast(achievement: achievements[i])));
      Overlay.of(context).insert(entry);
      Future.delayed(const Duration(milliseconds: 3400), entry.remove);
    });
  }
}
