import 'package:economize/data/goal_dao.dart';
import 'package:flutter/foundation.dart';

class GoalsService {
  final GoalsDAO _goalsDAO = GoalsDAO();

  Future<List<Goal>> getAllGoals() async {
    try {
      return await _goalsDAO.findAll();
    } catch (e) {
      debugPrint('Erro ao buscar metas: $e');
      return [];
    }
  }

  Future<Goal?> getGoalById(String id) async {
    try {
      return await _goalsDAO.findById(id);
    } catch (e) {
      debugPrint('Erro ao buscar meta por ID: $e');
      return null;
    }
  }

  // Outros métodos relacionados a metas podem ser adicionados aqui
}
