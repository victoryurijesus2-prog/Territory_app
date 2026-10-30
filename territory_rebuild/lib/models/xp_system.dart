// lib/models/xp_system.dart
//
// Sistema de XP e Níveis do TerritoryApp

class XpSystem {
  // XP ganho por ação
  static const int xpPerKm = 50;
  static const int xpPerTerritory = 100;
  static const int xpPerSteal = 200;
  static const int xpPerHotspot = 300;
  static const int xpPerAchievement = 150;

  // Níveis e títulos
  static const List<PlayerLevel> levels = [
    PlayerLevel(level: 1,  title: 'Recruta',      emoji: '🥾', xpRequired: 0,     color: '#9E9E9E'),
    PlayerLevel(level: 2,  title: 'Explorador',   emoji: '🗺️', xpRequired: 500,   color: '#4CAF50'),
    PlayerLevel(level: 3,  title: 'Corredor',     emoji: '🏃', xpRequired: 1500,  color: '#2196F3'),
    PlayerLevel(level: 4,  title: 'Caçador',      emoji: '🎯', xpRequired: 3000,  color: '#9C27B0'),
    PlayerLevel(level: 5,  title: 'Conquistador', emoji: '⚔️', xpRequired: 6000,  color: '#FF9800'),
    PlayerLevel(level: 6,  title: 'Dominador',    emoji: '🔥', xpRequired: 12000, color: '#F44336'),
    PlayerLevel(level: 7,  title: 'Guerreiro',    emoji: '🛡️', xpRequired: 25000, color: '#E91E63'),
    PlayerLevel(level: 8,  title: 'Campeão',      emoji: '🏆', xpRequired: 50000, color: '#FFD700'),
    PlayerLevel(level: 9,  title: 'Mestre',       emoji: '👑', xpRequired: 100000,color: '#FF5722'),
    PlayerLevel(level: 10, title: 'Lenda',        emoji: '⭐', xpRequired: 200000,color: '#FFFFFF'),
  ];

  static PlayerLevel getLevelForXp(int xp) {
    PlayerLevel current = levels.first;
    for (final level in levels) {
      if (xp >= level.xpRequired) {
        current = level;
      }
    }
    return current;
  }

  static PlayerLevel? getNextLevel(int xp) {
    final current = getLevelForXp(xp);
    final idx = levels.indexWhere((l) => l.level == current.level);
    if (idx < levels.length - 1) return levels[idx + 1];
    return null;
  }

  static double getProgressToNextLevel(int xp) {
    final current = getLevelForXp(xp);
    final next = getNextLevel(xp);
    if (next == null) return 1.0;
    final range = next.xpRequired - current.xpRequired;
    final earned = xp - current.xpRequired;
    return (earned / range).clamp(0.0, 1.0);
  }

  static int getXpToNextLevel(int xp) {
    final next = getNextLevel(xp);
    if (next == null) return 0;
    return next.xpRequired - xp;
  }

  // Calcula XP ganho em uma corrida
  static int calculateRunXp({
    required double distanceKm,
    required bool capturedTerritory,
    required bool stoledTerritory,
    required bool capturedHotspot,
    required int newAchievements,
    required double streakMultiplier,
  }) {
    int xp = (distanceKm * xpPerKm).round();
    if (capturedTerritory) xp += xpPerTerritory;
    if (stoledTerritory) xp += xpPerSteal;
    if (capturedHotspot) xp += xpPerHotspot;
    xp += newAchievements * xpPerAchievement;
    return (xp * streakMultiplier).round();
  }
}

class PlayerLevel {
  final int level;
  final String title;
  final String emoji;
  final int xpRequired;
  final String color;

  const PlayerLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.xpRequired,
    required this.color,
  });

  List<String> get perks {
    switch (level) {
      case 1: return ['Acesso ao mapa básico'];
      case 2: return ['Vê territórios no raio de 500m', 'Badge de Explorador no perfil'];
      case 3: return ['Corridas salvas por 30 dias', 'Estatísticas detalhadas'];
      case 4: return ['Radar de hotspots próximos', 'Badge exclusivo de Caçador'];
      case 5: return ['Escudo de território (1x por dia)', 'Histórico completo de corridas'];
      case 6: return ['Cor exclusiva de território', 'Ataque mais eficiente (+10%)'];
      case 7: return ['Notificações em tempo real', 'Badge de Guerreiro no perfil'];
      case 8: return ['Título de Campeão no ranking', 'Destaque especial no leaderboard'];
      case 9: return ['Moldura dourada no perfil', 'XP em dobro por 24h (1x por semana)'];
      case 10: return ['Status de Lenda', 'Todos os perks anteriores', 'Ícone exclusivo no mapa'];
      default: return [];
    }
  }
}
