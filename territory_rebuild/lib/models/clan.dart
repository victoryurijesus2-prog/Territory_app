// lib/models/clan.dart

class Clan {
  final String id;
  final String name;
  final String tag; // ex: [TER]
  final String color; // hex
  final String leaderId;
  final String leaderName;
  final int memberCount;
  final double totalAreaM2;
  final String? description;
  final DateTime createdAt;

  const Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.color,
    required this.leaderId,
    required this.leaderName,
    this.memberCount = 1,
    this.totalAreaM2 = 0,
    this.description,
    required this.createdAt,
  });

  String get formattedArea {
    if (totalAreaM2 >= 1000000) {
      return '${(totalAreaM2 / 1000000).toStringAsFixed(2)} km²';
    } else if (totalAreaM2 >= 10000) {
      return '${(totalAreaM2 / 10000).toStringAsFixed(2)} ha';
    }
    return '${totalAreaM2.toStringAsFixed(0)} m²';
  }

  factory Clan.fromMap(Map<String, dynamic> map) {
    return Clan(
      id: map['id'] as String,
      name: map['name'] as String,
      tag: map['tag'] as String? ?? '',
      color: map['color'] as String? ?? '#FF5722',
      leaderId: map['leader_id'] as String,
      leaderName: map['leader_name'] as String? ?? 'Líder',
      memberCount: map['member_count'] as int? ?? 1,
      totalAreaM2: (map['total_area_m2'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tag': tag,
        'color': color,
        'leader_id': leaderId,
        'leader_name': leaderName,
        'member_count': memberCount,
        'total_area_m2': totalAreaM2,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}

class ClanMember {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String clanId;
  final String role; // leader, member
  final double totalAreaM2;
  final DateTime joinedAt;

  const ClanMember({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.clanId,
    this.role = 'member',
    this.totalAreaM2 = 0,
    required this.joinedAt,
  });

  bool get isLeader => role == 'leader';

  factory ClanMember.fromMap(Map<String, dynamic> map) {
    return ClanMember(
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String? ?? 'Jogador',
      avatarUrl: map['avatar_url'] as String?,
      clanId: map['clan_id'] as String,
      role: map['role'] as String? ?? 'member',
      totalAreaM2: (map['total_area_m2'] as num?)?.toDouble() ?? 0,
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'] as String)
          : DateTime.now(),
    );
  }
}
