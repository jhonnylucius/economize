import 'package:economize/data/costs_dao.dart';
import 'package:economize/data/revenues_dao.dart';
import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class ReportService {
  final CostsDAO _costsDAO = CostsDAO();
  final RevenuesDAO _revenuesDAO = RevenuesDAO();

  Future<Map<String, dynamic>> generateReport({
    required String type,
    required String period,
    required String specificType,
  }) async {
    try {
      if (type == 'receitas') {
        final List<Revenues> items = await _revenuesDAO.findAll();

        // Filtra apenas por tipo específico se necessário
        final List<Revenues> finalItems;
        if (specificType == 'Todas') {
          finalItems = items; // Retorna todas as receitas
        } else {
          finalItems = items
              .where((item) => item.tipoReceita == specificType)
              .toList(); // Retorna apenas as receitas do tipo específico
        }

        // Calcula totais
        final totals = <String, double>{};
        var total = 0.0;
        for (var item in finalItems) {
          totals[item.tipoReceita] =
              (totals[item.tipoReceita] ?? 0) + item.preco;
          total += item.preco;
        }

        // Converter os objetos Revenues para mapas
        final List<Map<String, dynamic>> itemsAsMaps = finalItems
            .map((item) => {
                  'descricaoDaReceita': item.descricaoDaReceita,
                  'tipoReceita': item.tipoReceita,
                  'preco': item.preco,
                  'data': item.data,
                  'id': item.id,
                })
            .toList();

        return {
          'success': true,
          'items':
              itemsAsMaps, // Retornando a lista de mapas em vez dos objetos
          'totals': totals,
          'total': total,
        };
      } else {
        // Lógica para despesas
        final List<Costs> items = await _costsDAO.findAll();

        // Filtra apenas por tipo específico
        final List<Costs> finalItems;
        if (specificType == 'Todas') {
          finalItems = items; // Retorna todas as despesas
        } else {
          finalItems = items
              .where((item) => item.tipoDespesa == specificType)
              .toList(); // Retorna apenas as despesas do tipo específico
        }

        // Calcula totais
        final totals = <String, double>{};
        var total = 0.0;
        for (var item in finalItems) {
          totals[item.tipoDespesa] =
              (totals[item.tipoDespesa] ?? 0) + item.preco;
          total += item.preco;
        }

        // Converter os objetos Costs para mapas
        final List<Map<String, dynamic>> itemsAsMaps = finalItems
            .map((item) => {
                  'descricaoDaDespesa': item.descricaoDaDespesa,
                  'tipoDespesa': item.tipoDespesa,
                  'preco': item.preco,
                  'data': item.data,
                  'id': item.id,
                })
            .toList();

        return {
          'success': true,
          'items':
              itemsAsMaps, // Retornando a lista de mapas em vez dos objetos
          'totals': totals,
          'total': total,
        };
      }
    } catch (e) {
      Logger().e('Erro no generateReport: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Retorna lista de meses disponíveis no formato MM/YYYY
  Future<List<String>> getAvailablePeriods() async {
    try {
      final Set<String> periods = {};

      // Busca períodos das receitas
      final revenues = await _revenuesDAO.findAll();
      for (var revenue in revenues) {
        periods.add(
          '${revenue.data.month.toString().padLeft(2, '0')}/${revenue.data.year}',
        );
      }

      // Busca períodos das despesas
      final costs = await _costsDAO.findAll();
      for (var cost in costs) {
        final date = DateFormat('dd/MM/yyyy').parse(cost.data as String);
        periods.add('${date.month.toString().padLeft(2, '0')}/${date.year}');
      }

      return periods.toList()..sort((a, b) => b.compareTo(a));
    } catch (e) {
      Logger().e('Erro ao buscar períodos: $e');
      return [];
    }
  }

  // Retorna tipos disponíveis para cada categoria
  Future<Map<String, List<String>>> getAvailableTypes() async {
    try {
      final Set<String> costTypes = {};
      final Set<String> revenueTypes = {};

      final costs = await _costsDAO.findAll();
      for (var cost in costs) {
        costTypes.add(cost.tipoDespesa);
      }

      final revenues = await _revenuesDAO.findAll();
      for (var revenue in revenues) {
        revenueTypes.add(revenue.tipoReceita);
      }

      return {
        'despesas': ['Todas', ...costTypes.toList()..sort()],
        'receitas': ['Todas', ...revenueTypes.toList()..sort()],
      };
    } catch (e) {
      Logger().e('Erro ao buscar tipos: $e');
      return {
        'despesas': ['Todas'],
        'receitas': ['Todas'],
      };
    }
  }
}
