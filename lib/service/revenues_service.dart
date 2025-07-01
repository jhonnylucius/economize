import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/data/revenues_dao.dart';
import 'package:economize/model/revenues.dart';
import 'package:flutter/material.dart';

class RevenuesService {
  final RevenuesDAO _revenuesDAO = RevenuesDAO();

  List<Revenues> _cachedRevenues = [];

  Future<List<Revenues>> getAllRevenues() async {
    _cachedRevenues = await _revenuesDAO.findAll();
    return _cachedRevenues;
  }

  List<Revenues> getRevenuesSync() {
    return _cachedRevenues;
  }

  Future<List<Revenues>> getRevenuesByDateRange(
      DateTime start, DateTime end) async {
    try {
      return await _revenuesDAO.findByPeriod(start, end);
    } catch (e) {
      debugPrint('Erro ao buscar receitas por período: $e');
      return [];
    }
  }

  /// Salva uma nova receita e atualiza o saldo da conta.
  Future<void> saveRevenue(
      Revenues revenue, AccountService accountService) async {
    await _revenuesDAO.insert(revenue);
    _cachedRevenues.add(revenue);

    if (revenue.accountId != null) {
      await accountService.handleNewTransaction(
        accountId: revenue.accountId!,
        amount: revenue.preco,
        isRevenue: true,
        date: revenue.data,
      );
    }

    debugPrint('✅ Receita salva e saldo da conta atualizado.');
  }

  /// Deleta uma receita e reverte o valor no saldo da conta.
  Future<void> deleteRevenue(String id, AccountService accountService) async {
    Revenues? revenueToDelete;
    try {
      revenueToDelete = _cachedRevenues.firstWhere((r) => r.id == id);
    } on StateError {
      revenueToDelete = await _revenuesDAO.findById(id);
    }

    if (revenueToDelete == null) {
      debugPrint('❌ Receita com id $id não encontrada para deletar.');
      return;
    }

    await _revenuesDAO.delete(id);
    _cachedRevenues.removeWhere((revenue) => revenue.id == id);

    if (revenueToDelete.accountId != null) {
      await accountService.handleDeletedTransaction(
        accountId: revenueToDelete.accountId!,
        amount: revenueToDelete.preco,
        isRevenue: true,
      );
    }
    debugPrint('✅ Receita deletada e saldo da conta revertido.');
  }
}
