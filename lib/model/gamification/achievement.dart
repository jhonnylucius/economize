import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

enum AchievementType {
  // Básicas (Bronze) 🥉
  firstGoal, // Primeira meta criada
  firstMonth, // 1 mês saldo positivo
  firstSaving, // Primeira economia registrada

  // Intermediárias (Prata) 🥈
  threeMonths, // 3 meses saldo positivo
  fiftyExpenses, // 50 despesas cadastradas
  firstBudget, // Primeiro orçamento criado
  tenGoals, // 10 metas criadas

  // Avançadas (Ouro) 🥇
  sixMonths, // 6 meses saldo positivo
  oneYear, // 1 ano saldo positivo
  hundredExpenses, // 100 despesas cadastradas
  fiveThousand, // R$ 5.000 economizados

  // LEGENDÁRIAS (Diamante) 💎
  yearStreak, // 365 dias consecutivos
  dailyUser, // 1 ano acessando todo dia
  masterSaver, // R$ 50.000 economizados
  budgetMaster, // 50 orçamentos criados
  goalAchiever, // 25 metas alcançadas

  // SECRETAS/ESPECIAIS ⭐
  hundredThousand, // R$ 100.000 economizados
  twoYearStreak, // 2 anos saldo positivo
  perfectYear, // Ano perfeito (todos os dias)
}

enum AchievementRarity {
  bronze, // 🥉 Básicas
  silver, // 🥈 Intermediárias
  gold, // 🥇 Avançadas
  diamond, // 💎 Legendárias
  legendary, // ⭐ Secretas
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String secretDescription; // Dica misteriosa para não conquistadas
  final AchievementType type;
  final AchievementRarity rarity;
  final String imagePath;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final double progress; // 0.0 a 1.0
  final Map<String, dynamic> metadata; // Dados extras

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.secretDescription,
    required this.type,
    required this.rarity,
    required this.imagePath,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.metadata = const {},
  });

  // Cores por raridade
  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.bronze:
        return const Color(0xFFCD7F32);
      case AchievementRarity.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRarity.gold:
        return const Color(0xFFFFD700);
      case AchievementRarity.diamond:
        return const Color(0xFF00FFFF);
      case AchievementRarity.legendary:
        return const Color(0xFFFF00FF);
    }
  }

  // Ícone por raridade
  IconData get rarityIcon {
    switch (rarity) {
      case AchievementRarity.bronze:
        return Icons.emoji_events;
      case AchievementRarity.silver:
        return Icons.military_tech;
      case AchievementRarity.gold:
        return Icons.stars;
      case AchievementRarity.diamond:
        return Icons.diamond;
      case AchievementRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'secret_description': secretDescription,
      'type': type.toString(),
      'rarity': rarity.toString(),
      'image_path': imagePath,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'progress': progress,

      // ✅ SEMPRE SALVAR METADATA COMO JSON STRING:
      'metadata': jsonEncode(metadata),
    };
  }

