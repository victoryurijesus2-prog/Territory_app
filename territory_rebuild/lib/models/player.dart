// lib/models/player.dart
class Player {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final double totalAreaM2;
  final int territoryCount;
  final int runCount;
  final bool isPremium;
  final int xp;
  final String? clanId;
  final String? clanTag;
  final String? clanColor;
  final DateTime createdAt;

  const Player({required this.id, required this.nickname, this.avatarUrl, this.totalAreaM2 = 0, this.territoryCount = 0, this.runCount = 0, this.isPremium = false, this.xp = 0, this.clanId, this.clanTag, this.clanColor, required this.createdAt});

  double get totalAreaKm2 => totalAreaM2 / 1000000;

  String get formattedArea {
    if (totalAreaM2 >= 1000000) return '${totalAreaKm2.toStringAsFixed(2)} km²';
    if (totalAreaM2 >= 10000) return '${(totalAreaM2 / 10000).toStringAsFixed(2)} ha';
    return '${totalAreaM2.toStringAsFixed(0)} m²';
  }

  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: map['id'] as String,
    nickname: map['nickname'] as String? ?? 'Jogador',
    avatarUrl: map['avatar_url'] as String?,
    totalAreaM2: (map['total_area_m2'] as num?)?.toDouble() ?? 0,
    territoryCount: (map['territory_count'] as int?) ?? 0,
    runCount: (map['run_count'] as int?) ?? 0,
    isPremium: map['is_premium'] as bool? ?? false,
    xp: (map['xp'] as int?) ?? 0,
    clanId: map['clan_id'] as String?,
    clanTag: map['clan_tag'] as String?,
    clanColor: map['clan_color'] as String?,
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toMap() => {'id': id, 'nickname': nickname, 'avatar_url': avatarUrl, 'total_area_m2': totalAreaM2, 'territory_count': territoryCount, 'run_count': runCount, 'is_premium': isPremium, 'xp': xp, 'clan_id': clanId, 'clan_tag': clanTag, 'clan_color': clanColor, 'created_at': createdAt.toIso8601String()};

  Player copyWith({String? nickname, String? avatarUrl, double? totalAreaM2, int? territoryCount, int? runCount, bool? isPremium, int? xp}) => Player(id: id, nickname: nickname ?? this.nickname, avatarUrl: avatarUrl ?? this.avatarUrl, totalAreaM2: totalAreaM2 ?? this.totalAreaM2, territoryCount: territoryCount ?? this.territoryCount, runCount: runCount ?? this.runCount, isPremium: isPremium ?? this.isPremium, xp: xp ?? this.xp, clanId: clanId, clanTag: clanTag, clanColor: clanColor, createdAt: createdAt);
}
