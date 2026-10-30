import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/geo_utils.dart';
import '../core/config.dart';

enum FraudReason { none, speedTooHigh, impossibleJump, pathTooShort, notEnoughPoints, mockLocation, frozenGps, impossibleAccel }

class FraudResult {
  final bool isFraud;
  final FraudReason reason;
  final double maxSpeedKmh;
  final String message;
  const FraudResult({required this.isFraud, required this.reason, required this.maxSpeedKmh, required this.message});
}

class FraudDetector {
  static const double _impossibleJumpKmh = 60.0;
  static const double _maxAccelMs2 = 4.0;
  static const int _minPoints = 5;
  static const double _minPathMeters = AppConfig.minPathLengthMeters;
  static const double _maxSpeedKmh = AppConfig.maxRunSpeedKmh;

  static Future<bool> isMockLocation() async {
    try { final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high); return pos.isMocked; } catch (_) { return false; }
  }

  static FraudResult analyze({required List<LatLng> path, required List<DateTime> timestamps}) {
    if (path.length < _minPoints) return const FraudResult(isFraud: true, reason: FraudReason.notEnoughPoints, maxSpeedKmh: 0, message: 'Corrida inválida: pontos insuficientes.');
    if (path.length != timestamps.length) return const FraudResult(isFraud: true, reason: FraudReason.notEnoughPoints, maxSpeedKmh: 0, message: 'Dados inconsistentes.');
    final pathLen = GeoUtils.pathLengthMeters(path);
    if (pathLen < _minPathMeters) return FraudResult(isFraud: true, reason: FraudReason.pathTooShort, maxSpeedKmh: 0, message: 'Caminho muito curto (${pathLen.toStringAsFixed(0)}m).');
    if (_isFrozenGps(path)) return const FraudResult(isFraud: true, reason: FraudReason.frozenGps, maxSpeedKmh: 0, message: 'GPS suspeito: posição repetida.');
    for (int i = 0; i < path.length - 1; i++) {
      final distM = GeoUtils.distanceMeters(path[i], path[i + 1]);
      final timeSec = timestamps[i + 1].difference(timestamps[i]).inMilliseconds / 1000.0;
      if (timeSec <= 0) continue;
      final segSpeed = (distM / timeSec) * 3.6;
      if (segSpeed > _impossibleJumpKmh) return FraudResult(isFraud: true, reason: FraudReason.impossibleJump, maxSpeedKmh: segSpeed, message: 'Salto impossível: ${segSpeed.toStringAsFixed(1)} km/h.');
    }
    final maxSpeed = _smoothedMaxSpeed(path, timestamps, windowSeconds: 3);
    if (maxSpeed > _maxSpeedKmh) return FraudResult(isFraud: true, reason: FraudReason.speedTooHigh, maxSpeedKmh: maxSpeed, message: 'Velocidade excedida: ${maxSpeed.toStringAsFixed(1)} km/h.');
    return FraudResult(isFraud: false, reason: FraudReason.none, maxSpeedKmh: maxSpeed, message: 'Corrida válida!');
  }

  static bool _isFrozenGps(List<LatLng> path) {
    if (path.length < 6) return false;
    int repeated = 1;
    for (int i = 1; i < path.length; i++) { if (GeoUtils.distanceMeters(path[i-1], path[i]) < 1.0) { repeated++; if (repeated > 5) return true; } else { repeated = 1; } }
    return false;
  }

  static double _smoothedMaxSpeed(List<LatLng> path, List<DateTime> timestamps, {int windowSeconds = 3}) {
    double maxSpeed = 0.0;
    for (int i = 0; i < path.length; i++) {
      int j = i + 1;
      while (j < path.length) { if (timestamps[j].difference(timestamps[i]).inSeconds >= windowSeconds) break; j++; }
      if (j >= path.length) continue;
      double dist = 0;
      for (int k = i; k < j; k++) dist += GeoUtils.distanceMeters(path[k], path[k+1]);
      final timeSec = timestamps[j].difference(timestamps[i]).inMilliseconds / 1000.0;
      if (timeSec <= 0) continue;
      final speed = (dist / timeSec) * 3.6;
      if (speed > maxSpeed) maxSpeed = speed;
    }
    return maxSpeed;
  }
}
