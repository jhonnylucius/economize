import 'package:economize/model/budget/budget.dart';
import 'package:economize/utils/budget_calculator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LocationComparisonCard extends StatelessWidget {
  final Budget budget;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  LocationComparisonCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationTotals = BudgetCalculator.calculateTotalsByLocation(budget);
    final savingsPercentage =
        BudgetCalculator.calculateSavingsPercentageByLocation(budget);

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparação entre Locais',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildLocationsList(context, locationTotals, savingsPercentage),
            const SizedBox(height: 16),
            _buildComparisonChart(context, locationTotals),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList(
    BuildContext context,
    Map<String, double> totals,
    Map<String, double> savings,
  ) {
    final theme = Theme.of(context);
    final sortedLocations =
        budget.locations.toList()
          ..sort((a, b) => (totals[a.id] ?? 0).compareTo(totals[b.id] ?? 0));

    return Column(
      children:
          sortedLocations.map((location) {
            final total = totals[location.id] ?? 0;
            final saving = savings[location.id] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              currencyFormat.format(total),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  (0.7 * 255).toInt(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSavingsBadge(context, saving),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _calculateProgress(total, totals),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      _getSavingsColor(context, saving),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSavingsBadge(BuildContext context, double savingPercentage) {
    if (savingPercentage <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getSavingsColor(context, savingPercentage),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${savingPercentage.toStringAsFixed(1)}% economia',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComparisonChart(
    BuildContext context,
    Map<String, double> totals,
  ) {
    return const SizedBox(); // Placeholder para futuro gráfico
  }

  double _calculateProgress(double value, Map<String, double> totals) {
    final maxTotal = totals.values.reduce((a, b) => a > b ? a : b);
    return maxTotal > 0 ? value / maxTotal : 0;
  }

  Color _getSavingsColor(BuildContext context, double savingPercentage) {
    final theme = Theme.of(context);

    if (savingPercentage <= 0) return theme.colorScheme.outline;
    if (savingPercentage < 5) return theme.colorScheme.tertiary;
    if (savingPercentage < 10) return theme.colorScheme.primary;
    return theme.colorScheme.primaryContainer;
  }
}
