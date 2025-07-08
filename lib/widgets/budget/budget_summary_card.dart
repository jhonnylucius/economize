import 'package:economize/model/budget/budget_summary.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;
  final String title;
  final Map<String, String>? locationNames;
  final bool showDetails;
  final CurrencyService _currencyService = CurrencyService();

  BudgetSummaryCard({
    super.key,
    required this.summary,
    this.title = 'Resumo',
    this.locationNames,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Card(
      color: themeManager.getSummaryCardBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMainSummary(context),
            if (showDetails) ...[
              Divider(
                height: 32,
                color: themeManager.getSummaryCardTextColor().withValues(
                      alpha: (0.2 * 255).toInt().toDouble(),
                    ),
              ),
              _buildLocationDetails(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final savingsPercentage = summary.totalOriginal > 0
        ? (summary.savings / summary.totalOriginal * 100)
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeManager.getSummaryCardTitleColor(),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Chip(
          label: Text(
            'Economia: ${savingsPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: themeManager.getSummaryCardChipTextColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: themeManager.getSummaryCardChipColor(),
        ),
      ],
    );
  }

  Widget _buildMainSummary(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem(
          context,
          'Total Original',
          _currencyService.formatCurrency(summary.totalOriginal),
          themeManager.getSummaryCardTitleColor(),
          Icons.shopping_cart,
        ),
        _buildSummaryItem(
          context,
          'Melhor Preço',
          _currencyService.formatCurrency(summary.totalOptimized),
          themeManager.getSummaryCardTitleColor(),
          Icons.verified,
        ),
        _buildSummaryItem(
          context,
          'Economia',
          _currencyService.formatCurrency(summary.savings),
          themeManager.getSummaryCardTitleColor(),
          Icons.savings,
        ),
      ],
    );
  }

  Widget _buildLocationDetails(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    final sortedLocations = summary.totalByLocation.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparativo por Local',
          style: TextStyle(
            color: themeManager.getSummaryCardTextColor(),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedLocations.map((entry) {
          final locationName =
              locationNames?[entry.key] ?? 'Local ${entry.key}';
          final total = entry.value;
          final percentage = (total / summary.totalOriginal) * 100;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        locationName,
                        style: TextStyle(
                          color: themeManager.getSummaryCardTextColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _currencyService.formatCurrency(total),
                      style: TextStyle(
                        color: themeManager.getSummaryCardTextColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: themeManager
                      .getSummaryCardTextColor()
                      .withValues(alpha: (0.1 * 255).toInt().toDouble()),
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(context, percentage),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final themeManager = context.watch<ThemeManager>();

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: themeManager.getSummaryCardTextColor().withValues(
                  alpha: (0.7 * 255).toInt().toDouble(),
                ),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(BuildContext context, double percentage) {
    final theme = Theme.of(context);

    if (percentage <= 80) {
      return theme.colorScheme.primary;
    } else if (percentage <= 90) {
      return theme.colorScheme.secondary;
    } else {
      return theme.colorScheme.error;
    }
  }
}
