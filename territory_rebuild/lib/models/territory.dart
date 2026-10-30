import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Territory {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final List<LatLng> polygon;
  final double areaSqMeters;
  final DateTime capturedAt;
  final String color;
  final int level;
  final double pointsPerHour;

  Territory({required this.id, required this.ownerId, required this.ownerName, this.ownerAvatarUrl, required this.polygon, required this.areaSqMeters, required this.capturedAt, this.color = '#FF5722', this.level = 1, this.pointsPerHour = 1.0});

  String get levelName { switch (level) { case 1: return 'Pequeno'; case 2: return 'Médio'; case 3: return 'Grande'; case 4: return 'Épico'; default: return 'Pequeno'; } }

  String get formattedArea {
    if (areaSqMeters >= 1000000) return '${(areaSqMeters / 1000000).toStringAsFixed(2)} km²';
    if (areaSqMeters >= 10000) return '${(areaSqMeters / 10000).toStringAsFixed(2)} ha';
    return '${areaSqMeters.toStringAsFixed(0)} m²';
  }

  static int computeLevel(double a) { if (a >= 500000) return 4; if (a >= 100000) return 3; if (a >= 20000) return 2; return 1; }

  Map<String, dynamic> toMap() => {'id': id, 'owner_id': ownerId, 'owner_name': ownerName, 'owner_avatar_url': ownerAvatarUrl, 'polygon_json': jsonEncode(polygon.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()), 'area_sq_meters': areaSqMeters, 'captured_at': capturedAt.toIso8601String(), 'color': color, 'level': level, 'points_per_hour': pointsPerHour};

  factory Territory.fromMap(Map<String, dynamic> map) {
    final raw = map['polygon_json'];
    final List<dynamic> pts = raw is String ? jsonDecode(raw) : (raw as List<dynamic>);
    return Territory(id: map['id'] as String, ownerId: map['owner_id'] as String, ownerName: map['owner_name'] as String? ?? 'Jogador', ownerAvatarUrl: map['owner_avatar_url'] as String?, polygon: pts.map((p) => LatLng(p['lat'] as double, p['lng'] as double)).toList(), areaSqMeters: (map['area_sq_meters'] as num).toDouble(), capturedAt: DateTime.parse(map['captured_at'] as String), color: map['color'] as String? ?? '#FF5722', level: map['level'] as int? ?? 1, pointsPerHour: (map['points_per_hour'] as num?)?.toDouble() ?? 1.0);
  }

  Territory copyWith({String? ownerId, String? ownerName, String? ownerAvatarUrl, String? color, int? level, double? pointsPerHour}) => Territory(id: id, ownerId: ownerId ?? this.ownerId, ownerName: ownerName ?? this.ownerName, ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl, polygon: polygon, areaSqMeters: areaSqMeters, capturedAt: capturedAt, color: color ?? this.color, level: level ?? this.level, pointsPerHour: pointsPerHour ?? this.pointsPerHour);
}
