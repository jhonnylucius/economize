import 'package:economize/data/gamification/achievement_dao.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:economize/service/gamification/achievement_checker.dart';
import 'package:economize/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  static AchievementService get instance => _instance;

  // Inicializar todas as conquistas
  static Future<void> initializeAchievements() async {
    try {
      Logger().i('🎯 Inicializando sistema de conquistas...');

      // ✅ VERIFICAR SE JÁ FORAM CRIADAS
      final existingCount = await AchievementDao.countTotal();
      if (existingCount > 0) {
        Logger()
            .i('✅ Conquistas já inicializadas ($existingCount encontradas)');
        return;
      }

      // ✅ CRIAR TODAS AS CONQUISTAS PADRÃO
      final defaultAchievements = _createAllAchievements();

      for (final achievement in defaultAchievements) {
        await AchievementDao.insert(achievement);
        Logger().d('📝 Conquista criada: ${achievement.title}');
      }

      Logger().i('🎉 ${defaultAchievements.length} conquistas criadas!');
    } catch (e) {
      Logger().e('❌ Erro ao inicializar conquistas: $e');
    }

    // Verificar se já foram criadas
    final existingCount = await AchievementDao.countTotal();
    if (existingCount > 0) {
      Logger().e('✅ Conquistas já inicializadas ($existingCount encontradas)');
      return;
    }

    // Criar todas as conquistas
    final achievements = _createAllAchievements();

    for (final achievement in achievements) {
      await AchievementDao.insert(achievement);
    }

    Logger().e('🎉 ${achievements.length} conquistas criadas!');
  }

  // Criar lista de todas as conquistas
  static List<Achievement> _createAllAchievements() {
    return [
      // 🥉 BRONZE - Primeiros passos
      Achievement(
        id: 'first_expense',
        title: '💸 Primeira Despesa',
        description:
            'Você cadastrou sua primeira despesa! O controle financeiro começou!',
        secretDescription: 'Cadastre sua primeira despesa para desbloquear',
        type: AchievementType.firstSaving,
        rarity: AchievementRarity.bronze,
        imagePath: 'assets/conquistas/conquista1.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'primeiros_passos'},
      ),

      Achievement(
        id: 'first_revenue',
        title: '💰 Primeira Receita',
        description:
            'Sua primeira receita foi registrada! O dinheiro está entrando!',
        secretDescription: 'Cadastre sua primeira receita para desbloquear',
        type: AchievementType.firstSaving,
        rarity: AchievementRarity.bronze,
        imagePath: 'assets/conquistas/conquista2.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'primeiros_passos'},
      ),

      Achievement(
        id: 'first_goal',
        title: '🎯 Primeira Meta',
        description:
            'Você definiu sua primeira meta financeira! Foco no objetivo!',
        secretDescription: 'Crie sua primeira meta para desbloquear',
        type: AchievementType.firstGoal,
        rarity: AchievementRarity.bronze,
        imagePath: 'assets/conquistas/conquista3.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'primeiros_passos'},
      ),

      // 🥈 PRATA - Progresso
      Achievement(
        id: 'goal_complete_1',
        title: '🏆 Meta Conquistada',
        description: 'Você completou sua primeira meta! Parabéns pelo foco!',
        secretDescription: 'Complete uma meta para desbloquear',
        type: AchievementType.firstGoal,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/conquistas/conquista4.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas'},
      ),

      Achievement(
        id: 'savings_2000',
        title: '💰 Primeiras Economias',
        description:
            'Você economizou seus primeiros R\$ 2000! Cada centavo conta!',
        secretDescription: 'Economize R\$ 2000 para desbloquear',
        type: AchievementType.firstSaving,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/conquistas/conquista5.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 2000},
      ),

      Achievement(
        id: 'expenses_100',
        title: '📝 Organizador Iniciante',
        description: '100 despesas cadastradas! O controle está funcionando!',
        secretDescription: 'Cadastre 100 despesas para desbloquear',
        type: AchievementType.fiftyExpenses,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/conquistas/conquista6.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'despesas', 'target_count': 100},
      ),

      // 🥇 OURO - Conquistas avançadas
      Achievement(
        id: 'savings_4000',
        title: '💎 Mil Reais',
        description: 'R\$ 4.000 economizados! Você está no caminho certo!',
        secretDescription: 'Economize R\$ 4.000 para desbloquear',
        type: AchievementType.fiveThousand,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista7.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 4000},
      ),

      Achievement(
        id: 'goal_complete_5',
        title: '🏆 Conquistador Persistente',
        description: 'Cinco metas alcançadas! Você é determinado!',
        secretDescription: 'Complete 5 metas para desbloquear',
        type: AchievementType.tenGoals,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista8.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 5},
      ),

      Achievement(
        id: 'expenses_500',
        title: '📊 Controlador Financeiro',
        description: '500 despesas registradas! Você está sempre atento!',
        secretDescription: 'Cadastre 500 despesas para desbloquear',
        type: AchievementType.fiftyExpenses,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista9.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'despesas', 'target_count': 500},
      ),

      // 💎 LENDÁRIAS - Conquistas épicas
      Achievement(
        id: 'savings_20000',
        title: '👑 Vinte Mil Reais!',
        description: 'R\$ 20.000 economizados! Você é LENDÁRIO!',
        secretDescription: 'Economize R\$ 20.000 para desbloquear',
        type: AchievementType.masterSaver,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista10.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 20000},
      ),

      Achievement(
        id: 'goal_complete_10',
        title: '🌟 Mestre das Metas',
        description: 'DEZ metas conquistadas! Você é imparável!',
        secretDescription: 'Complete 10 metas para desbloquear',
        type: AchievementType.goalAchiever,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista11.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 10},
      ),

      // 📈 PRIMEIRO MÊS POSITIVO
      Achievement(
        id: 'month_positive_1',
        title: '📈 Primeiro Mês Positivo',
        description: 'Seu primeiro mês com saldo positivo! Continue assim!',
        secretDescription: 'Tenha um mês com saldo positivo para desbloquear',
        type: AchievementType.firstMonth,
        rarity: AchievementRarity.bronze,
        imagePath: 'assets/conquistas/conquista4.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal'},
      ),

      // 🏦 CINCO MIL ECONOMIZADOS
      Achievement(
        id: 'savings_5000',
        title: '🏦 Cinco Mil!',
        description: 'R\$ 5.000 economizados! Você é um poupador nato!',
        secretDescription: 'Economize R\$ 5.000 para desbloquear',
        type: AchievementType.fiveThousand,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista14.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 5000},
      ),

