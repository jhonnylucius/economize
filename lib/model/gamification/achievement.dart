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
