import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum RunStatus { idle, running, paused, finished, fraud }

class RunSession {
  final String id;
  final String userId;
  final List<LatLng> path;
  final List<DateTime> timestamps;
  final RunStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final double? maxSpeedKmh;
  final double? avgSpeedKmh;
  final double? pathLengthMeters;
  final double? estimatedCalories;
  final double? paceMinPerKm;
  final bool? fraudDetected;
  final bool? isPersonalRecord;

  RunSession({required this.id, required this.userId, this.path = const [], this.timestamps = const [], this.status = RunStatus.idle, this.startedAt, this.finishedAt, this.maxSpeedKmh, this.avgSpeedKmh, this.pathLengthMeters, this.estimatedCalories, this.paceMinPerKm, this.fraudDetected, this.isPersonalRecord});

  String get formattedDistance { if (pathLengthMeters == null) return '0 m'; if (pathLengthMeters! >= 1000) return '${(pathLengthMeters! / 1000).toStringAsFixed(2)} km'; return '${pathLengthMeters!.toStringAsFixed(0)} m'; }

  String get formattedPace { if (paceMinPerKm == null || paceMinPerKm! <= 0) return '--:--'; final min = paceMinPerKm!.floor(); final sec = ((paceMinPerKm! - min) * 60).round(); return '$min:${sec.toString().padLeft(2, '0')} /km'; }

  RunSession copyWith({List<LatLng>? path, List<DateTime>? timestamps, RunStatus? status, DateTime? startedAt, DateTime? finishedAt, double? maxSpeedKmh, double? avgSpeedKmh, double? pathLengthMeters, double? estimatedCalories, double? paceMinPerKm, bool? fraudDetected, bool? isPersonalRecord}) => RunSession(id: id, userId: userId, path: path ?? this.path, timestamps: timestamps ?? this.timestamps, status: status ?? this.status, startedAt: startedAt ?? this.startedAt, finishedAt: finishedAt ?? this.finishedAt, maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh, avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh, pathLengthMeters: pathLengthMeters ?? this.pathLengthMeters, estimatedCalories: estimatedCalories ?? this.estimatedCalories, paceMinPerKm: paceMinPerKm ?? this.paceMinPerKm, fraudDetected: fraudDetected ?? this.fraudDetected, isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord);

  Map<String, dynamic> toMap() => {'id': id, 'user_id': userId, 'path_json': jsonEncode(path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()), 'timestamps_json': jsonEncode(timestamps.map((t) => t.toIso8601String()).toList()), 'status': status.name, 'started_at': startedAt?.toIso8601String(), 'finished_at': finishedAt?.toIso8601String(), 'max_speed_kmh': maxSpeedKmh, 'avg_speed_kmh': avgSpeedKmh, 'path_length_meters': pathLengthMeters, 'estimated_calories': estimatedCalories, 'pace_min_per_km': paceMinPerKm, 'fraud_detected': fraudDetected == true ? 1 : 0, 'is_personal_record': isPersonalRecord == true ? 1 : 0};

  factory RunSession.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawPath = jsonDecode(map['path_json'] as String? ?? '[]');
    final List<dynamic> rawTs = jsonDecode(map['timestamps_json'] as String? ?? '[]');
    return RunSession(id: map['id'] as String, userId: map['user_id'] as String, path: rawPath.map((p) => LatLng(p['lat'] as double, p['lng'] as double)).toList(), timestamps: rawTs.map((t) => DateTime.parse(t as String)).toList(), status: RunStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => RunStatus.finished), startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null, finishedAt: map['finished_at'] != null ? DateTime.parse(map['finished_at'] as String) : null, maxSpeedKmh: (map['max_speed_kmh'] as num?)?.toDouble(), avgSpeedKmh: (map['avg_speed_kmh'] as num?)?.toDouble(), pathLengthMeters: (map['path_length_meters'] as num?)?.toDouble(), estimatedCalories: (map['estimated_calories'] as num?)?.toDouble(), paceMinPerKm: (map['pace_min_per_km'] as num?)?.toDouble(), fraudDetected: (map['fraud_detected'] as int?) == 1, isPersonalRecord: (map['is_personal_record'] as int?) == 1);
  }
}