// 🎯 MIL DESPESAS
      Achievement(
        id: 'expenses_1000',
        title: '🎯 Mestre do Controle',
        description: '1000 despesas! Você é um verdadeiro expert!',
        secretDescription: 'Cadastre 1000 despesas para desbloquear',
        type: AchievementType.hundredExpenses,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista13.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'despesas', 'target_count': 1000},
      ),

// 🎯 CINCO METAS CRIADAS
      Achievement(
        id: 'goals_5',
        title: '🎯 Planejador Ambicioso',
        description: '5 metas criadas! Você pensa no futuro!',
        secretDescription: 'Crie 5 metas para desbloquear',
        type: AchievementType.tenGoals,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/conquistas/conquista12.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 5},
      ),

// 🌟 DEZ METAS CRIADAS
      Achievement(
        id: 'goals_10',
        title: '🌟 Visionário Financeiro',
        description: '10 metas definidas! Sua visão é clara!',
        secretDescription: 'Crie 10 metas para desbloquear',
        type: AchievementType.tenGoals,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista15.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 10},
      ),

      // 🔥 TRÊS MESES CONSECUTIVOS
      Achievement(
        id: 'consecutive_3_months',
        title: '🔥 Três Meses Seguidos',
        description: 'Três meses consecutivos no azul! Você está arrasando!',
        secretDescription: 'Mantenha saldo positivo por 3 meses seguidos',
        type: AchievementType.firstMonth,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/conquistas/conquista16.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal', 'target_months': 3},
      ),

      // 🏆 SEIS MESES CONSECUTIVOS
      Achievement(
        id: 'consecutive_6_months',
        title: '🏆 Semestre Perfeito',
        description: 'Seis meses consecutivos positivos! Você é imparável!',
        secretDescription: 'Mantenha saldo positivo por 6 meses seguidos',
        type: AchievementType.firstMonth,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/conquistas/conquista17.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal', 'target_months': 6},
      ),

      // 🌟 UM ANO CONSECUTIVO (12 MESES)
      Achievement(
        id: 'consecutive_12_months',
        title: '🌟 Um Ano Perfeito',
        description: 'UM ANO INTEIRO positivo! Você é um MESTRE das finanças!',
        secretDescription: 'Mantenha saldo positivo por 12 meses seguidos',
        type: AchievementType.firstMonth,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista18.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal', 'target_months': 12},
      ),

// 🏛️ DOIS ANOS CONSECUTIVOS (24 MESES)
      Achievement(
        id: 'consecutive_24_months',
        title: '🏛️ Imperador Financeiro',
        description:
            'DOIS ANOS consecutivos! Você construiu um IMPÉRIO financeiro!',
        secretDescription: 'Mantenha saldo positivo por 24 meses seguidos',
        type: AchievementType.masterSaver,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista20.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal', 'target_months': 24},
      ),

