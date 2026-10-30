import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/territory.dart';
import '../models/run_session.dart';
import '../services/auth_service.dart';
import '../services/territory_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/stats_panel.dart';
import '../widgets/capture_celebration.dart';
import '../widgets/result_dialog.dart';
import '../core/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  late final TerritoryService _service;
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(-15.7942, -47.8822);
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _isCentered = true;
  bool _showCelebration = false;
  bool _isStealCelebration = false;
  RunStatus _runStatus = RunStatus.idle;
  List<LatLng> _currentPath = [];
  List<Territory> _territories = [];
  Timer? _statsTimer;
  double _currentSpeedKmh = 0;
  double _totalDistanceMeters = 0;
  Duration _elapsed = Duration.zero;
  DateTime? _runStartTime;
  StreamSubscription<List<Territory>>? _territoriesSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = TerritoryService(onPositionUpdate: _onPositionUpdate, onError: (msg) => _showSnack(msg, isError: true));
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    _hasPermission = await TerritoryService.requestLocationPermission();
    if (_hasPermission) {
      try { final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high); _currentPosition = LatLng(pos.latitude, pos.longitude); } catch (_) {}
    }
    _territoriesSubscription = _service.territoriesStream.listen((t) { if (mounted) setState(() => _territories = t); });
    setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _mapController.move(_currentPosition, 17.0));
  }

  void _onPositionUpdate(LatLng position) {
    if (!mounted) return;
    setState(() {
      _currentPath = List.from(_service.currentSession?.path ?? []);
      _totalDistanceMeters = GeoUtils.pathLengthMeters(_currentPath);
      _currentPosition = position;
      if (_currentPath.length >= 2) {
        final session = _service.currentSession;
        if (session != null && session.timestamps.length >= 2) {
          final dist = GeoUtils.distanceMeters(session.path[session.path.length - 2], session.path.last);
          final secs = session.timestamps.last.difference(session.timestamps[session.timestamps.length - 2]).inMilliseconds / 1000.0;
          if (secs > 0) _currentSpeedKmh = (dist / secs) * 3.6;
        }
      }
    });
    if (_isCentered) _mapController.move(position, _mapController.camera.zoom);
  }

  Future<void> _startRun() async {
    if (!_hasPermission) { _showSnack('Permissão de localização necessária.', isError: true); return; }
    try { await _service.startRun(AuthService.userId); } catch (e) { _showSnack(e.toString(), isError: true); return; }
    _runStartTime = DateTime.now();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (_runStartTime != null && mounted) setState(() => _elapsed = DateTime.now().difference(_runStartTime!)); });
    setState(() { _runStatus = RunStatus.running; _currentPath = []; _elapsed = Duration.zero; _isCentered = true; });
    _showSnack('Corrida iniciada! 🏃 Corra para capturar território');
  }

  Future<void> _finishRun() async {
    _statsTimer?.cancel();
    setState(() => _isLoading = true);
    final result = await _service.finishRunAndCapture(
      userId: AuthService.userId,
      userName: AuthService.currentUser?.userMetadata?['full_name'] ?? AuthService.currentUser?.email?.split('@').first ?? 'Jogador',
      userAvatarUrl: AuthService.currentUser?.userMetadata?['avatar_url'],
    );
    if (mounted) {
      setState(() { _runStatus = RunStatus.idle; _currentPath = []; _currentSpeedKmh = 0; _totalDistanceMeters = 0; _elapsed = Duration.zero; _isLoading = false; });
      if (result.success) {
        setState(() { _showCelebration = true; _isStealCelebration = result.stolenTerritory != null; });
        if (result.newAchievements.isNotEmpty) showAchievementToasts(context, result.newAchievements);
        Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showCelebration = false); });
      }
      await showDialog(context: context, barrierDismissible: false, builder: (_) => ResultDialog(result: result));
    }
  }

  void _togglePause() {
    if (_runStatus == RunStatus.running) { _service.pauseRun(); _statsTimer?.cancel(); setState(() => _runStatus = RunStatus.paused); }
    else if (_runStatus == RunStatus.paused) { _service.resumeRun(); _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (_runStartTime != null && mounted) setState(() => _elapsed = DateTime.now().difference(_runStartTime!)); }); setState(() => _runStatus = RunStatus.running); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black,
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : Stack(children: [
        FlutterMap(mapController: _mapController,
          options: MapOptions(initialCenter: _currentPosition, initialZoom: 17.0, maxZoom: 19.0, minZoom: 10.0, onPositionChanged: (_, hasGesture) { if (hasGesture && _isCentered) setState(() => _isCentered = false); }),
          children: [
            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', subdomains: const ['a','b','c','d'], userAgentPackageName: 'com.territory.app', retinaMode: true),
            PolygonLayer(polygons: _territories.map((t) { final color = _hexToColor(t.color); final isOwn = t.ownerId == AuthService.userId; return Polygon(points: t.polygon, color: color.withOpacity(isOwn ? 0.4 : 0.25), borderColor: color.withOpacity(isOwn ? 1.0 : 0.7), borderStrokeWidth: isOwn ? 3.0 : 2.0); }).toList()),
            if (_currentPath.length >= 2) PolylineLayer(polylines: [Polyline(points: _currentPath, strokeWidth: 4.0, color: AppTheme.primary, strokeCap: StrokeCap.round)]),
            MarkerLayer(markers: [Marker(point: _currentPosition, width: 48, height: 48, child: _UserMarker(isRunning: _runStatus == RunStatus.running))]),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 100, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])))),
        Positioned(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.terrain, color: AppTheme.primary, size: 18), SizedBox(width: 6), Text('TerritoryApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))])),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.map_outlined, color: Colors.white54, size: 14), const SizedBox(width: 4), Text('${_territories.length}', style: const TextStyle(color: Colors.white, fontSize: 13))])),
        ])),
        if (_runStatus != RunStatus.idle) Positioned(top: MediaQuery.of(context).padding.top + 60, left: 16, right: 16, child: _buildLiveStats()),
        Positioned(right: 16, bottom: 140, child: FloatingActionButton.small(heroTag: 'center', backgroundColor: _isCentered ? AppTheme.primary : Colors.white, onPressed: () { setState(() => _isCentered = !_isCentered); if (_isCentered) _mapController.move(_currentPosition, _mapController.camera.zoom); }, child: Icon(Icons.my_location, color: _isCentered ? Colors.white : Colors.black87))),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildControlPanel()),
        if (_showCelebration) Positioned.fill(child: IgnorePointer(child: CaptureCelebration(isSteal: _isStealCelebration))),
      ]),
    );
  }

  Widget _buildLiveStats() {
    final session = _service.currentSession;
    if (session == null) return const SizedBox.shrink();
    return StatsPanel(session: session.copyWith(pathLengthMeters: _totalDistanceMeters, avgSpeedKmh: _currentSpeedKmh, estimatedCalories: (_totalDistanceMeters / 1000) * 60, paceMinPerKm: _currentSpeedKmh > 0 ? 60 / _currentSpeedKmh : null), isRunning: _runStatus == RunStatus.running).animate().slideY(begin: -0.3, duration: 300.ms);
  }

  Widget _buildControlPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        if (_runStatus == RunStatus.idle) ...[
          Text('${_territories.length} territórios no mapa • ${_territories.where((t) => t.ownerId == AuthService.userId).length} seus', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: _hasPermission ? _startRun : null, icon: const Icon(Icons.play_arrow_rounded), label: const Text('INICIAR CORRIDA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        ] else ...[
          Text(_formatDuration(_elapsed), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SizedBox(height: 52, child: OutlinedButton.icon(onPressed: _togglePause, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), icon: Icon(_runStatus == RunStatus.paused ? Icons.play_arrow : Icons.pause), label: Text(_runStatus == RunStatus.paused ? 'RETOMAR' : 'PAUSAR')))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: SizedBox(height: 52, child: ElevatedButton.icon(onPressed: _finishRun, icon: const Icon(Icons.flag_rounded), label: const Text('CAPTURAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))))),
          ]),
        ],
      ]),
    );
  }

  void _showSnack(String message, {bool isError = false}) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red[700] : const Color(0xFF4CAF50), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); }
  Color _hexToColor(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  String _formatDuration(Duration d) { final h = d.inHours; final m = d.inMinutes.remainder(60).toString().padLeft(2, '0'); final s = d.inSeconds.remainder(60).toString().padLeft(2, '0'); return h > 0 ? '$h:$m:$s' : '$m:$s'; }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _statsTimer?.cancel(); _territoriesSubscription?.cancel(); _service.dispose(); _mapController.dispose(); super.dispose(); }
}

class _UserMarker extends StatefulWidget {
  final bool isRunning;
  const _UserMarker({required this.isRunning});
  @override
  State<_UserMarker> createState() => _UserMarkerState();
}

class _UserMarkerState extends State<_UserMarker> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true); _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _pulse, builder: (_, child) => Transform.scale(scale: widget.isRunning ? _pulse.value : 1.0, child: child), child: Container(decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]), child: const Icon(Icons.person, color: Colors.white, size: 22)));
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
