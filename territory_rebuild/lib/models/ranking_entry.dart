class RankingEntry {
  final int position;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final double totalAreaM2;
  final int territoryCount;

  const RankingEntry({required this.position, required this.userId, required this.nickname, this.avatarUrl, required this.totalAreaM2, required this.territoryCount});

  String get formattedArea { if (totalAreaM2 >= 1000000) return '${(totalAreaM2 / 1000000).toStringAsFixed(2)} km²'; if (totalAreaM2 >= 10000) return '${(totalAreaM2 / 10000).toStringAsFixed(2)} ha'; return '${totalAreaM2.toStringAsFixed(0)} m²'; }

  String get medal { switch (position) { case 1: return '🥇'; case 2: return '🥈'; case 3: return '🥉'; default: return '#$position'; } }

  factory RankingEntry.fromMap(Map<String, dynamic> map, int position) => RankingEntry(position: position, userId: map['owner_id'] as String, nickname: map['owner_name'] as String? ?? 'Jogador', avatarUrl: map['avatar_url'] as String?, totalAreaM2: (map['total_area'] as num).toDouble(), territoryCount: (map['territory_count'] as int?) ?? 0);
}
