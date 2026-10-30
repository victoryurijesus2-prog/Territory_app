import 'package:flutter/material.dart';
import '../models/run_session.dart';
import '../core/theme.dart';

class StatsPanel extends StatelessWidget {
  final RunSession session;
  final bool isRunning;
  const StatsPanel({super.key, required this.session, this.isRunning = false});

  @override
  Widget build(BuildContext context) {
    final duration = session.startedAt != null ? DateTime.now().difference(session.startedAt!) : Duration.zero;
    final distKm = (session.pathLengthMeters ?? 0) / 1000;
    final avgSpeed = session.avgSpeedKmh ?? 0;
    final calories = session.estimatedCalories ?? 0;
    final pace = session.paceMinPerKm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 1))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
        if (isRunning) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)), const SizedBox(width: 6), Text('GPS ativo — ${session.path.length} pontos', style: const TextStyle(color: Colors.white54, fontSize: 11))]),
        if (isRunning) const SizedBox(height: 12),
        Row(children: [
          _StatItem(label: 'TEMPO', value: _formatDuration(duration), icon: Icons.timer_outlined),
          _divider(),
          _StatItem(label: 'DISTÂNCIA', value: distKm >= 1 ? '${distKm.toStringAsFixed(2)} km' : '${(session.pathLengthMeters ?? 0).toStringAsFixed(0)} m', icon: Icons.straighten),
          _divider(),
          _StatItem(label: 'VEL. MÉD.', value: '${avgSpeed.toStringAsFixed(1)} km/h', icon: Icons.speed, highlight: avgSpeed > 12),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatItem(label: 'RITMO', value: _formatPace(pace), icon: Icons.directions_run),
          _divider(),
          _StatItem(label: 'CALORIAS', value: '${calories.toStringAsFixed(0)} kcal', icon: Icons.local_fire_department, highlight: calories > 200),
        ]),
      ]),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 4));
  String _formatDuration(Duration d) { final h = d.inHours; final m = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return h > 0 ? '$h:$m:$s' : '$m:$s'; }
  String _formatPace(double? pace) { if (pace == null || pace <= 0) return '--:--'; final min = pace.floor(); final sec = ((pace - min) * 60).round(); return '$min:${sec.toString().padLeft(2, '0')} /km'; }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  const _StatItem({required this.label, required this.value, required this.icon, this.highlight = false});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Icon(icon, size: 16, color: highlight ? AppTheme.primary : Colors.white38), const SizedBox(height: 4), Text(value, style: TextStyle(color: highlight ? AppTheme.primary : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9))]));
}
