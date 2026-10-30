// lib/screens/share_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/run_session.dart';
import '../models/territory.dart';
import '../services/streak_service.dart';
import '../core/theme.dart';

class ShareScreen extends StatefulWidget {
  final RunSession session;
  final Territory territory;

  const ShareScreen({
    super.key,
    required this.session,
    required this.territory,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _repaintKey = GlobalKey();
  StreakData? _streakData;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final data = await StreakService.instance.getStreak();
    if (mounted) setState(() => _streakData = data);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // pixelRatio alto para qualidade boa no Stories
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/territory_run.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🏃 Acabei de conquistar um território no TerritoryApp!\n'
            '📐 ${widget.territory.formattedArea} capturados\n'
            '🔥 ${_streakData?.streak ?? 0} dias seguidos\n'
            'Baixe e me desafie! #TerritoryApp',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Compartilhar'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: _ShareCard(
                  session: widget.session,
                  territory: widget.territory,
                  streakData: _streakData,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            child: Column(
              children: [
                const Text(
                  'A imagem será salva com fundo transparente ✨',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share),
                    label: Text(_sharing ? 'Preparando...' : 'Compartilhar'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar',
                      style: TextStyle(color: Colors.white38)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final RunSession session;
  final Territory territory;
  final StreakData? streakData;

  const _ShareCard({
    required this.session,
    required this.territory,
    required this.streakData,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(territory.color);

    // Fundo TRANSPARENTE — só elementos flutuantes visíveis
    return Container(
      width: 360,
      color: Colors.transparent, // <- fundo transparente
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini mapa com bordas arredondadas e brilho
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.8), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: _MiniMap(territory: territory, color: color),
          ),

          const SizedBox(height: 16),

          // Card de stats com fundo semi-transparente escuro
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.terrain,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TerritoryApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: color.withOpacity(0.6)),
                      ),
                      child: Text(
                        territory.levelName,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Área em destaque
                Text(
                  territory.formattedArea,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'conquistados',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 12),

                // Stats grid
                Row(
                  children: [
                    _StatPill(
                        icon: '🏃',
                        value: session.formattedDistance),
                    const SizedBox(width: 8),
                    _StatPill(
                        icon: '⚡',
                        value:
                            '${(session.avgSpeedKmh ?? 0).toStringAsFixed(1)} km/h'),
                    const SizedBox(width: 8),
                    _StatPill(
                        icon: '🔥',
                        value:
                            '${(session.estimatedCalories ?? 0).toStringAsFixed(0)} kcal'),
                  ],
                ),

                const SizedBox(height: 10),

                // Footer: streak + PR + data
                Row(
                  children: [
                    if (streakData != null && streakData!.streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.orange.shade800,
                            Colors.deepOrange.shade900,
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 ${streakData!.streak} dias',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (session.isPersonalRecord == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.gold.withOpacity(0.5)),
                        ),
                        child: const Text(
                          '⭐ PR',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(territory.capturedAt),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String value;

  const _StatPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  final Territory territory;
  final Color color;

  const _MiniMap({required this.territory, required this.color});

  @override
  Widget build(BuildContext context) {
    if (territory.polygon.isEmpty) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 40))),
      );
    }

    final lat = territory.polygon
            .map((p) => p.latitude)
            .reduce((a, b) => a + b) /
        territory.polygon.length;
    final lng = territory.polygon
            .map((p) => p.longitude)
            .reduce((a, b) => a + b) /
        territory.polygon.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(lat, lng),
        initialZoom: 16,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.territory.app',
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: territory.polygon,
              color: color.withOpacity(0.45),
              borderColor: color,
              borderStrokeWidth: 3,
            ),
          ],
        ),
      ],
    );
  }
}
