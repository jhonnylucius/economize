import 'package:economize/model/budget/budget_location.dart';
import 'package:economize/model/notification_type.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/goals_service.dart';
import 'package:economize/service/push_notification_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/service/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static const String _storageKey = 'app_notifications';

  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();
  final BudgetService _budgetService = BudgetService();
  final GoalsService _goalsService = GoalsService();
  final PushNotificationService _pushService = PushNotificationService();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Notificadores
  final ValueNotifier<List<NotificationItem>> notifications =
      ValueNotifier<List<NotificationItem>>([]);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // Inicialização
  Future<void> initialize() async {
    await _loadSavedNotifications();

    // Inicializar notificações push
    await _pushService.initialize();

    _scheduleNotificationCheck();
  }

  // Carregar notificações salvas
  Future<void> _loadSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);

      if (storedData != null) {
        final List<dynamic> decoded = json.decode(storedData);
        final loadedNotifications =
            decoded.map((item) => NotificationItem.fromJson(item)).toList();

        // Ordena por timestamp (mais recente primeiro)
        loadedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Atualiza os notificadores
        notifications.value = loadedNotifications;
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    }
  }

  // Salvar notificações atuais
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(
        notifications.value.map((item) => item.toJson()).toList(),
      );

      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');
    }
  }

  // Adicionar uma nova notificação
  Future<void> addNotification(NotificationItem notification) async {
    notifications.value = [notification, ...notifications.value];
    _updateUnreadCount();
    await _saveNotifications();

    // CORREÇÃO: Adicionar verificação de null safety
    if (notification.type == NotificationType.reminder &&
        notification.data != null && // <- ADICIONE ESTA LINHA
        notification.data!['paymentId'] != null) {
      await _sendPushNotification(notification);
    }
  }

  Future<void> _schedulePaymentPushNotifications(dynamic payment) async {
    try {
      await schedulePaymentNotification(
        paymentId: payment.id,
        paymentName: payment.tipoDespesa,
        amount: payment.preco,
        dueDate: payment.data,
        isRecurrent: payment.recorrente,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação push para pagamento: $e');
    }
  }

  // ATUALIZADO: Método para enviar notificação push (mais seletivo)
  Future<void> _sendPushNotification(NotificationItem notification) async {
    try {
      // Só envia push para tipos específicos (principalmente pagamentos)
      final shouldSendPush = _shouldSendPushForNotification(notification);

      if (!shouldSendPush) {
        debugPrint('Notificação "${notification.title}" mantida apenas no app');
        return;
      }

      // Gerar ID único para a notificação push
      final pushId = notification.id.hashCode;

      await _pushService.showNotification(
        id: pushId,
        title: notification.title,
        body: notification.description,
        payload: notification.id,
        channelId: _getChannelIdForType(notification.type),
        channelName: _getChannelNameForType(notification.type),
      );

      debugPrint('📱 Notificação push enviada: ${notification.title}');
    } catch (e) {
      debugPrint('Erro ao enviar notificação push: $e');
    }
  }
// No método _showAchievementNotification, TROCAR de:
  /*await NotificationService.showAchievementNotification(
  title: '🏆 Nova Conquista Desbloqueada!',
  body: '${achievement.title} - ${achievement.description}',
  achievementId: achievement.id,
);

// PARA:
await NotificationService().addNotification(
  NotificationItem(
    id: 'achievement_${achievement.id}_${DateTime.now().millisecondsSinceEpoch}',
    title: '🏆 Nova Conquista Desbloqueada!',
    description: '${achievement.title} - ${achievement.description}',
    type: NotificationType.achievement,
    timestamp: DateTime.now(),
    isRead: false,
    data: {
      'achievementId': achievement.id,
      'achievementType': achievement.type.toString(),
    },
  ),
);*/

// NOVO: Método para mostrar notificação de conquista
  static Future<void> showAchievementNotification({
    required String title,
    required String body,
    required String achievementId,
  }) async {
    try {
      final pushService = PushNotificationService();

      // Gerar ID único para a notificação push
      final pushId = achievementId.hashCode;

      await pushService.showNotification(
        id: pushId,
        title: title,
        body: body,
        payload: 'achievement_$achievementId',
        channelId: 'economize_achievements',
        channelName: 'Conquistas e Realizações',
      );

      Logger().e('🏆 Notificação de conquista enviada: $title');

      // OPCIONAL: Também criar notificação no app
      final notificationItem = NotificationItem(
        id: 'achievement_notification_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: body,
        type: NotificationType.achievement,
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'achievementId': achievementId,
          'type': 'achievement_unlocked',
        },
      );

      // Adicionar ao sistema de notificações do app
      await NotificationService().addNotification(notificationItem);
    } catch (e) {
      Logger().e('❌ Erro ao enviar notificação de conquista: $e');
    }
  }

  // NOVO: Determina quais notificações devem virar push
  bool _shouldSendPushForNotification(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.reminder:
        // Apenas lembretes de pagamento vão para push
        return notification.data['paymentId'] != null;

      case NotificationType.alert:
      case NotificationType.warning:
        // Alertas críticos podem ir para push
        return notification.title.toLowerCase().contains('orçamento') ||
            notification.title.toLowerCase().contains('limite');

      case NotificationType.achievement:
        // Conquistas importantes podem ir para push
        return notification.title.toLowerCase().contains('meta') &&
            notification.title.toLowerCase().contains('alcançada');

      case NotificationType.success:
      case NotificationType.tip:
      case NotificationType.info:
      case NotificationType.report:
        // Estes tipos ficam APENAS no app
        return false;
    }
  }

  // NOVO: Método para agendar notificação de pagamento
  Future<void> schedulePaymentNotification({
    required String paymentId,
    required String paymentName,
    required double amount,
    required DateTime dueDate,
    bool isRecurrent = false,
  }) async {
    try {
      // Agendar 3 dias antes
      final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
      if (threeDaysBefore.isAfter(DateTime.now())) {
        await _pushService.scheduleNotification(
          id: '${paymentId}_3days'.hashCode,
          title: 'Pagamento próximo 📅',
          body:
              '$paymentName de R\$${amount.toStringAsFixed(2)} vence em 3 dias',
          scheduledDate: threeDaysBefore,
          payload: 'payment_$paymentId',
          channelId: 'economize_payments',
          channelName: 'Pagamentos',
        );
      }

      // Agendar 1 dia antes
      final oneDayBefore = dueDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(DateTime.now())) {
        await _pushService.scheduleNotification(
          id: '${paymentId}_1day'.hashCode,
          title: 'Pagamento amanhã! ⚠️',
          body: '$paymentName de R\$${amount.toStringAsFixed(2)} vence amanhã',
          scheduledDate: oneDayBefore,
          payload: 'payment_$paymentId',
          channelId: 'economize_payments',
          channelName: 'Pagamentos',
        );
      }

      // Agendar no dia do vencimento
      final dayOf = DateTime(
          dueDate.year, dueDate.month, dueDate.day, 9, 0); // 9h da manhã
      if (dayOf.isAfter(DateTime.now())) {
        await _pushService.scheduleNotification(
          id: '${paymentId}_today'.hashCode,
          title: 'Pagamento hoje! 🚨',
          body: '$paymentName de R\$${amount.toStringAsFixed(2)} vence hoje',
          scheduledDate: dayOf,
          payload: 'payment_$paymentId',
          channelId: 'economize_urgent',
          channelName: 'Urgente',
        );
      }

      debugPrint('📅 Notificações de pagamento agendadas para: $paymentName');
    } catch (e) {
      debugPrint('Erro ao agendar notificações de pagamento: $e');
    }
  }

  // NOVO: Método para cancelar notificações de um pagamento
  Future<void> cancelPaymentNotifications(String paymentId) async {
    await _pushService.cancelNotification('${paymentId}_3days'.hashCode);
    await _pushService.cancelNotification('${paymentId}_1day'.hashCode);
    await _pushService.cancelNotification('${paymentId}_today'.hashCode);
  }

  // NOVO: Métodos auxiliares para canais
  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
      case NotificationType.alert:
        return 'economize_alerts';
      case NotificationType.reminder:
        return 'economize_payments';
      case NotificationType.achievement:
      case NotificationType.success:
        return 'economize_achievements';
      case NotificationType.tip:
        return 'economize_tips';
      case NotificationType.report:
        return 'economize_reports';
      default:
        return 'economize_default';
    }
  }

  String _getChannelNameForType(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
      case NotificationType.alert:
        return 'Alertas Importantes';
      case NotificationType.reminder:
        return 'Lembretes de Pagamento';
      case NotificationType.achievement:
      case NotificationType.success:
        return 'Conquistas';
      case NotificationType.tip:
        return 'Dicas Financeiras';
      case NotificationType.report:
        return 'Relatórios';
      default:
        return 'Notificações Gerais';
    }
  }

  // Marcar notificação como lida
  Future<void> markAsRead(String id) async {
    final updatedList = notifications.value.map((item) {
      if (item.id == id && !item.isRead) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    notifications.value = updatedList;
    _updateUnreadCount();
    await _saveNotifications();
  }

  // Marcar todas como lidas
  Future<void> markAllAsRead() async {
    final updatedList = notifications.value.map((item) {
      return item.copyWith(isRead: true);
    }).toList();

    notifications.value = updatedList;
    _updateUnreadCount();
    await _saveNotifications();
  }

  // Remover uma notificação
  Future<void> removeNotification(String id) async {
    notifications.value =
        notifications.value.where((item) => item.id != id).toList();
    _updateUnreadCount();
    await _saveNotifications();
  }

  // Limpar todas as notificações
  Future<void> clearAllNotifications() async {
    notifications.value = [];
    _updateUnreadCount();
    await _saveNotifications();
  }

  // Atualizar contagem de não lidas
  void _updateUnreadCount() {
    final count = notifications.value.where((item) => !item.isRead).length;
    unreadCount.value = count;
  }

  // Programar verificação de notificações
  void _scheduleNotificationCheck() {
    // Verifica imediatamente
    checkForNewNotifications();

    // Programa verificações periódicas
    Future.delayed(const Duration(hours: 2), () {
      if (notifications.value.length < 20) {
        // Limitar número total de notificações
        checkForNewNotifications();
      }
      _scheduleNotificationCheck(); // Agenda próxima verificação
    });
  }

  // Principal método para gerar novas notificações baseadas nos dados reais
  Future<void> checkForNewNotifications() async {
    try {
      await Future.wait([
        _checkBudgetAlerts(),
        _checkGoalProgress(),
        _checkUpcomingPayments(), // Adicionado este método
        _checkFinancialTips(),
        _checkAchievements(),
        _checkMonthlyReport(),
      ]);
    } catch (e) {
      debugPrint('Erro ao verificar notificações: $e');
    }
  }

  // Verificações específicas para diferentes tipos de alertas

  // 1. Alerta de orçamento próximo do limite
  Future<void> _checkBudgetAlerts() async {
    try {
      final budgets = await _budgetService.getAllBudgets();
      final costs = await _costsService.getAllCosts();

      // Agrupar despesas por categoria e verificar totais
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Para cada orçamento
      for (final budget in budgets) {
        // Verificar se o orçamento possui itens e summary
        if (budget.items.isEmpty) continue;

        // 1. Alerta de economia potencial
        double savingsPercentage = 0;
        if (budget.summary.totalOriginal > 0) {
          savingsPercentage =
              (budget.summary.savings / budget.summary.totalOriginal) * 100;
        }

        // Se a economia está abaixo de 5%, notificar
        if (savingsPercentage < 5 && budget.summary.totalOriginal > 0) {
          final existing = _hasExistingBudgetAlert(budget.id);

          if (!existing) {
            final notification = NotificationItem(
              id: 'budget_alert_${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Potencial de economia baixo',
              description:
                  'Seu orçamento "${budget.title}" tem um potencial de economia de apenas ${savingsPercentage.toStringAsFixed(1)}%',
              type: NotificationType.warning,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'budgetId': budget.id,
                'budgetTitle': budget.title,
                'savingsPercentage': savingsPercentage,
              },
            );

            await addNotification(notification);
          }
        }

        // 2. Alerta de economia significativa (usa o método que estava não referenciado)
        else if (savingsPercentage >= 20) {
          final existing = _hasExistingBudgetSavingsAlert(budget.id);

          if (!existing) {
            final notification = NotificationItem(
              id: 'budget_savings_${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Ótima economia! 💰',
              description:
                  'Seu orçamento "${budget.title}" está economizando ${savingsPercentage.toStringAsFixed(1)}%!',
              type: NotificationType.success,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'budgetId': budget.id,
                'budgetTitle': budget.title,
                'savingsPercentage': savingsPercentage,
              },
            );

            await addNotification(notification);
          }
        }

        // 3. Alerta de itens excessivamente caros
        // Identificar itens que estão com preço muito acima da média
        for (final item in budget.items) {
          if (item.prices.length <= 1) {
            continue; // Precisa ter mais de um preço para comparação
          }

          final prices = item.prices.values.toList();
          final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
          final highestPrice = prices.reduce((a, b) => a > b ? a : b);

          // Se o preço mais alto é pelo menos 30% maior que a média
          if (highestPrice > avgPrice * 1.3) {
            final highPriceLocation = item.prices.entries
                .firstWhere((entry) => entry.value == highestPrice)
                .key;

            // Encontre o nome da localização
            final location = budget.locations.firstWhere(
              (loc) => loc.id == highPriceLocation,
              orElse: () => BudgetLocation(
                id: highPriceLocation,
                name: "Desconhecido",
                address: "",
                priceDate: DateTime.now(),
                budgetId: budget.id,
              ),
            );

            final itemAlertId =
                'item_price_alert_${item.id}_$highPriceLocation';
            final existing =
                notifications.value.any((n) => n.id == itemAlertId);

            if (!existing) {
              final notification = NotificationItem(
                id: itemAlertId,
                title: 'Preço elevado detectado',
                description:
                    'O item "${item.name}" está ${((highestPrice / avgPrice - 1) * 100).toStringAsFixed(0)}% mais caro em ${location.name}',
                type: NotificationType.warning,
                timestamp: DateTime.now(),
                isRead: false,
                data: {
                  'budgetId': budget.id,
                  'itemId': item.id,
                  'itemName': item.name,
                  'locationId': highPriceLocation,
                  'locationName': location.name,
                  'priceDifference':
                      ((highestPrice / avgPrice - 1) * 100).toStringAsFixed(0),
                },
              );

              await addNotification(notification);
            }
          }
        }
      }

      // 4. Alerta de gastos por categoria
      // Agrupar despesas do mês atual por categoria
      final categorySpending = <String, double>{};
      for (final cost in costs) {
        if (cost.data.isAfter(startOfMonth) && cost.data.isBefore(endOfMonth)) {
          final category = cost.category ?? 'Desconhecido';
          categorySpending[category] =
              (categorySpending[category] ?? 0) + cost.preco;
        }
      }

      // Comparar gastos por categoria com média dos últimos 3 meses
      // Para simplificar, geramos um alerta se o gasto atual for maior que o dobro da média
      for (final entry in categorySpending.entries) {
        if (entry.value > 500) {
          // Limite arbitrário para considerar gastos significativos
          final categoryAlertId =
              'category_spending_${entry.key}_${now.month}_${now.year}';
          final existing =
              notifications.value.any((n) => n.id == categoryAlertId);

          if (!existing) {
            final notification = NotificationItem(
              id: categoryAlertId,
              title: 'Gastos elevados em ${entry.key}',
              description:
                  'Você já gastou R\$ ${entry.value.toStringAsFixed(2)} em ${entry.key} este mês',
              type: NotificationType.info,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'category': entry.key,
                'amount': entry.value,
                'month': now.month,
                'year': now.year,
              },
            );

            await addNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar alertas de orçamento: $e');
    }
  }

  bool _hasExistingBudgetSavingsAlert(String budgetId) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    return notifications.value.any((notification) =>
        notification.id.startsWith('budget_savings_$budgetId') &&
        notification.timestamp.isAfter(oneWeekAgo));
  }

  // 2. Progresso de metas financeiras
  Future<void> _checkGoalProgress() async {
    try {
      final goals = await _goalsService.getAllGoals();

      for (final goal in goals) {
        final percentComplete = goal.percentComplete;

        // Meta atingida
        if (percentComplete >= 1.0) {
          final existing = _hasExistingGoalCompleteAlert(goal.id ?? '');

          if (!existing) {
            final notification = NotificationItem(
              id: 'goal_complete_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Meta alcançada! 🎉',
              description: 'Você atingiu sua meta "${goal.name}". Parabéns!',
              type: NotificationType.success,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'goalId': goal.id,
                'goalName': goal.name,
              },
            );

            await addNotification(notification);
          }
        }

        // Progresso significativo (75%)
        else if (percentComplete >= 0.75 && percentComplete < 0.9) {
          final existing = _hasExistingGoalProgressAlert(goal.id ?? '', 75);

          if (!existing) {
            final notification = NotificationItem(
              id: 'goal_progress75_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Progresso de meta',
              description:
                  'Você está a 75% de atingir sua meta "${goal.name}"!',
              type: NotificationType.info,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'goalId': goal.id,
                'goalName': goal.name,
                'progress': percentComplete,
              },
            );

            await addNotification(notification);
          }
        }

        // Progresso muito significativo (90%)
        else if (percentComplete >= 0.9 && percentComplete < 1.0) {
          final existing = _hasExistingGoalProgressAlert(goal.id ?? '', 90);

          if (!existing) {
            final notification = NotificationItem(
              id: 'goal_progress90_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Meta quase concluída!',
              description:
                  'Você está a ${((1.0 - percentComplete) * 100).toInt()}% de concluir sua meta "${goal.name}"!',
              type: NotificationType.info,
              timestamp: DateTime.now(),
              isRead: false,
              data: {
                'goalId': goal.id,
                'goalName': goal.name,
                'progress': percentComplete,
              },
            );

            await addNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar progresso das metas: $e');
    }
  }

  // 4. Dicas financeiras baseadas no padrão de gastos
  Future<void> _checkFinancialTips() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1);

      // Determina quando mostrar dicas (início do mês ou quando necessário)
      final dayOfMonth = now.day;
      final hasRecentTip = _hasRecentFinancialTip();

      if ((dayOfMonth <= 5 || dayOfMonth >= 25) && !hasRecentTip) {
        // Obter dados para personalizar a dica
        final currentMonthCosts =
            await _costsService.getCostsByDateRange(firstDayOfMonth, now);

        final lastMonthCosts = await _costsService.getCostsByDateRange(
            DateTime(lastMonth.year, lastMonth.month, 1),
            DateTime(now.year, now.month, 0));

        // Calcular totais
        final currentTotal =
            currentMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
        final lastMonthTotal =
            lastMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);

        // Analisar categorias com maiores gastos
        final categoryTotals = <String, double>{};
        for (final cost in currentMonthCosts) {
          categoryTotals[cost.descricaoDaDespesa] =
              (categoryTotals[cost.descricaoDaDespesa] ?? 0) + cost.preco;
        }

        // Encontrar categoria com maior gasto
        String? topCategory;
        double maxSpent = 0;
        categoryTotals.forEach((category, spent) {
          if (spent > maxSpent) {
            maxSpent = spent;
            topCategory = category;
          }
        });

        // Gerar dica baseada na análise
        String tipTitle;
        String tipContent;

        if (currentTotal > lastMonthTotal &&
            lastMonthTotal > 0 &&
            dayOfMonth < 20) {
          final increase = ((currentTotal / lastMonthTotal) - 1) * 100;
          tipTitle = 'Gastos aumentando';
          tipContent =
              'Seus gastos estão ${increase.toInt()}% maiores que no mesmo período do mês passado. Fique atento ao seu orçamento.';
        } else if (topCategory != null) {
          final percentage = (maxSpent / currentTotal) * 100;
          tipTitle = 'Dica de economia';
          tipContent =
              'Você gastou ${percentage.toInt()}% do seu orçamento em $topCategory. Revise se há oportunidades para economizar nesta categoria.';
        } else if (dayOfMonth >= 25) {
          tipTitle = 'Planeje o próximo mês';
          tipContent =
              'Faltam poucos dias para o próximo mês. Este é um ótimo momento para planejar seu orçamento e definir metas de economia.';
        } else {
          tipTitle = 'Dica financeira';
          tipContent =
              'Registrar pequenos gastos diários pode revelar até 15% do seu orçamento que passa despercebido. Experimente por uma semana!';
        }

        final notification = NotificationItem(
          id: 'financial_tip_${DateTime.now().millisecondsSinceEpoch}',
          title: tipTitle,
          description: tipContent,
          type: NotificationType.tip,
          timestamp: DateTime.now(),
          isRead: false,
          data: {
            'tipType': tipTitle.toLowerCase().replaceAll(' ', '_'),
          },
        );

        await addNotification(notification);
      }
    } catch (e) {
      debugPrint('Erro ao gerar dicas financeiras: $e');
    }
  }

  // 5. Conquistas financeiras
  Future<void> _checkAchievements() async {
    try {
      // Verificar se o usuário já tem notificação de conquista recente
      if (_hasRecentAchievement()) return;

      // Obter dados para analisar conquistas possíveis
      final revenues = await _revenuesService.getAllRevenues();
      final costs = await _costsService.getAllCosts();

      // Calcular saldo
      final totalRevenues =
          revenues.fold<double>(0, (sum, revenue) => sum + revenue.preco);
      final totalCosts = costs.fold<double>(0, (sum, cost) => sum + cost.preco);
      final balance = totalRevenues - totalCosts;

      // Verificar diferentes tipos de conquistas

      // Conquista 1: Primeira vez com saldo positivo significativo
      if (balance > 1000 && !_hasAchievementOfType('positive_balance')) {
        final notification = NotificationItem(
          id: 'achievement_positive_balance_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Conquista desbloqueada! 🏆',
          description:
              'Parabéns! Você atingiu um saldo positivo significativo. Continue com o bom trabalho!',
          type: NotificationType.achievement,
          timestamp: DateTime.now(),
          isRead: false,
          data: {
            'achievementType': 'positive_balance',
            'balance': balance,
          },
        );

        await addNotification(notification);
        return; // Retornar após adicionar uma conquista
      }

      // Conquista 2: Economias consistentes por múltiplos meses
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      final recentRevenues =
          await _revenuesService.getRevenuesByDateRange(threeMonthsAgo, now);
      final recentCosts =
          await _costsService.getCostsByDateRange(threeMonthsAgo, now);

      // Verificar se teve saldo positivo em todos os últimos 3 meses
      final monthlyBalances = <int, double>{};

      for (final revenue in recentRevenues) {
        final month = revenue.data.month;
        monthlyBalances[month] = (monthlyBalances[month] ?? 0) + revenue.preco;
      }

      for (final cost in recentCosts) {
        final month = cost.data.month;
        monthlyBalances[month] = (monthlyBalances[month] ?? 0) - cost.preco;
      }

      // Verificar se todos os 3 meses tiveram saldo positivo
      final uniqueMonths = monthlyBalances.keys.toSet();
      final allPositive = uniqueMonths.length >= 3 &&
          uniqueMonths.every((month) => (monthlyBalances[month] ?? 0) > 0);

      if (allPositive && !_hasAchievementOfType('consistent_savings')) {
        final notification = NotificationItem(
          id: 'achievement_consistent_savings_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Conquista desbloqueada! 🏆',
          description:
              'Você manteve suas economias no positivo por 3 meses consecutivos! Isso demonstra excelente disciplina financeira.',
          type: NotificationType.achievement,
          timestamp: DateTime.now(),
          isRead: false,
          data: {
            'achievementType': 'consistent_savings',
            'monthsCount': uniqueMonths.length,
          },
        );

        await addNotification(notification);
        return;
      }

      // Mais conquistas podem ser adicionadas aqui
    } catch (e) {
      debugPrint('Erro ao verificar conquistas: $e');
    }
  }

  // 6. Relatório mensal
  Future<void> _checkMonthlyReport() async {
    try {
      final now = DateTime.now();

      // Enviar relatório apenas no primeiro dia do mês
      if (now.day == 1 && !_hasMonthlyReportForCurrentMonth()) {
        final lastMonth = DateTime(now.year, now.month - 1);
        final firstDayLastMonth = DateTime(lastMonth.year, lastMonth.month, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0);

        // Buscar dados do mês anterior
        final lastMonthCosts = await _costsService.getCostsByDateRange(
            firstDayLastMonth, lastDayLastMonth);

        final lastMonthRevenues = await _revenuesService.getRevenuesByDateRange(
            firstDayLastMonth, lastDayLastMonth);

        // Calcular totais
        final totalCosts =
            lastMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
        final totalRevenues = lastMonthRevenues.fold<double>(
            0, (sum, revenue) => sum + revenue.preco);
        final balance = totalRevenues - totalCosts;

        // Gerar relatório
        final monthName = _getMonthName(lastMonth.month);
        final notification = NotificationItem(
          id: 'monthly_report_${lastMonth.year}_${lastMonth.month}',
          title: 'Relatório de $monthName está pronto',
          description: 'Receitas: R\$${totalRevenues.toStringAsFixed(2)}, '
              'Despesas: R\$${totalCosts.toStringAsFixed(2)}, '
              'Saldo: R\$${balance.toStringAsFixed(2)}',
          type: NotificationType.report,
          timestamp: DateTime.now(),
          isRead: false,
          data: {
            'month': lastMonth.month,
            'year': lastMonth.year,
            'revenues': totalRevenues,
            'costs': totalCosts,
            'balance': balance,
          },
        );

        await addNotification(notification);
      }
    } catch (e) {
      debugPrint('Erro ao gerar relatório mensal: $e');
    }
  }

  // Métodos auxiliares

  bool _hasExistingBudgetAlert(String category) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    return notifications.value.any((notification) =>
        notification.id.startsWith('budget_$category') &&
        notification.timestamp.isAfter(oneWeekAgo));
  }

  // Atualize o método _hasExistingBudgetExceededAlert para usar budgetId

  bool _hasExistingGoalCompleteAlert(String goalId) {
    return notifications.value.any(
        (notification) => notification.id.startsWith('goal_complete_$goalId'));
  }

  bool _hasExistingGoalProgressAlert(String goalId, int progressPercent) {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    return notifications.value.any((notification) =>
        notification.id.startsWith('goal_progress${progressPercent}_$goalId') &&
        notification.timestamp.isAfter(twoWeeksAgo));
  }

  bool _hasRecentFinancialTip() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    return notifications.value.any((notification) =>
        notification.id.startsWith('financial_tip_') &&
        notification.timestamp.isAfter(oneWeekAgo));
  }

  bool _hasRecentAchievement() {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));

    return notifications.value.any((notification) =>
        notification.id.startsWith('achievement_') &&
        notification.timestamp.isAfter(oneMonthAgo));
  }

  bool _hasAchievementOfType(String type) {
    return notifications.value
        .any((notification) => notification.id.startsWith('achievement_$type'));
  }

  bool _hasMonthlyReportForCurrentMonth() {
    final now = DateTime.now();

    return notifications.value.any((notification) =>
        notification.id == 'monthly_report_${now.year}_${now.month}');
  }

  /// Verifica se já existe uma notificação recente para um pagamento específico
  /// @param paymentId ID do pagamento para verificar
  /// @return true se uma notificação já existe para este pagamento nos últimos dias
  bool _hasExistingPaymentAlert(String paymentId) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return notifications.value.any((notification) =>
        notification.id.startsWith('payment_due_$paymentId') &&
        notification.timestamp.isAfter(threeDaysAgo));
  }

