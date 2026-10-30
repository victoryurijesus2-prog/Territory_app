// lib/widgets/streak_widget.dart
//
// Widget do streak exibido no perfil e no mapa

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/streak_service.dart';
import '../core/theme.dart';

class StreakBadge extends StatelessWidget {
  final StreakData data;
  final bool large;

  const StreakBadge({super.key, required this.data, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (!data.isActive && data.streak == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(large ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.streakEmoji,
            style: TextStyle(fontSize: large ? 22 : 16),
          ),
          SizedBox(width: large ? 8 : 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data.streak} dias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 16 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (large)
                Text(
                  data.multiplierText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }
}

class StreakToast extends StatelessWidget {
  final StreakResult result;

  const StreakToast({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade800,
            Colors.deepOrange.shade900,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            result.streak >= 7 ? '🔥' : '✨',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.isNewRecord
                      ? '🏆 Novo recorde de streak!'
                      : '${result.streak} dias seguidos!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Multiplicador: ${result.multiplier}x pontos',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -1, duration: 400.ms, curve: Curves.easeOut)
        .then(delay: 2500.ms)
        .slideY(end: -1, duration: 300.ms, curve: Curves.easeIn);
  }
}

void showStreakToast(BuildContext context, StreakResult result) {
  if (!result.isNewDay) return;
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: StreakToast(result: result),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 3400), entry.remove);
}