// 👑 TRÊS ANOS CONSECUTIVOS (36 MESES)
      Achievement(
        id: 'consecutive_36_months',
        title: '👑 Rei das Finanças',
        description:
            'TRÊS ANOS consecutivos! Você é REALEZA financeira! LENDÁRIO!',
        secretDescription: 'Mantenha saldo positivo por 36 meses seguidos',
        type: AchievementType.masterSaver,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista22.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'saldo_mensal', 'target_months': 36},
      ),

// 🌌 CONQUISTA IMPOSSÍVEL - 5 ANOS (60 MESES)
      Achievement(
        id: 'consecutive_60_months',
        title: '🌌 Deus das Finanças',
        description: 'CINCO ANOS consecutivos! Você transcendeu! É IMPOSSÍVEL!',
        secretDescription: 'Mantenha saldo positivo por 60 meses seguidos',
        type: AchievementType.masterSaver,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista21.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {
          'category': 'saldo_mensal',
          'target_months': 60,
          'legendary_tier': 'godlike'
        },
      ),

      // 👻 EASTER EGG DO MURPHY
      Achievement(
        id: 'murphy_special',
        title: '👻 Murphy Apareceu!',
        description:
            'Você desbloqueou o fantasma Murphy! Ele vai te "ajudar" com os bugs!',
        secretDescription: '🥜 Algo sobre paçocas...',
        type: AchievementType.dailyUser,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/conquistas/conquista19.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'easter_egg', 'murphy_paçocas': 300},
      ),
    ];
  }

  // ✅ VERIFICAR E DESBLOQUEAR CONQUISTAS AUTOMATICAMENTE
  static Future<List<Achievement>> checkAndUnlockAchievements() async {
    final unlockedAchievements = <Achievement>[];

    try {
      Logger().i('🔍 Iniciando verificação automática de conquistas...');

      // 🎯 USAR NOSSO ACHIEVEMENT_CHECKER!
      await AchievementChecker.checkAllAchievements();

      // Buscar conquistas recém-desbloqueadas (últimas 5 minutos)
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      final allUnlocked = await getUnlockedAchievements();

      // Filtrar conquistas desbloqueadas recentemente
      for (final achievement in allUnlocked) {
        if (achievement.unlockedAt != null &&
            achievement.unlockedAt!.isAfter(fiveMinutesAgo)) {
          unlockedAchievements.add(achievement);
        }
      }

      Logger().i(
          '🎉 ${unlockedAchievements.length} conquistas recém-desbloqueadas encontradas');
    } catch (e) {
      Logger().e('❌ Erro na verificação automática de conquistas: $e');
    }

    return unlockedAchievements;
  }

  // Mostrar notificação de conquista
  static Future<void> _showAchievementNotification(
      Achievement achievement) async {
    await NotificationService.showAchievementNotification(
      title: '🏆 Nova Conquista Desbloqueada!',
      body: '${achievement.title} - ${achievement.description}',
      achievementId: achievement.id,
    );
  }

  // Buscar todas as conquistas
  static Future<List<Achievement>> getAllAchievements() async {
    return await AchievementDao.findAll();
  }

  // Buscar conquistas desbloqueadas
  static Future<List<Achievement>> getUnlockedAchievements() async {
    return await AchievementDao.findUnlocked();
  }

  // Buscar conquistas por raridade
  static Future<List<Achievement>> getAchievementsByRarity(
      AchievementRarity rarity) async {
    return await AchievementDao.findByRarity(rarity);
  }

  // Estatísticas de conquistas
  static Future<Map<String, int>> getAchievementStats() async {
    final unlockedCount = await AchievementDao.countUnlocked();
    final totalCount = await AchievementDao.countTotal();

    return {
      'unlocked': unlockedCount,
      'total': totalCount,
      'percentage':
          totalCount > 0 ? ((unlockedCount / totalCount) * 100).round() : 0,
    };
  }

  // 🔍 BUSCAR CONQUISTA POR ID
  static Future<Achievement?> getAchievementById(String id) async {
    try {
      return await AchievementDao.findById(id);
    } catch (e) {
      Logger().e('❌ Erro ao buscar conquista por ID $id: $e');
      return null;
    }
  }

  // 🔓 DESBLOQUEAR CONQUISTA POR ID
  static Future<bool> unlockAchievementById(String achievementId) async {
    try {
      await AchievementDao.unlock(achievementId);

      // Buscar a conquista desbloqueada para notificação
      final achievement = await AchievementDao.findById(achievementId);
      if (achievement != null) {
        // Mostrar notificação
        await _showAchievementNotification(achievement);
        Logger().i('🔓 Conquista desbloqueada: ${achievement.title}');
        return true;
      }
      return false;
    } catch (e) {
      Logger().e('❌ Erro ao desbloquear conquista por ID $achievementId: $e');
      return false;
    }
  }

  // 🎉 DESBLOQUEAR CONQUISTA (SOBRECARGA DO MÉTODO EXISTENTE)
  static Future<bool> unlockAchievement(Achievement achievement) async {
    try {
      // Salvar conquista no banco se não existir
      final existing = await AchievementDao.findById(achievement.id);
      if (existing == null) {
        await AchievementDao.insert(achievement);
      }

      // Desbloquear
      await AchievementDao.unlock(achievement.id);

      // Mostrar notificação
      await _showAchievementNotification(achievement);
      Logger().i('🎉 Nova conquista desbloqueada: ${achievement.title}');
      return true;
    } catch (e) {
      Logger().e('❌ Erro ao desbloquear conquista ${achievement.id}: $e');
      return false;
    }
  }

  // 📊 VERIFICAR SE CONQUISTA EXISTE
  static Future<bool> achievementExists(String id) async {
    try {
      final achievement = await AchievementDao.findById(id);
      return achievement != null;
    } catch (e) {
      Logger().e('❌ Erro ao verificar existência da conquista $id: $e');
      return false;
    }
  }

  // 🔄 ATUALIZAR PROGRESSO DE CONQUISTA
  static Future<void> updateAchievementProgress(
      String id, double progress) async {
    try {
      await AchievementDao.updateProgress(id, progress);
      Logger().i(
          '📊 Progresso da conquista $id atualizado: ${(progress * 100).toStringAsFixed(1)}%');
    } catch (e) {
      Logger().e('❌ Erro ao atualizar progresso da conquista $id: $e');
    }
  }

  // 🎯 CRIAR CONQUISTA CUSTOMIZADA
  static Future<Achievement> createCustomAchievement({
    required String id,
    required String title,
    required String description,
    required AchievementType type,
    required AchievementRarity rarity,
    String secretDescription = 'Conquista misteriosa...',
    String imagePath = 'assets/conquistas/conquista23.png',
  }) async {
    final achievement = Achievement(
      id: id,
      title: title,
      description: description,
      secretDescription: secretDescription,
      type: type,
      rarity: rarity,
      imagePath: imagePath,
      isUnlocked: false,
      progress: 0.0,
      metadata: {
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'custom': true,
      },
    );

    await AchievementDao.insert(achievement);
    Logger().i('🎯 Conquista customizada criada: $title');

    return achievement;
  }

  // 🏆 DESBLOQUEAR MÚLTIPLAS CONQUISTAS
  static Future<List<Achievement>> unlockMultipleAchievements(
      List<String> achievementIds) async {
    final unlockedAchievements = <Achievement>[];

    for (final id in achievementIds) {
      try {
        final success = await unlockAchievementById(id);
        if (success) {
          final achievement = await getAchievementById(id);
          if (achievement != null) {
            unlockedAchievements.add(achievement);
          }
        }
      } catch (e) {
        Logger().e('❌ Erro ao desbloquear conquista $id: $e');
      }
    }

    Logger().i(
        '🎉 ${unlockedAchievements.length} conquistas desbloqueadas em lote');
    return unlockedAchievements;
  }

  // 🔄 RESETAR TODAS AS CONQUISTAS (Para desenvolvimento/teste)
  static Future<void> resetAllAchievements() async {
    try {
      await AchievementDao.resetAll();
      Logger().w('🔄 TODAS as conquistas foram resetadas!');
    } catch (e) {
      Logger().e('❌ Erro ao resetar conquistas: $e');
    }
  }

  // 📈 ESTATÍSTICAS AVANÇADAS
  static Future<Map<String, dynamic>> getAdvancedStats() async {
    try {
      final allAchievements = await getAllAchievements();
      final unlockedAchievements = await getUnlockedAchievements();

      final statsByRarity = <String, Map<String, int>>{};

      for (final rarity in AchievementRarity.values) {
        final totalByRarity =
            allAchievements.where((a) => a.rarity == rarity).length;
        final unlockedByRarity =
            unlockedAchievements.where((a) => a.rarity == rarity).length;

        statsByRarity[rarity.toString()] = {
          'total': totalByRarity,
          'unlocked': unlockedByRarity,
          'percentage': totalByRarity > 0
              ? ((unlockedByRarity / totalByRarity) * 100).round()
              : 0,
        };
      }

      return {
        'total_achievements': allAchievements.length,
        'unlocked_achievements': unlockedAchievements.length,
        'overall_percentage': allAchievements.isNotEmpty
            ? ((unlockedAchievements.length / allAchievements.length) * 100)
                .round()
            : 0,
        'by_rarity': statsByRarity,
        'last_unlocked': unlockedAchievements.isNotEmpty
            ? unlockedAchievements.last.unlockedAt?.toString()
            : null,
      };
    } catch (e) {
      Logger().e('❌ Erro ao obter estatísticas avançadas: $e');
      return {};
    }
  }
}