// E altere o método _hasExistingBudgetAlert para usar o ID do orçamento:

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];

    return months[month - 1];
  }

  // 3. Pagamentos próximos ao vencimento
  Future<void> _checkUpcomingPayments() async {
    try {
      final now = DateTime.now();
      final costs = await _costsService.getAllCosts();

      final upcomingPayments = costs.where((cost) {
        final daysUntilDue = cost.data.difference(now).inDays;
        return (cost.recorrente && !cost.pago) ||
            (daysUntilDue >= 0 && daysUntilDue <= 5 && !cost.pago);
      }).toList();

      for (final payment in upcomingPayments) {
        final daysUntilDue = payment.data.difference(now).inDays;
        final existing = _hasExistingPaymentAlert(payment.id);

        if (!existing) {
          final daysText = daysUntilDue == 0
              ? 'hoje'
              : daysUntilDue == 1
                  ? 'amanhã'
                  : 'em $daysUntilDue dias';

          final recurrentText = payment.recorrente ? ' (Recorrente)' : '';

          final notification = NotificationItem(
            id: 'payment_due_${payment.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Pagamento próximo$recurrentText',
            description:
                '${payment.tipoDespesa} de R\$${payment.preco.toStringAsFixed(2)} vence $daysText.',
            type: NotificationType.reminder,
            timestamp: DateTime.now(),
            isRead: false,
            data: {
              'paymentId': payment.id,
              'paymentName': payment.tipoDespesa,
              'amount': payment.preco,
              'dueDate': payment.data.toIso8601String(),
              'isRecurrent': payment.recorrente,
            },
          );

          await addNotification(notification);

          // NOVO: Agendar notificações push adicionais para este pagamento
          await _schedulePaymentPushNotifications(payment);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar pagamentos próximos: $e');
    }
  }
}
