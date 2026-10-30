// lib/widgets/result_dialog.dart

import 'package:flutter/material.dart';
import '../screens/share_screen.dart';
import '../services/territory_service.dart';
import '../core/theme.dart';

class ResultDialog extends StatelessWidget {
  final CaptureResult result;

  const ResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.success;
    final isSteal = result.stolenTerritory != null;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? (isSteal ? '⚔️' : '🏆') : _failIcon(result.reason),
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              isSuccess
                  ? (isSteal ? 'Território Roubado!' : 'Território Capturado!')
                  : _failTitle(result.reason),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            // Stats do território
            if (isSuccess && result.territory != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoChip(label: 'Área', value: result.territory!.formattedArea),
                    _InfoChip(label: 'Nível', value: result.territory!.levelName),
                    _InfoChip(
                        label: 'Pts/h',
                        value: '${result.territory!.pointsPerHour.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ],

            // Streak
            if (isSuccess && result.streakResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade800, Colors.deepOrange.shade900],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.streakResult!.streak >= 7 ? '🔥' : '✨',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${result.streakResult!.streak} dias seguidos!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Multiplicador: ${result.streakResult!.multiplier}x',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // PR
            if (result.isPersonalRecord) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: AppTheme.gold, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Novo Recorde Pessoal!',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Conquistas
            if (result.newAchievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: result.newAchievements
                    .map((a) => Chip(
                          avatar: Text(a.emoji),
                          label: Text(a.title,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppTheme.gold.withOpacity(0.15),
                          side: BorderSide(color: AppTheme.gold.withOpacity(0.4)),
                          labelStyle: const TextStyle(color: Colors.white),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Botões
            if (isSuccess && result.territory != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShareScreen(
                          session: result.territory != null
                              ? _emptySession()
                              : _emptySession(),
                          territory: result.territory!,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartilhar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cria sessão com dados do result para a tela de share
  RunSession _emptySession() {
    return RunSession(
      id: '',
      userId: '',
      avgSpeedKmh: 0,
      estimatedCalories: 0,
      pathLengthMeters: 0,
      isPersonalRecord: result.isPersonalRecord,
    );
  }

  String _failIcon(CaptureFailReason reason) {
    switch (reason) {
      case CaptureFailReason.fraud: return '🚫';
      case CaptureFailReason.pathNotClosed: return '🔄';
      case CaptureFailReason.overlapsExistingTerritory: return '⚠️';
      case CaptureFailReason.limitReached: return '📦';
      default: return '❌';
    }
  }

  String _failTitle(CaptureFailReason reason) {
    switch (reason) {
      case CaptureFailReason.fraud: return 'Trapaça Detectada';
      case CaptureFailReason.pathNotClosed: return 'Percurso Não Fechado';
      case CaptureFailReason.overlapsExistingTerritory: return 'Sobreposição';
      case CaptureFailReason.limitReached: return 'Limite Atingido';
      default: return 'Captura Falhou';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

