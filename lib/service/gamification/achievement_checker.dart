import 'package:economize/data/costs_dao.dart';
import 'package:economize/data/goal_dao.dart';
import 'package:economize/data/revenues_dao.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:economize/service/gamification/achievement_service.dart';
import 'package:economize/service/notification_service.dart';
import 'package:logger/logger.dart';

class AchievementChecker {
  static final Logger _logger = Logger();
  static DateTime? _lastCheck; // ✅ CONTROLE DE TEMPO
  static const Duration _cooldownPeriod =
      Duration(seconds: 30); // ✅ 30 segundos entre verificações

  /// 🎯 VERIFICA TODAS AS CONQUISTAS APÓS CADA AÇÃO
  static Future<void> checkAllAchievements() async {
    // ✅ VERIFICAR COOLDOWN
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < _cooldownPeriod) {
      _logger.d('⏰ Verificação em cooldown, pulando...');
      return;
    }

    _lastCheck = now;

    try {
      _logger.i('🔍 Verificando conquistas automáticas...');

      await Future.wait([
        _checkFirstExpense(),
        _checkFirstRevenue(),
        _checkFirstGoal(),
        _checkCompletedGoals(),
        _checkSavingsAmount(),
        _checkExpenseCount(),
        _checkGoalCount(),
        _checkMonthlyBalance(),
        // 🥜 Easter egg do Murphy
        _checkMurphySpecial(),
      ]);

      _logger.i('✅ Verificação de conquistas concluída');
    } catch (e) {
      _logger.e('❌ Erro ao verificar conquistas: $e');
    }
  }

  /// 💰 PRIMEIRA DESPESA CADASTRADA
  static Future<void> _checkFirstExpense() async {
    try {
      final costsDAO = CostsDAO();
      final costs = await costsDAO.findAll();

      if (costs.isNotEmpty) {
        await _unlockAchievementIfNotExists(
          id: 'first_expense',
          type: AchievementType.firstSaving,
          title: '💸 Primeira Despesa',
          description:
              'Você cadastrou sua primeira despesa! O controle financeiro começou!',
          rarity: AchievementRarity.bronze,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar primeira despesa: $e');
    }
  }

  /// 💵 PRIMEIRA RECEITA CADASTRADA
  static Future<void> _checkFirstRevenue() async {
    try {
      final revenuesDAO = RevenuesDAO();
      final revenues = await revenuesDAO.findAll();

      if (revenues.isNotEmpty) {
        await _unlockAchievementIfNotExists(
          id: 'first_revenue',
          type: AchievementType.firstSaving,
          title: '💰 Primeira Receita',
          description:
              'Sua primeira receita foi registrada! O dinheiro está entrando!',
          rarity: AchievementRarity.bronze,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar primeira receita: $e');
    }
  }

  /// 🎯 PRIMEIRA META CRIADA
  static Future<void> _checkFirstGoal() async {
    try {
      final goalsDAO = GoalsDAO();
      final goals = await goalsDAO.findAll();

      if (goals.isNotEmpty) {
        await _unlockAchievementIfNotExists(
          id: 'first_goal',
          type: AchievementType.firstGoal,
          title: '🎯 Primeira Meta',
          description:
              'Você definiu sua primeira meta financeira! Foco no objetivo!',
          rarity: AchievementRarity.bronze,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar primeira meta: $e');
    }
  }

  /// 🏆 METAS CONCLUÍDAS
  static Future<void> _checkCompletedGoals() async {
    try {
      final goalsDAO = GoalsDAO();
      final goals = await goalsDAO.findAll();

      final completedGoals =
          goals.where((goal) => goal.percentComplete >= 1.0).length;

      // Primeira meta concluída
      if (completedGoals >= 1) {
        await _unlockAchievementIfNotExists(
          id: 'goal_complete_1',
          type: AchievementType.firstGoal,
          title: '🏆 Meta Conquistada',
          description: 'Você completou sua primeira meta! Parabéns pelo foco!',
          rarity: AchievementRarity.silver,
        );
      }

      // 5 metas concluídas
      if (completedGoals >= 5) {
        await _unlockAchievementIfNotExists(
          id: 'goal_complete_5',
          type: AchievementType.tenGoals,
          title: '🏆 Conquistador Persistente',
          description: 'Cinco metas alcançadas! Você é determinado!',
          rarity: AchievementRarity.gold,
        );
      }

      // 10 metas concluídas (LENDÁRIA!)
      if (completedGoals >= 10) {
        await _unlockAchievementIfNotExists(
          id: 'goal_complete_10',
          type: AchievementType.goalAchiever,
          title: '🌟 Mestre das Metas',
          description: 'DEZ metas conquistadas! Você é imparável!',
          rarity: AchievementRarity.legendary,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar metas concluídas: $e');
    }
  }

  /// 💎 VERIFICAR VALOR ECONOMIZADO
  static Future<void> _checkSavingsAmount() async {
    try {
      final costsDAO = CostsDAO();
      final revenuesDAO = RevenuesDAO();

      final costs = await costsDAO.findAll();
      final revenues = await revenuesDAO.findAll();

      final totalCosts = costs.fold<double>(0, (sum, cost) => sum + cost.preco);
      final totalRevenues =
          revenues.fold<double>(0, (sum, revenue) => sum + revenue.preco);
      final savings = totalRevenues - totalCosts;

      // R$ 500 economizados
      if (savings >= 500) {
        await _unlockAchievementIfNotExists(
          id: 'savings_500',
          type: AchievementType.firstSaving,
          title: '💰 Primeiras Economias',
          description:
              'Você economizou seus primeiros R\$ 500! Cada centavo conta!',
          rarity: AchievementRarity.bronze,
        );
      }

      // R$ 1.000 economizados
      if (savings >= 1000) {
        await _unlockAchievementIfNotExists(
          id: 'savings_1000',
          type: AchievementType.fiveThousand,
          title: '💎 Mil Reais',
          description: 'R\$ 1.000 economizados! Você está no caminho certo!',
          rarity: AchievementRarity.silver,
        );
      }

      // R$ 5.000 economizados
      if (savings >= 5000) {
        await _unlockAchievementIfNotExists(
          id: 'savings_5000',
          type: AchievementType.fiveThousand,
          title: '🏦 Cinco Mil!',
          description: 'R\$ 5.000 economizados! Você é um poupador nato!',
          rarity: AchievementRarity.gold,
        );
      }

      // R$ 20.000 economizados (LENDÁRIA!)
      if (savings >= 20000) {
        await _unlockAchievementIfNotExists(
          id: 'savings_20000',
          type: AchievementType.masterSaver,
          title: '👑 Vinte Mil Reais!',
          description: 'R\$ 20.000 economizados! Você é LENDÁRIO!',
          rarity: AchievementRarity.legendary,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar economias: $e');
    }
  }

  /// 📊 QUANTIDADE DE DESPESAS
  static Future<void> _checkExpenseCount() async {
    try {
      final costsDAO = CostsDAO();
      final costs = await costsDAO.findAll();
      final expenseCount = costs.length;

      // 100 despesas
      if (expenseCount >= 100) {
        await _unlockAchievementIfNotExists(
          id: 'expenses_100',
          type: AchievementType.fiftyExpenses,
          title: '📝 Organizador Iniciante',
          description: '100 despesas cadastradas! O controle está funcionando!',
          rarity: AchievementRarity.bronze,
        );
      }

      // 500 despesas
      if (expenseCount >= 500) {
        await _unlockAchievementIfNotExists(
          id: 'expenses_500',
          type: AchievementType.fiftyExpenses,
          title: '📊 Controlador Financeiro',
          description: '500 despesas registradas! Você está sempre atento!',
          rarity: AchievementRarity.silver,
        );
      }

      // 1000 despesas
      if (expenseCount >= 1000) {
        await _unlockAchievementIfNotExists(
          id: 'expenses_1000',
          type: AchievementType.hundredExpenses,
          title: '🎯 Mestre do Controle',
          description: '1000 despesas! Você é um verdadeiro expert!',
          rarity: AchievementRarity.gold,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar quantidade de despesas: $e');
    }
  }

  /// 🎯 QUANTIDADE DE METAS
  static Future<void> _checkGoalCount() async {
    try {
      final goalsDAO = GoalsDAO();
      final goals = await goalsDAO.findAll();
      final goalCount = goals.length;

      // 5 metas
      if (goalCount >= 5) {
        await _unlockAchievementIfNotExists(
          id: 'goals_5',
          type: AchievementType.tenGoals,
          title: '🎯 Planejador Ambicioso',
          description: '5 metas criadas! Você pensa no futuro!',
          rarity: AchievementRarity.silver,
        );
      }

      // 10 metas
      if (goalCount >= 10) {
        await _unlockAchievementIfNotExists(
          id: 'goals_10',
          type: AchievementType.tenGoals,
          title: '🌟 Visionário Financeiro',
          description: '10 metas definidas! Sua visão é clara!',
          rarity: AchievementRarity.gold,
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar quantidade de metas: $e');
    }
  }

  /// 📈 SALDO MENSAL POSITIVO
  static Future<void> _checkMonthlyBalance() async {
    try {
      final now = DateTime.now();
      final costsDAO = CostsDAO();
      final revenuesDAO = RevenuesDAO();

      final costs = await costsDAO.findAll();
      final revenues = await revenuesDAO.findAll();

      // Filtrar por mês atual
      final currentMonthCosts = costs
          .where((cost) =>
              cost.data.year == now.year && cost.data.month == now.month)
          .toList();

      final currentMonthRevenues = revenues
          .where((revenue) =>
              revenue.data.year == now.year && revenue.data.month == now.month)
          .toList();

      final monthlyBalance = currentMonthRevenues.fold<double>(
              0, (sum, revenue) => sum + revenue.preco) -
          currentMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);

      // Primeiro mês positivo
      if (monthlyBalance > 0) {
        await _unlockAchievementIfNotExists(
          id: 'month_positive_1',
          type: AchievementType.firstMonth,
          title: '📈 Primeiro Mês Positivo',
          description: 'Seu primeiro mês com saldo positivo! Continue assim!',
          rarity: AchievementRarity.bronze,
        );

        // Verificar múltiplos meses consecutivos
        await _checkConsecutivePositiveMonths(costs, revenues, now);
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar saldo mensal: $e');
    }
  }

  /// 📊 VERIFICAR MESES CONSECUTIVOS POSITIVOS
  static Future<void> _checkConsecutivePositiveMonths(
      List costs, List revenues, DateTime currentDate) async {
    try {
      int consecutiveMonths = 0;

      // ✅ VERIFICAR ATÉ 60 MESES (5 ANOS) PARA CONQUISTAS ÉPICAS
      for (int i = 0; i < 60; i++) {
        final checkDate = _subtractMonths(currentDate, i);

        final monthCosts = costs
            .where((cost) =>
                cost.data.year == checkDate.year &&
                cost.data.month == checkDate.month)
            .toList();

        final monthRevenues = revenues
            .where((revenue) =>
                revenue.data.year == checkDate.year &&
                revenue.data.month == checkDate.month)
            .toList();

        final totalCosts =
            monthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
        final totalRevenues = monthRevenues.fold<double>(
            0, (sum, revenue) => sum + revenue.preco);
        final monthBalance = totalRevenues - totalCosts;

        // Log apenas para os primeiros 12 meses (evitar spam)
        if (i < 12) {
          _logger.d(
              '📊 ${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}: '
              'Receitas: R\$ ${totalRevenues.toStringAsFixed(2)}, '
              'Despesas: R\$ ${totalCosts.toStringAsFixed(2)}, '
              'Saldo: R\$ ${monthBalance.toStringAsFixed(2)}');
        }

        if (monthBalance > 0) {
          consecutiveMonths++;
          if (i < 12) {
            _logger.d('✅ Mês positivo! Consecutivos: $consecutiveMonths');
          }
        } else {
          if (i < 12) {
            _logger.d(
                '❌ Mês não positivo (${monthBalance.toStringAsFixed(2)}), quebrando sequência');
          }
          break;
        }
      }

      _logger.i(
          '🎯 RESULTADO ÉPICO: $consecutiveMonths meses consecutivos positivos');

      // ✅ DESBLOQUEAR CONQUISTAS BASEADAS NO RESULTADO

      // 3 meses consecutivos
      if (consecutiveMonths >= 3) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_3_months',
          type: AchievementType.firstMonth,
          title: '🔥 Três Meses Seguidos',
          description: 'Três meses consecutivos no azul! Você está arrasando!',
          rarity: AchievementRarity.silver,
        );
      }

      // 6 meses consecutivos
      if (consecutiveMonths >= 6) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_6_months',
          type: AchievementType.firstMonth,
          title: '🏆 Semestre Perfeito',
          description: 'Seis meses consecutivos positivos! Você é imparável!',
          rarity: AchievementRarity.gold,
        );
      }

      // ✅ ADICIONAR ESTA LINHA AQUI - ATUALIZAR PROGRESSO
      await _updateLongTermProgress(consecutiveMonths);

      // 🌟 12 meses consecutivos (1 ANO!)
      if (consecutiveMonths >= 12) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_12_months',
          type: AchievementType.firstMonth,
          title: '🌟 Um Ano Perfeito',
          description:
              'UM ANO INTEIRO positivo! Você é um MESTRE das finanças!',
          rarity: AchievementRarity.legendary,
        );

        // 🎊 NOTIFICAÇÃO ESPECIAL PARA 1 ANO
        await NotificationService.showAchievementNotification(
          title: '🎊 CONQUISTA ÉPICA DESBLOQUEADA!',
          body: '🌟 Um Ano Perfeito - Você é um MESTRE das finanças!',
          achievementId: 'consecutive_12_months',
        );
      }

      // 🏛️ 24 meses consecutivos (2 ANOS!)
      if (consecutiveMonths >= 24) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_24_months',
          type: AchievementType.masterSaver,
          title: '🏛️ Imperador Financeiro',
          description:
              'DOIS ANOS consecutivos! Você construiu um IMPÉRIO financeiro!',
          rarity: AchievementRarity.legendary,
        );

        // 🏛️ NOTIFICAÇÃO IMPERIAL
        await NotificationService.showAchievementNotification(
          title: '🏛️ CONQUISTA IMPERIAL!',
          body: '🏛️ Imperador Financeiro - DOIS ANOS de domínio total!',
          achievementId: 'consecutive_24_months',
        );
      }

      // 👑 36 meses consecutivos (3 ANOS!)
      if (consecutiveMonths >= 36) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_36_months',
          type: AchievementType.masterSaver,
          title: '👑 Rei das Finanças',
          description:
              'TRÊS ANOS consecutivos! Você é REALEZA financeira! LENDÁRIO!',
          rarity: AchievementRarity.legendary,
        );

        // 👑 NOTIFICAÇÃO REAL
        await NotificationService.showAchievementNotification(
          title: '👑 COROAÇÃO FINANCEIRA!',
          body: '👑 Rei das Finanças - TRÊS ANOS de reinado absoluto!',
          achievementId: 'consecutive_36_months',
        );
      }

      // 🌌 60 meses consecutivos (5 ANOS!) - IMPOSSÍVEL
      if (consecutiveMonths >= 60) {
        await _unlockAchievementIfNotExists(
          id: 'consecutive_60_months',
          type: AchievementType.masterSaver,
          title: '🌌 Deus das Finanças',
          description:
              'CINCO ANOS consecutivos! Você transcendeu! É IMPOSSÍVEL!',
          rarity: AchievementRarity.legendary,
        );

        // 🌌 NOTIFICAÇÃO DIVINA
        await NotificationService.showAchievementNotification(
          title: '🌌 ASCENSÃO DIVINA!',
          body:
              '🌌 Deus das Finanças - Você transcendeu a mortalidade financeira!',
          achievementId: 'consecutive_60_months',
        );
      }

      // 📊 LOG ESPECIAL PARA MARCOS IMPORTANTES
      if (consecutiveMonths >= 12) {
        final years = (consecutiveMonths / 12).floor();
        final remainingMonths = consecutiveMonths % 12;

        if (remainingMonths == 0) {
          _logger.i('🎉 MARCO ÉPICO: $years ano(s) completo(s) consecutivos!');
        } else {
          _logger.i(
              '🎯 PROGRESSO: $years ano(s) e $remainingMonths mês(es) consecutivos!');
        }
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar meses consecutivos épicos: $e');
    }
  }

  /// 📊 MOSTRAR PROGRESSO PARA CONQUISTAS DE LONGO PRAZO
  static Future<void> _updateLongTermProgress(int consecutiveMonths) async {
    try {
      // Progresso para 1 ano (12 meses)
      if (consecutiveMonths < 12) {
        await AchievementService.updateAchievementProgress(
            'consecutive_12_months', consecutiveMonths / 12.0);
      }

      // Progresso para 2 anos (24 meses)
      if (consecutiveMonths >= 12 && consecutiveMonths < 24) {
        await AchievementService.updateAchievementProgress(
            'consecutive_24_months', consecutiveMonths / 24.0);
      }

      // Progresso para 3 anos (36 meses)
      if (consecutiveMonths >= 24 && consecutiveMonths < 36) {
        await AchievementService.updateAchievementProgress(
            'consecutive_36_months', consecutiveMonths / 36.0);
      }

      // Progresso para 5 anos (60 meses)
      if (consecutiveMonths >= 36 && consecutiveMonths < 60) {
        await AchievementService.updateAchievementProgress(
            'consecutive_60_months', consecutiveMonths / 60.0);
      }

      _logger.d('📊 Progresso de conquistas épicas atualizado');
    } catch (e) {
      _logger.e('❌ Erro ao atualizar progresso épico: $e');
    }
  }

// ✅ MÉTODO AUXILIAR PARA CÁLCULO CORRETO DE MESES
  static DateTime _subtractMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month - months;

    while (newMonth <= 0) {
      newMonth += 12;
      newYear--;
    }

    return DateTime(newYear, newMonth, 1);
  }

  /// 👻 EASTER EGG DO MURPHY (SECRETO!)
  static Future<void> _checkMurphySpecial() async {
    try {
      // Murphy só aparece se o usuário tiver pelo menos 3 conquistas
      final stats = await AchievementService.getAchievementStats();

      if (stats['unlocked']! >= 3) {
        await _unlockAchievementIfNotExists(
          id: 'murphy_special',
          type: AchievementType.dailyUser,
          title: '👻 Murphy Apareceu!',
          description:
              'Você desbloqueou o fantasma Murphy! Ele vai te "ajudar" com as bugs!',
          rarity: AchievementRarity.legendary,
          secretDescription: '🥜 Algo sobre paçocas...',
        );
      }
    } catch (e) {
      _logger.e('❌ Erro ao verificar Easter Egg do Murphy: $e');
    }
  }

  /// 🔧 MÉTODO AUXILIAR PARA DESBLOQUEAR CONQUISTA
  static Future<void> _unlockAchievementIfNotExists({
    required String id,
    required AchievementType type,
    required String title,
    required String description,
    required AchievementRarity rarity,
    String secretDescription = 'Conquista misteriosa...',
  }) async {
    try {
      // Verificar se já existe
      final existingAchievement =
          await AchievementService.getAchievementById(id);

      if (existingAchievement == null) {
        // Criar nova conquista
        final achievement = Achievement(
          id: id,
          title: title,
          description: description,
          secretDescription: secretDescription,
          type: type,
          rarity: rarity,
          imagePath: 'assets/achievements/$id.png',
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: 1.0,
          metadata: {
            'auto_unlocked': true,
            'unlock_timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );

        await AchievementService.unlockAchievement(achievement);

        // 🎉 NOTIFICAÇÃO DE CONQUISTA!
        await NotificationService.showAchievementNotification(
          title: '🏆 Nova Conquista Desbloqueada!',
          body: '$title - $description',
          achievementId: id,
        );

        _logger.i('🎉 Nova conquista desbloqueada: $title');
      } else if (!existingAchievement.isUnlocked) {
        // Desbloquear conquista existente
        await AchievementService.unlockAchievementById(id);

        // 🎉 NOTIFICAÇÃO DE CONQUISTA!
        await NotificationService.showAchievementNotification(
          title: '🏆 Conquista Desbloqueada!',
          body: '$title - $description',
          achievementId: id,
        );

        _logger.i('🔓 Conquista desbloqueada: $title');
      }
    } catch (e) {
      _logger.e('❌ Erro ao desbloquear conquista $id: $e');
    }
  }

  /// 🔍 VERIFICAR E RETORNAR CONQUISTAS DESBLOQUEADAS RECENTEMENTE
  static Future<List<Achievement>> checkAndReturnNewAchievements() async {
    final beforeCheck = await AchievementService.getUnlockedAchievements();
    final beforeIds = beforeCheck.map((a) => a.id).toSet();

    // Executar todas as verificações
    await checkAllAchievements();

    // Verificar quais são novas
    final afterCheck = await AchievementService.getUnlockedAchievements();
    final newAchievements =
        afterCheck.where((a) => !beforeIds.contains(a.id)).toList();

    _logger.i(
        '🎉 ${newAchievements.length} novas conquistas desbloqueadas nesta verificação');

    return newAchievements;
  }

  /// 📊 VERIFICAÇÃO RÁPIDA SEM LOGS EXCESSIVOS
  static Future<void> quickCheck() async {
    try {
      await Future.wait([
        _checkFirstExpense(),
        _checkFirstRevenue(),
        _checkFirstGoal(),
        _checkCompletedGoals(),
        _checkSavingsAmount(),
      ]);
    } catch (e) {
      _logger.e('❌ Erro na verificação rápida: $e');
    }
  }
}
