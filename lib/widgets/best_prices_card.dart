import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/utils/budget_calculator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BestPricesCard extends StatelessWidget {
  final Budget budget;
  final CurrencyService _currencyService = CurrencyService();

  BestPricesCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestPricesByLocation = BudgetCalculator.getBestPricesByLocation(
      budget,
    );

    return Card(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Melhores Preços por Local',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...budget.locations.map((location) {
              final items = bestPricesByLocation[location.id] ?? [];
              if (items.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      location.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${items.length} itens com melhor preço',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    leading: Icon(
                      Icons.store,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _buildItemsList(context, items),
                  Divider(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.2 * 255).toInt(),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<BudgetItem> items) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.take(5).map((item) {
          final savings = item.calculateSavings();
          final savingsPercentage = savings / item.bestPrice * 100;

          return Card(
            margin: const EdgeInsets.all(4),
            color: theme.colorScheme.surface,
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyService.formatCurrency(item.bestPrice),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (savings > 0)
                    Text(
                      'Economia: ${savingsPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
