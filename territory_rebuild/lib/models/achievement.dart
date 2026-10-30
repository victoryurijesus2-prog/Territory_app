enum AchievementId { firstRun, firstTerritory, tenTerritories, fiftyTerritories, speedDemon, marathoner, weekStreak, bigTerritory, conqueror, earlyBird }

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final String emoji;
  final DateTime? unlockedAt;

  const Achievement({required this.id, required this.title, required this.description, required this.emoji, this.unlockedAt});

  bool get isUnlocked => unlockedAt != null;

  static const List<Achievement> all = [
    Achievement(id: AchievementId.firstRun, title: 'Primeira Corrida', description: 'Complete sua primeira corrida', emoji: '🏃'),
    Achievement(id: AchievementId.firstTerritory, title: 'Primeiro Território', description: 'Capture seu primeiro território', emoji: '🗺️'),
    Achievement(id: AchievementId.tenTerritories, title: 'Conquistador', description: 'Capture 10 territórios', emoji: '👑'),
    Achievement(id: AchievementId.fiftyTerritories, title: 'Imperador', description: 'Capture 50 territórios', emoji: '🏰'),
    Achievement(id: AchievementId.speedDemon, title: 'Velocidade', description: 'Corra com velocidade média > 12 km/h', emoji: '⚡'),
    Achievement(id: AchievementId.marathoner, title: 'Maratonista', description: 'Acumule 42 km no total', emoji: '🎽'),
    Achievement(id: AchievementId.weekStreak, title: '7 Dias Seguidos', description: 'Corra por 7 dias consecutivos', emoji: '🔥'),
    Achievement(id: AchievementId.bigTerritory, title: 'Latifundiário', description: 'Capture um território com mais de 10 hectares', emoji: '🌄'),
    Achievement(id: AchievementId.conqueror, title: 'Invasor', description: 'Roube o território de outro jogador', emoji: '⚔️'),
    Achievement(id: AchievementId.earlyBird, title: 'Madrugador', description: 'Corra antes das 7h da manhã', emoji: '🌅'),
  ];

  Achievement copyWith({DateTime? unlockedAt}) => Achievement(id: id, title: title, description: description, emoji: emoji, unlockedAt: unlockedAt ?? this.unlockedAt);
}
