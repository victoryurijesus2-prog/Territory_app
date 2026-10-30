// lib/models/hotspot.dart

import 'package:latlong2/latlong.dart';

enum HotspotType {
  doublePoints,  // 2x pontos
  rareItem,      // item raro
  megaTerritory, // território épico garantido
}

class Hotspot {
  final String id;
  final String name;
  final LatLng position;
  final HotspotType type;
  final DateTime expiresAt;
  final double radiusMeters;
  final String? capturedByUserId;
  final String? capturedByName;

  const Hotspot({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    required this.expiresAt,
    this.radiusMeters = 200,
    this.capturedByUserId,
    this.capturedByName,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);
  bool get isCaptured => capturedByUserId != null;

  Duration get timeLeft => expiresAt.difference(DateTime.now());

  String get timeLeftText {
    final d = timeLeft;
    if (d.isNegative) return 'Expirado';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    if (d.inMinutes > 0) return '${d.inMinutes}min';
    return '${d.inSeconds}s';
  }

  String get typeEmoji {
    switch (type) {
      case HotspotType.doublePoints: return '⚡';
      case HotspotType.rareItem: return '💎';
      case HotspotType.megaTerritory: return '👑';
    }
  }

  String get typeLabel {
    switch (type) {
      case HotspotType.doublePoints: return '2x Pontos';
      case HotspotType.rareItem: return 'Item Raro';
      case HotspotType.megaTerritory: return 'Mega Território';
    }
  }

  double get pointsMultiplier {
    switch (type) {
      case HotspotType.doublePoints: return 2.0;
      case HotspotType.rareItem: return 1.5;
      case HotspotType.megaTerritory: return 3.0;
    }
  }

  factory Hotspot.fromMap(Map<String, dynamic> map) {
    return Hotspot(
      id: map['id'] as String,
      name: map['name'] as String,
      position: LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      ),
      type: HotspotType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HotspotType.doublePoints,
      ),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 200,
      capturedByUserId: map['captured_by_user_id'] as String?,
      capturedByName: map['captured_by_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'lat': position.latitude,
        'lng': position.longitude,
        'type': type.name,
        'expires_at': expiresAt.toIso8601String(),
        'radius_meters': radiusMeters,
        'captured_by_user_id': capturedByUserId,
        'captured_by_name': capturedByName,
      };

  Hotspot copyWith({
    String? capturedByUserId,
    String? capturedByName,
  }) => Hotspot(
        id: id,
        name: name,
        position: position,
        type: type,
        expiresAt: expiresAt,
        radiusMeters: radiusMeters,
        capturedByUserId: capturedByUserId ?? this.capturedByUserId,
        capturedByName: capturedByName ?? this.capturedByName,
      );
}
