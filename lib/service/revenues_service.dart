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

  // Método síncrono para obter receitas sem acessar o banco
  List<Revenues> getRevenuesSync() {
    return _cachedRevenues;
  }

  Future<List<Revenues>> getRevenuesByDateRange(
      DateTime start, DateTime end) async {
    // Se já tiver esses métodos implementados, não precisa reescrevê-los
    try {
      return await _revenuesDAO.findByPeriod(start, end);
    } catch (e) {
      debugPrint('Erro ao buscar receitas por período: $e');
      return []; // Retorna lista vazia em caso de erro
    }
  }

  Future<void> saveRevenue(Revenues revenue) async {
    await _revenuesDAO.insert(revenue);
    // Atualizar cache
    _cachedRevenues.add(revenue);
  }

  Future<void> deleteRevenue(String id) async {
    await _revenuesDAO.delete(id);
    // Atualizar cache
    _cachedRevenues.removeWhere((revenue) => revenue.id == id);
  }
}
