import 'dart:async';
import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/push_notification_service.dart';
import 'package:economize/model/costs.dart'; // ADICIONAR ESTE IMPORT
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // ADICIONAR ESTE IMPORT

class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final CostsService _costsService = CostsService();
  final PushNotificationService _pushService = PushNotificationService();

  Timer? _dailyTimer;
  bool _isInitialized = false;

  late AccountService _accountService;

  void setAccountService(AccountService service) {
    _accountService = service;
  }

  /// Inicializa o scheduler que roda diariamente às 9h
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Executar verificação imediata
    await _checkAndScheduleNotifications();

    // Agendar verificação diária às 9h da manhã
    _scheduleDailyCheck();

    _isInitialized = true;
    debugPrint('🔔 Scheduler de notificações inicializado');
  }

  /// Agenda verificação diária às 9h da manhã
  void _scheduleDailyCheck() {
    final now = DateTime.now();
    final nextNineAM = DateTime(now.year, now.month, now.day, 9, 0);

    // Se já passou das 9h hoje, agendar para amanhã
    final targetTime = nextNineAM.isBefore(now)
        ? nextNineAM.add(const Duration(days: 1))
        : nextNineAM;

    final duration = targetTime.difference(now);

    _dailyTimer = Timer(duration, () {
      _checkAndScheduleNotifications();
      // Reagendar para o próximo dia
      _scheduleDailyCheck();
    });

    debugPrint('⏰ Próxima verificação agendada para: $targetTime');
  }

  /// Verifica e agenda notificações APENAS para despesas que vencem entre 5-0 dias
  Future<void> _checkAndScheduleNotifications() async {
    try {
      debugPrint('🔍 Verificando despesas para notificação...');

      final allCosts = await _costsService.getAllCosts();
      final now = DateTime.now();

      // Filtrar apenas despesas não pagas com vencimento entre 5 dias e hoje
      final upcomingCosts = allCosts.where((cost) {
        if (cost.pago) return false; // Ignora despesas já pagas

        final daysUntilDue = cost.data.difference(now).inDays;
        return daysUntilDue >= 0 && daysUntilDue <= 5;
      }).toList();

      debugPrint(
          '📋 Encontradas ${upcomingCosts.length} despesas próximas do vencimento');

      // Agendar notificações para cada despesa próxima
      for (final cost in upcomingCosts) {
        await _scheduleNotificationForCost(cost);
      }

      // Para despesas recorrentes, verificar se precisa criar nova ocorrência
      await _handleRecurrentExpenses(allCosts);
    } catch (e) {
      debugPrint('❌ Erro na verificação de notificações: $e');
    }
  }

  /// Agenda notificação para uma despesa específica
  Future<void> _scheduleNotificationForCost(Costs cost) async {
    try {
      final now = DateTime.now();
      final daysUntilDue = cost.data.difference(now).inDays;

      // Determinar título baseado nos dias restantes
      String title;
      String body;

      if (daysUntilDue == 0) {
        title = '🚨 VENCIMENTO HOJE!';
        body =
            '${cost.tipoDespesa} vence hoje - R\$ ${cost.preco.toStringAsFixed(2)}';
      } else if (daysUntilDue == 1) {
        title = '⚠️ Vence amanhã!';
        body =
            '${cost.tipoDespesa} vence amanhã - R\$ ${cost.preco.toStringAsFixed(2)}';
      } else {
        title = '📅 Vencimento em $daysUntilDue dias';
        body =
            '${cost.tipoDespesa} vence em $daysUntilDue dias - R\$ ${cost.preco.toStringAsFixed(2)}';
      }

      // Agendar para as 9h da manhã do dia do vencimento
      final notificationTime = DateTime(
        cost.data.year,
        cost.data.month,
        cost.data.day,
        9, // 9h da manhã
        0,
      );

      // Só agendar se for no futuro
      if (notificationTime.isAfter(now)) {
        await _pushService.scheduleNotification(
          id: cost.id.hashCode,
          title: title,
          body: body,
          scheduledDate: notificationTime,
          payload: 'expense_${cost.id}',
          channelId: 'economize_payments',
        );

        debugPrint(
            '✅ Notificação agendada: ${cost.tipoDespesa} para $notificationTime');
      } else {
        // Se for hoje mas já passou das 9h, enviar notificação imediata
        await _pushService.showNotification(
          id: cost.id.hashCode,
          title: title,
          body: body,
          payload: 'expense_${cost.id}',
          channelId: 'economize_payments',
        );

        debugPrint('✅ Notificação imediata enviada: ${cost.tipoDespesa}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao agendar notificação para ${cost.tipoDespesa}: $e');
    }
  }

  /// CORRIGIDO: Gerencia despesas recorrentes criando nova ocorrência apenas quando necessário
  Future<void> _handleRecurrentExpenses(List<Costs> allCosts) async {
    try {
      final now = DateTime.now();
      final recurrentCosts =
          allCosts.where((cost) => cost.recorrente && cost.pago).toList();

      debugPrint(
          '🔄 Verificando ${recurrentCosts.length} despesas recorrentes pagas...');

      for (final paidRecurrentCost in recurrentCosts) {
        // Calcular a próxima data de vencimento (próximo mês)
        final nextMonthDate = DateTime(
          paidRecurrentCost.data.year,
          paidRecurrentCost.data.month + 1,
          paidRecurrentCost.data.day,
        );

        // Verificar se já existe uma próxima ocorrência não paga
        final hasNextOccurrence = allCosts.any((cost) =>
            cost.tipoDespesa == paidRecurrentCost.tipoDespesa &&
            cost.data.year == nextMonthDate.year &&
            cost.data.month == nextMonthDate.month &&
            cost.data.day == nextMonthDate.day &&
            !cost.pago); // IMPORTANTE: deve ser não paga

        // Se não existe e faltam 5 dias ou menos para a próxima, criar
        if (!hasNextOccurrence && nextMonthDate.difference(now).inDays <= 5) {
          debugPrint(
              '📝 Criando nova ocorrência recorrente para: ${paidRecurrentCost.tipoDespesa}');

          // AGORA POSSO CRIAR A NOVA DESPESA RECORRENTE:
          final newRecurrentCost = Costs(
            id: const Uuid().v4(),
            data: nextMonthDate,
            preco: paidRecurrentCost.preco,
            descricaoDaDespesa: paidRecurrentCost.descricaoDaDespesa,
            tipoDespesa: paidRecurrentCost.tipoDespesa,
            recorrente: true,
            pago: false,
            category:
                paidRecurrentCost.category ?? paidRecurrentCost.tipoDespesa,
          );

          // Salvar a nova despesa
          await _costsService.saveCost(newRecurrentCost, _accountService);

          debugPrint(
              '✅ Nova despesa recorrente criada: ${newRecurrentCost.tipoDespesa} para $nextMonthDate');

          // Agendar notificação para a nova despesa se estiver dentro do prazo de 5 dias
          final daysUntilNewDue = nextMonthDate.difference(now).inDays;
          if (daysUntilNewDue >= 0 && daysUntilNewDue <= 5) {
            await _scheduleNotificationForCost(newRecurrentCost);
          }
        } else if (hasNextOccurrence) {
          debugPrint(
              'ℹ️ Próxima ocorrência já existe para: ${paidRecurrentCost.tipoDespesa}');
        } else {
          debugPrint(
              '⏳ Ainda não é hora de criar próxima ocorrência para: ${paidRecurrentCost.tipoDespesa} (faltam ${nextMonthDate.difference(now).inDays} dias)');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao gerenciar despesas recorrentes: $e');
    }
  }

  /// Para fins de debug - força verificação manual
  Future<void> forceCheck() async {
    debugPrint('🔧 Verificação manual forçada');
    await _checkAndScheduleNotifications();
  }

  /// Cancela todos os timers
  void dispose() {
    _dailyTimer?.cancel();
    _isInitialized = false;
    debugPrint('🔔 Scheduler de notificações encerrado');
  }
}
