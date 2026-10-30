// lib/services/territory_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/achievement.dart';
import '../models/territory.dart';
import '../models/run_session.dart';
import '../utils/geo_utils.dart';
import '../services/fraud_detector.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';
import '../services/achievement_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import '../core/config.dart';
import '../core/theme.dart';

class TerritoryService {
  final DatabaseService _db;
  final LocalDatabaseService _local;
  final SyncService _sync;
  final AchievementService _achievements;
  final StreakService _streak;
  final Uuid _uuid;

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<LatLng> _positionController =
      StreamController<LatLng>.broadcast();

  RunSession? _currentSession;

  final void Function(LatLng position)? onPositionUpdate;
  final void Function(String message)? onError;

  TerritoryService({
    DatabaseService? db,
    AchievementService? achievements,
    this.onPositionUpdate,
    this.onError,
  })  : _db = db ?? DatabaseService.instance,
        _local = LocalDatabaseService.instance,
        _sync = SyncService.instance,
        _achievements = achievements ?? AchievementService(),
        _streak = StreakService.instance,
        _uuid = const Uuid();

  Stream<LatLng> get positionStream => _positionController.stream;
  RunSession? get currentSession => _currentSession;
  bool get isOnline => _sync.isOnline;
  Stream<List<Territory>> get territoriesStream => _db.territoriesStream();

  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<RunSession> startRun(String userId) async {
    await stopTracking();

    final isMock = await FraudDetector.isMockLocation();
    if (isMock) {
      throw Exception('GPS falso detectado. Desative o Mock Location para jogar.');
    }

    _currentSession = RunSession(
      id: _uuid.v4(),
      userId: userId,
      status: RunStatus.running,
      startedAt: DateTime.now(),
      path: [],
      timestamps: [],
    );

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onNewPosition,
      onError: (error) => onError?.call('Erro no GPS: $error'),
    );