// ✅ MAPEAMENTO REAL E CORRETO - CONFERIDO COM O SERVICE
  String get badgeImagePath {
    final Map<String, String> specificMappings = {
      // 🎯 MAPEAMENTO EXATO CONFORME SUA LISTA:
      'first_expense': 'assets/conquistas/conquista1.png', // 1
      'first_revenue': 'assets/conquistas/conquista2.png', // 2
      'first_goal': 'assets/conquistas/conquista3.png', // 3
      'goal_complete_1': 'assets/conquistas/conquista4.png', // 4
      'savings_500': 'assets/conquistas/conquista5.png', // 5
      'expenses_100': 'assets/conquistas/conquista6.png', // 6
      'savings_1000': 'assets/conquistas/conquista7.png', // 7
      'goal_complete_5': 'assets/conquistas/conquista8.png', // 8
      'expenses_500': 'assets/conquistas/conquista9.png', // 9
      'savings_20000': 'assets/conquistas/conquista10.png', // 10
      'goal_complete_10': 'assets/conquistas/conquista11.png', // 11
      'goals_5': 'assets/conquistas/conquista12.png', // 12 (era 15)
      'expenses_1000': 'assets/conquistas/conquista13.png', // 13 (era 14)
      'savings_5000': 'assets/conquistas/conquista14.png', // 14 (era 13)
      'goals_10': 'assets/conquistas/conquista15.png', // 15 (era 16)
      'consecutive_3_months':
          'assets/conquistas/conquista16.png', // 16 (era 17)
      'consecutive_6_months':
          'assets/conquistas/conquista17.png', // 17 (era 18)
      'consecutive_12_months':
          'assets/conquistas/conquista18.png', // 18 (era 19)
      'murphy_special': 'assets/conquistas/conquista19.png', // 19 (era 23)
      'consecutive_24_months': 'assets/conquistas/conquista20.png', // 20
      'consecutive_60_months':
          'assets/conquistas/conquista21.png', // 21 (era 22)
      'consecutive_36_months':
          'assets/conquistas/conquista22.png', // 22 (era 21)
      'conquista_misteriosa':
          'assets/conquistas/conquista23.png', // 23 (customizada)
      'month_positive_1': 'assets/conquistas/conquista24.png', // 24 (era 12)
    };

    // Verificar se tem mapeamento específico
    if (specificMappings.containsKey(id)) {
      return specificMappings[id]!;
    }

    // ✅ FALLBACK: Se não encontrar, usar baseado na raridade
    switch (rarity) {
      case AchievementRarity.bronze:
        final bronzeIndex = (id.hashCode.abs() % 6) + 1; // 1-6
        return 'assets/conquistas/conquista$bronzeIndex.png';

      case AchievementRarity.silver:
        final silverIndex = (id.hashCode.abs() % 6) + 7; // 7-12
        return 'assets/conquistas/conquista$silverIndex.png';

      case AchievementRarity.gold:
        final goldIndex = (id.hashCode.abs() % 6) + 13; // 13-18
        return 'assets/conquistas/conquista$goldIndex.png';

      case AchievementRarity.legendary:
        final legendaryIndex = (id.hashCode.abs() % 6) + 19; // 19-24
        return 'assets/conquistas/conquista$legendaryIndex.png';

      default:
        return 'assets/conquistas/conquista1.png';
    }
  }

  // ✅ GETTER SEGURO PARA METADATA
  T? getMetadata<T>(String key) {
    try {
      return metadata[key] as T?;
    } catch (e) {
      Logger().w('⚠️ Erro ao acessar metadata[$key]: $e');
      return null;
    }
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      secretDescription: map['secret_description'] ?? 'Conquista misteriosa...',
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => AchievementType.firstSaving,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.toString() == map['rarity'],
        orElse: () => AchievementRarity.bronze,
      ),
      imagePath: map['image_path'] ?? 'assets/achievements/default.png',
      isUnlocked: (map['is_unlocked'] ?? 0) == 1,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'])
          : null,
      progress: (map['progress'] ?? 0.0).toDouble(),

      // ✅ CORREÇÃO DO METADATA - TRATAMENTO SEGURO:
      metadata: _parseMetadata(map['metadata']),
    );
  }
  static Map<String, dynamic> _parseMetadata(dynamic metadataValue) {
    try {
      if (metadataValue == null) {
        return <String, dynamic>{};
      }

      if (metadataValue is Map<String, dynamic>) {
        return metadataValue;
      }

      if (metadataValue is String) {
        // Se for String, tentar fazer parse do JSON
        if (metadataValue.trim().isEmpty) {
          return <String, dynamic>{};
        }

        try {
          final Map<String, dynamic> parsed = jsonDecode(metadataValue);
          return parsed;
        } catch (e) {
          Logger().w('⚠️ Erro ao fazer parse do metadata JSON: $metadataValue');
          return <String, dynamic>{};
        }
      }

      // Se for outro tipo, tentar converter
      return Map<String, dynamic>.from(metadataValue as Map);
    } catch (e) {
      Logger().w('⚠️ Erro ao processar metadata: $e');
      return <String, dynamic>{};
    }
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? secretDescription,
    AchievementType? type,
    AchievementRarity? rarity,
    String? imagePath,
    DateTime? unlockedAt,
    bool? isUnlocked,
    double? progress,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      secretDescription: secretDescription ?? this.secretDescription,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      imagePath: imagePath ?? this.imagePath,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      metadata: metadata ?? this.metadata,
    );
  }

  Achievement copyWithMetadata(Map<String, dynamic> newMetadata) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      secretDescription: secretDescription,
      type: type,
      rarity: rarity,
      imagePath: imagePath,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
      progress: progress,
      metadata: {...metadata, ...newMetadata},
    );
  }
}
