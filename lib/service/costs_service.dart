import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/data/costs_dao.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/service/push_notification_service.dart';
import 'package:flutter/material.dart';

class CostsService {
  final CostsDAO _costsDAO = CostsDAO();

  List<Costs> _cachedCosts = [];

  Future<List<Costs>> getAllCosts() async {
    _cachedCosts = await _costsDAO.findAll();
    return _cachedCosts;
  }

  // Método síncrono para obter custos sem acessar o banco
  List<Costs> getCostsSync() {
    return _cachedCosts;
  }

  Future<List<Costs>> getCostsByDateRange(DateTime start, DateTime end) async {
    // Se já tiver esses métodos implementados, não precisa reescrevê-los
    try {
      return await _costsDAO.findByPeriod(start, end);
    } catch (e) {
      debugPrint('Erro ao buscar custos por período: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  // TROCAR ESTE MÉTODO no CostsService:
  Future<void> saveCost(Costs cost, AccountService accountService) async {
    await _costsDAO.insert(cost);

    // ✅ NÃO adicionar no cache ainda - vamos recarregar tudo no final

    if (!cost.pago) {
      await _checkImmediateNotification(cost);
    }

    if (cost.accountId != null) {
      await accountService.handleNewTransaction(
        accountId: cost.accountId!,
        amount: cost.preco,
        isRevenue: false,
        date: cost.data,
      );
    }

// ✅ MOVER PARA FORA - Recorrência independe da conta
    if (cost.recorrente && !cost.isLancamentoFuturo) {
      await _createRecurringCosts(cost);
    }

    // ✅ RECARREGAR CACHE COMPLETO APÓS TODAS AS OPERAÇÕES
    await getAllCosts(); // Isso vai atualizar o _cachedCosts corretamente

    debugPrint('✅ Despesa salva e cache atualizado: ${cost.tipoDespesa}');
  }

  Future<void> _createRecurringCosts(Costs originalCost) async {
    for (int i = 1; i <= 12; i++) {
      final nextDate = DateTime(
        originalCost.data.year,
        originalCost.data.month + i,
        originalCost.data.day,
      );

      final futureCost = Costs(
        id: '${originalCost.id}_future_${nextDate.year}_${nextDate.month}',
        preco: originalCost.preco,
        descricaoDaDespesa: originalCost.descricaoDaDespesa,
        tipoDespesa: originalCost.tipoDespesa,
        data: nextDate,
        isLancamentoFuturo: true, // ✅ Marca como futuro
        recorrenciaOrigemId: originalCost.id, // ✅ Vincula ao original
        recorrente: originalCost.recorrente,
        pago: false, // Inicialmente não pago
        accountId: originalCost.accountId, // Mantém a mesma conta
        // Adicione outros campos obrigatórios se necessário, copiando de originalCost
      );

      await _costsDAO.insert(futureCost);
    }
  }

  Future<List<Costs>> getCostsForCalculations() async {
    final allCosts = await getAllCosts();
    final now = DateTime.now();
    return allCosts
        .where((cost) =>
            !cost.isLancamentoFuturo ||
            cost.data.isBefore(now.add(Duration(days: 1))))
        .toList();
  }

  // NOVO MÉTODO ADICIONADO (NÃO MEXE EM NADA EXISTENTE)
  Future<void> _checkImmediateNotification(Costs cost) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ✅ CORREÇÃO: Normalizar data da despesa
      final dueDate = DateTime(cost.data.year, cost.data.month, cost.data.day);
      final daysUntilDue = dueDate.difference(today).inDays;

      debugPrint(
          '📊 Verificando notificação para ${cost.tipoDespesa}: $daysUntilDue dias');

      // ✅ FILTRO CORRETO: Apenas entre 0 e 5 dias
      if (daysUntilDue >= 0 && daysUntilDue <= 5) {
        final notificationService = PushNotificationService();

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

        // ✅ Notificação IMEDIATA só para despesas que realmente vencem em breve
        await notificationService.showNotification(
          id: '${cost.id}_immediate_${today.year}${today.month}${today.day}'
              .hashCode,
          title: title,
          body: body,
          payload: 'expense_immediate_${cost.id}',
          channelId: 'economize_payments',
        );

        debugPrint(
            '🔔 Notificação imediata enviada: ${cost.tipoDespesa} ($daysUntilDue dias)');
      } else {
        debugPrint(
            '⏭️ ${cost.tipoDespesa} vence em $daysUntilDue dias - sem notificação');
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação imediata: $e');
    }
  }

  /// Deleta uma despesa e reverte o valor no saldo da conta.
  Future<void> deleteCost(String id, AccountService accountService) async {
    Costs? costToDelete;
    try {
      costToDelete = _cachedCosts.firstWhere((c) => c.id == id);
    } on StateError {
      costToDelete = await _costsDAO.findById(id);
    }

    if (costToDelete == null) {
      debugPrint('❌ Custo com id $id não encontrado para deletar.');
      return;
    }

    try {
      final notificationService = PushNotificationService();
      await notificationService.cancelNotification(id.hashCode);
    } catch (e) {
      debugPrint('❌ Erro ao cancelar notificações: $e');
    }

    await _costsDAO.delete(id);
    _cachedCosts.removeWhere((cost) => cost.id == id);

    if (costToDelete.accountId != null) {
      await accountService.handleDeletedTransaction(
        accountId: costToDelete.accountId!,
        amount: costToDelete.preco,
        isRevenue: false,
      );
    }
    debugPrint('✅ Despesa deletada e saldo da conta revertido.');
  }
}
