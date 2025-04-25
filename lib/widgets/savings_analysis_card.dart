import 'package:economize/model/budget/budget.dart';
import 'package:economize/utils/budget_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsAnalysisCard extends StatelessWidget {
  final Budget budget;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  SavingsAnalysisCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = BudgetUtils.analyzeBudgetSavings(budget);

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Economia',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildSavingsOverview(context, analysis),
            Divider(
              height: 32,
              color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
            ),
            _buildRecommendations(
              context,
              analysis['recommendations'] as List<Map<String, dynamic>>,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsOverview(
    BuildContext context,
    Map<String, dynamic> analysis,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSavingsStat(
              context,
              'Economia Total',
              currencyFormat.format(analysis['totalSaving'] as double),
              Icons.savings,
              theme.colorScheme.primary,
            ),
            _buildSavingsStat(
              context,
              'Percentual',
              '${(analysis['savingPercentage'] as double).toStringAsFixed(1)}%',
              Icons.percent,
              theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Melhor Local para Compras: ${budget.locations.firstWhere((loc) => loc.id == analysis['bestLocation']).name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(
    BuildContext context,
    List<Map<String, dynamic>> recommendations,
  ) {
    final theme = Theme.of(context);

    if (recommendations.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma recomendação disponível',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendações de Compra',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.take(3).map((rec) {
          final saving = rec['savingPercentage'] as double;
          return ListTile(
            leading: Icon(
              Icons.shopping_cart,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              rec['item'] as String,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            subtitle: Text(
              'Economia de ${saving.toStringAsFixed(1)}% comprando em ${budget.locations.firstWhere((loc) => loc.id == rec['bestLocation']).name}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
              ),
            ),
            trailing: Text(
              currencyFormat.format(rec['bestPrice']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }),
      ],
    );
  }
}
