import 'package:economize/accounts/service/account_service.dart';
import 'package:economize/data/revenues_dao.dart';
import 'package:economize/model/revenues.dart';
import 'package:flutter/material.dart';

class RevenuesService {
  final RevenuesDAO _revenuesDAO = RevenuesDAO();
  final AccountService _accountService = AccountService();

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
  Future<void> saveRevenue(Revenues revenue) async {
    // 1. Sua lógica existente
    await _revenuesDAO.insert(revenue);
    _cachedRevenues.add(revenue);

    // 2. Integração com o AccountService
    if (revenue.accountId != null) {
      await _accountService.handleNewTransaction(
        accountId: revenue.accountId!,
        amount: revenue.preco,
        isRevenue: true, // É uma receita
      );
    }

    debugPrint('✅ Receita salva e saldo da conta atualizado.');
  }

  /// Deleta uma receita e reverte o valor no saldo da conta.
  Future<void> deleteRevenue(String id) async {
    Revenues? revenueToDelete;

    // --- CORREÇÃO APLICADA AQUI ---
    // 1. Tenta encontrar no cache primeiro.
    try {
      revenueToDelete = _cachedRevenues.firstWhere((r) => r.id == id);
    } on StateError {
      // 2. Se não encontrar no cache (StateError), busca no banco.
      revenueToDelete = await _revenuesDAO.findById(id);
    }
    // --- FIM DA CORREÇÃO ---

    if (revenueToDelete == null) {
      debugPrint('❌ Receita com id $id não encontrada para deletar.');
      return;
    }

    await _revenuesDAO.delete(id);
    _cachedRevenues.removeWhere((revenue) => revenue.id == id);

    if (revenueToDelete.accountId != null) {
      await _accountService.handleDeletedTransaction(
        accountId: revenueToDelete.accountId!,
        amount: revenueToDelete.preco,
        isRevenue: true,
      );
    }
    debugPrint('✅ Receita deletada e saldo da conta revertido.');
  }
}
