import 'package:economize/data/costs_dao.dart';
import 'package:economize/model/costs.dart';
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
    // Atualizar cache
    _cachedCosts.add(cost);
  }

  Future<void> deleteCost(String id) async {
    await _costsDAO.delete(id);
    // Atualizar cache
    _cachedCosts.removeWhere((cost) => cost.id == id);
  }
}