    return _currentSession!;
  }

  void _onNewPosition(Position pos) {
    if (_currentSession == null ||
        _currentSession!.status != RunStatus.running) return;

    final latLng = LatLng(pos.latitude, pos.longitude);
    final newPath = List<LatLng>.from(_currentSession!.path)..add(latLng);
    final newTimestamps = List<DateTime>.from(_currentSession!.timestamps)
      ..add(DateTime.now());

    _currentSession = _currentSession!.copyWith(
      path: newPath,
      timestamps: newTimestamps,
    );

    _positionController.add(latLng);
    onPositionUpdate?.call(latLng);
  }

  void pauseRun() {
    if (_currentSession?.status == RunStatus.running) {
      _currentSession = _currentSession!.copyWith(status: RunStatus.paused);
      _positionSubscription?.pause();
    }
  }

  void resumeRun() {
    if (_currentSession?.status == RunStatus.paused) {
      _currentSession = _currentSession!.copyWith(status: RunStatus.running);
      _positionSubscription?.resume();
    }
  }

  Future<CaptureResult> finishRunAndCapture({
    required String userId,
    required String userName,
    String? userAvatarUrl,
  }) async {
    if (_currentSession == null) {
      return CaptureResult.error('Nenhuma corrida ativa.');
    }

    await stopTracking();

    final session = _currentSession!.copyWith(
      status: RunStatus.finished,
      finishedAt: DateTime.now(),
    );

    // Fraude
    final fraudResult = FraudDetector.analyze(
      path: session.path,
      timestamps: session.timestamps,
    );

    if (fraudResult.isFraud) {
      final fraudSession = session.copyWith(
        status: RunStatus.fraud,
        fraudDetected: true,
        maxSpeedKmh: fraudResult.maxSpeedKmh,
      );
      await _local.saveRunLocally(fraudSession);
      if (_sync.isOnline) await _db.saveRunSession(fraudSession);
      _currentSession = null;
      return CaptureResult(
        success: false,
        reason: CaptureFailReason.fraud,
        fraudResult: fraudResult,
        message: fraudResult.message,
      );
    }

    // Polígono fechado
    final isClosed = GeoUtils.isPathClosed(
      session.path,
      closingThresholdMeters: AppConfig.closingThresholdMeters,
      minPoints: AppConfig.minGpsPoints,
    );

    if (!isClosed) {
      await _saveRunOfflineFirst(session);
      _currentSession = null;
      return CaptureResult(
        success: false,
        reason: CaptureFailReason.pathNotClosed,
        message: 'Seu percurso não fechou um círculo. Volte ao ponto de partida!',
      );
    }

    final polygon = GeoUtils.convexHull(session.path);
    if (polygon.length < 3) {
      await _saveRunOfflineFirst(session);
      _currentSession = null;
      return CaptureResult(
        success: false,
        reason: CaptureFailReason.invalidPolygon,
        message: 'Não foi possível gerar um polígono válido.',
      );
    }

    final existingTerritories = await _sync.getTerritories();
    final areaSqMeters = GeoUtils.polygonAreaSqMeters(polygon);
    final colorIndex =
        existingTerritories.length % AppTheme.territoryColors.length;

    Territory? stolenTerritory;
    bool didSteal = false;

    for (final existing in existingTerritories) {
      if (existing.ownerId == userId) continue;

      final overlaps = GeoUtils.doesPathCrossPolygon(polygon, existing.polygon);
      if (!overlaps) continue;

      final attackerPointsInside = polygon
          .where((p) => GeoUtils.isPointInPolygon(p, existing.polygon))
          .length;
      final overlapPercent =
          polygon.isEmpty ? 0.0 : attackerPointsInside / polygon.length;

      if (overlapPercent >= 0.5) {
        final stolen = existing.copyWith(
          ownerId: userId,
          ownerName: userName,
          ownerAvatarUrl: userAvatarUrl,
          color: AppTheme.territoryColors[colorIndex],
        );
        if (_sync.isOnline) await _db.updateTerritory(stolen);
        stolenTerritory = stolen;
        didSteal = true;

        // Notifica o dono do território roubado
        await NotificationService.instance.notifyTerritoryStolen(
          attackerName: userName,
          territoryArea: existing.formattedArea,
        );
      } else if (overlapPercent > 0) {
        await _saveRunOfflineFirst(session);
        _currentSession = null;
        return CaptureResult(
          success: false,
          reason: CaptureFailReason.overlapsExistingTerritory,
          conflictingTerritory: existing,
          message: 'Cubra mais de 50% da área de ${existing.ownerName} para roubar.',
        );
      }
    }

    final level = Territory.computeLevel(areaSqMeters);
    final newTerritory = Territory(
      id: _uuid.v4(),
      ownerId: userId,
      ownerName: userName,
      ownerAvatarUrl: userAvatarUrl,
      polygon: polygon,
      areaSqMeters: areaSqMeters,
      capturedAt: DateTime.now(),
      color: AppTheme.territoryColors[colorIndex],
      level: level,
      pointsPerHour: level.toDouble(),
    );

    if (_sync.isOnline) await _db.saveTerritory(newTerritory);
    await _local.cacheTerritories([newTerritory]);

    final pathLen = GeoUtils.pathLengthMeters(session.path);
    final avgSpeed = GeoUtils.avgSpeedKmh(session.path, session.timestamps);
    final pace = avgSpeed > 0 ? 60 / avgSpeed : null;
    final calories = (pathLen / 1000) * 60;
    final bestDist = _sync.isOnline
        ? (await _db.getBestRunDistanceByUser(userId) ?? 0)
        : 0.0;
    final isPR = pathLen > bestDist;

    final finalSession = session.copyWith(
      status: RunStatus.finished,
      fraudDetected: false,
      maxSpeedKmh: fraudResult.maxSpeedKmh,
      avgSpeedKmh: avgSpeed,
      pathLengthMeters: pathLen,
      estimatedCalories: calories,
      paceMinPerKm: pace,
      isPersonalRecord: isPR,
    );

    await _sync.saveRun(finalSession);

    // ── STREAK ────────────────────────────────────────────────────────────
    final streakResult = await _streak.registerRun();
    // Agenda lembrete para amanhã
    await NotificationService.instance.scheduleStreakReminder();

    List<Achievement> newAchievements = [];
    if (_sync.isOnline) {
      final allTerritories = await _db.getAllTerritories();
      final allRuns = await _db.getRunSessionsByUser(userId);
      newAchievements = await _achievements.checkAndUnlock(
        userId: userId,
        session: finalSession,
        allTerritories: allTerritories,
        allRuns: allRuns,
        didCapture: true,
        didStealTerritory: didSteal,
      );
    }

    _currentSession = null;

    final offlineNote = _sync.isOnline ? '' : '\n📦 Salvo offline';
    final msg = didSteal
        ? '⚔️ Roubou de ${stolenTerritory!.ownerName}!\n🏆 ${newTerritory.formattedArea}$offlineNote'
        : '🏆 ${newTerritory.formattedArea} capturado!$offlineNote';

    return CaptureResult(
      success: true,
      reason: CaptureFailReason.none,
      territory: newTerritory,
      stolenTerritory: stolenTerritory,
      newAchievements: newAchievements,
      isPersonalRecord: isPR,
      streakResult: streakResult,
      message: msg,
    );
  }

  Future<void> _saveRunOfflineFirst(RunSession session) async {
    await _local.saveRunLocally(session);
    if (_sync.isOnline) {
      try {
        await _db.saveRunSession(session);
        await _local.markRunSynced(session.id);
      } catch (_) {}
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<List<Territory>> getAllTerritories() => _sync.getTerritories();
  Future<List<RunSession>> getMyRuns(String userId) => _sync.getMyRuns(userId);
  Future<double> getMyTotalArea(String userId) => _db.getTotalAreaByOwner(userId);

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}

enum CaptureFailReason {
  none, fraud, pathNotClosed, invalidPolygon,
  overlapsExistingTerritory, limitReached, error,
}

class CaptureResult {
  final bool success;
  final CaptureFailReason reason;
  final Territory? territory;
  final Territory? conflictingTerritory;
  final Territory? stolenTerritory;
  final FraudResult? fraudResult;
  final List<Achievement> newAchievements;
  final bool isPersonalRecord;
  final StreakResult? streakResult;
  final String message;

  const CaptureResult({
    required this.success,
    required this.reason,
    this.territory,
    this.conflictingTerritory,
    this.stolenTerritory,
    this.fraudResult,
    this.newAchievements = const [],
    this.isPersonalRecord = false,
    this.streakResult,
    required this.message,
  });

  factory CaptureResult.error(String msg) => CaptureResult(
        success: false,
        reason: CaptureFailReason.error,
        message: msg,
      );
}
