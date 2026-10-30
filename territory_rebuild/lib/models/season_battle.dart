// lib/models/season_battle.dart

class SeasonBattle {
  final String id;
  final String name;
  final String regionName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? leaderId;
  final String? leaderName;
  final double leaderArea;
  final String badgeEmoji;

  const SeasonBattle({
    required this.id,
    required this.name,
    required this.regionName,
    required this.startsAt,
    required this.endsAt,
    this.leaderId,
    this.leaderName,
    this.leaderArea = 0,
    this.badgeEmoji = '🏅',
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  bool get isFinished => DateTime.now().isAfter(endsAt);

  Duration get timeLeft => endsAt.difference(DateTime.now());

  String get timeLeftText {
    final d = timeLeft;
    if (d.isNegative) return 'Finalizada';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inMinutes}min';
  }

  String get statusText {
    if (isFinished) return 'Finalizada';
    if (isActive) return 'Em andamento';
    return 'Em breve';
  }

  factory SeasonBattle.fromMap(Map<String, dynamic> map) {
    return SeasonBattle(
      id: map['id'] as String,
      name: map['name'] as String,
      regionName: map['region_name'] as String,
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: DateTime.parse(map['ends_at'] as String),
      leaderId: map['leader_id'] as String?,
      leaderName: map['leader_name'] as String?,
      leaderArea: (map['leader_area'] as num?)?.toDouble() ?? 0,
      badgeEmoji: map['badge_emoji'] as String? ?? '🏅',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'region_name': regionName,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'leader_id': leaderId,
        'leader_name': leaderName,
        'leader_area': leaderArea,
        'badge_emoji': badgeEmoji,
      };
}
