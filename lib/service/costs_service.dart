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

  Future<void> saveCost(Costs cost) async {
    await _costsDAO.insert(cost);
    _cachedCosts.add(cost);

    // ADICIONADO: Verificar se precisa de notificação IMEDIATA (APENAS ESTA LINHA)
    if (!cost.pago) {
      await _checkImmediateNotification(cost);
    }

    debugPrint('✅ Despesa salva: ${cost.tipoDespesa}');
  }

  // NOVO MÉTODO ADICIONADO (NÃO MEXE EM NADA EXISTENTE)
  Future<void> _checkImmediateNotification(Costs cost) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final costDate = DateTime(cost.data.year, cost.data.month, cost.data.day);
      final daysUntilDue = costDate.difference(today).inDays;

      // Se vence hoje, amanhã ou em até 5 dias, notificar AGORA
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

        // Notificação IMEDIATA
        await notificationService.showNotification(
          id: cost.id.hashCode,
          title: title,
          body: body,
          payload: 'expense_immediate_${cost.id}',
          channelId: 'economize_payments',
        );

        debugPrint('🔔 Notificação imediata enviada: ${cost.tipoDespesa}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar notificação imediata: $e');
    }
  }

  Future<void> deleteCost(String id) async {
    // APENAS ALTERAR ESTA PARTE: Cancelar notificações antes de deletar
    try {
      final notificationService = PushNotificationService(); // TROCAR AQUI
      await notificationService
          .cancelNotification(id.hashCode); // E TROCAR AQUI
      debugPrint('✅ Notificações canceladas para despesa: $id');
    } catch (e) {
      debugPrint('❌ Erro ao cancelar notificações: $e');
    }

    await _costsDAO.delete(id);
    // Atualizar cache
    _cachedCosts.removeWhere((cost) => cost.id == id);
  }
}
