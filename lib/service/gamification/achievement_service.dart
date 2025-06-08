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
        imagePath: 'assets/achievements/first_expense.png',
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
        imagePath: 'assets/achievements/first_revenue.png',
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
        imagePath: 'assets/achievements/first_goal.png',
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
        imagePath: 'assets/achievements/goal_complete.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas'},
      ),

      Achievement(
        id: 'savings_100',
        title: '💰 Primeiras Economias',
        description:
            'Você economizou seus primeiros R\$ 100! Cada centavo conta!',
        secretDescription: 'Economize R\$ 100 para desbloquear',
        type: AchievementType.firstSaving,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/achievements/savings_100.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 100},
      ),

      Achievement(
        id: 'expenses_10',
        title: '📝 Organizador Iniciante',
        description: '10 despesas cadastradas! O controle está funcionando!',
        secretDescription: 'Cadastre 10 despesas para desbloquear',
        type: AchievementType.fiftyExpenses,
        rarity: AchievementRarity.silver,
        imagePath: 'assets/achievements/expenses_10.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'despesas', 'target_count': 10},
      ),

      // 🥇 OURO - Conquistas avançadas
      Achievement(
        id: 'savings_1000',
        title: '💎 Mil Reais',
        description: 'R\$ 1.000 economizados! Você está no caminho certo!',
        secretDescription: 'Economize R\$ 1.000 para desbloquear',
        type: AchievementType.fiveThousand,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/achievements/savings_1000.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 1000},
      ),

      Achievement(
        id: 'goal_complete_5',
        title: '🏆 Conquistador Persistente',
        description: 'Cinco metas alcançadas! Você é determinado!',
        secretDescription: 'Complete 5 metas para desbloquear',
        type: AchievementType.tenGoals,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/achievements/goal_complete_5.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 5},
      ),

      Achievement(
        id: 'expenses_50',
        title: '📊 Controlador Financeiro',
        description: '50 despesas registradas! Você está sempre atento!',
        secretDescription: 'Cadastre 50 despesas para desbloquear',
        type: AchievementType.fiftyExpenses,
        rarity: AchievementRarity.gold,
        imagePath: 'assets/achievements/expenses_50.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'despesas', 'target_count': 50},
      ),

      // 💎 LENDÁRIAS - Conquistas épicas
      Achievement(
        id: 'savings_10000',
        title: '👑 Dez Mil Reais!',
        description: 'R\$ 10.000 economizados! Você é LENDÁRIO!',
        secretDescription: 'Economize R\$ 10.000 para desbloquear',
        type: AchievementType.masterSaver,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/achievements/savings_10000.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'economias', 'target_amount': 10000},
      ),

      Achievement(
        id: 'goal_complete_10',
        title: '🌟 Mestre das Metas',
        description: 'DEZ metas conquistadas! Você é imparável!',
        secretDescription: 'Complete 10 metas para desbloquear',
        type: AchievementType.goalAchiever,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/achievements/goal_master.png',
        isUnlocked: false,
        progress: 0.0,
        metadata: {'category': 'metas', 'target_count': 10},
      ),

      // 👻 EASTER EGG DO MURPHY
      Achievement(
        id: 'murphy_special',
        title: '👻 Murphy Apareceu!',
        description:
            'Você desbloqueou o fantasma Murphy! Ele vai te "ajudar" com bugs!',
        secretDescription: '🥜 Algo sobre paçocas...',
        type: AchievementType.dailyUser,
        rarity: AchievementRarity.legendary,
        imagePath: 'assets/achievements/murphy.png',
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
    String imagePath = 'assets/achievements/default.png',
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
