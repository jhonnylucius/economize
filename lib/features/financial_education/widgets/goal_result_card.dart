import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/utils/goal_calculator.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class GoalResultCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onRecalculate;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  GoalResultCard({super.key, required this.goal, required this.onRecalculate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const Divider(height: 32),
            _buildMainInfo(theme),
            const SizedBox(height: 24),
            _buildSavingsInfo(theme),
            const SizedBox(height: 24),
            _buildRecommendation(theme),
            const SizedBox(height: 24),
            _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Meta: ${_currencyFormat.format(goal.targetValue)}',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(ThemeData theme) {
    if (goal.type == CalculationType.byMonthlyValue) {
      final months = goal.calculateTimeNeeded();
      return _buildInfoRow(
        theme,
        'Tempo p/ alcançar:',
        GoalCalculator.formatTimeToReach(months),
        icon: Icons.timelapse,
      );
    } else {
      final monthlyValue = goal.calculateMonthlyNeeded();
      return _buildInfoRow(
        theme,
        'Valor mensal necessário:',
        _currencyFormat.format(monthlyValue),
        icon: Icons.savings,
      );
    }
  }

  Widget _buildSavingsInfo(ThemeData theme) {
    if (goal.cashDiscount == null) return const SizedBox.shrink();

    final savings = goal.calculateTotalSavings();
    final finalValue = goal.calculateFinalValue();

    return Column(
      children: [
        _buildInfoRow(
          theme,
          'Economia à vista:',
          _currencyFormat.format(savings),
          icon: Icons.discount,
          valueColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          theme,
          'Valor final:',
          _currencyFormat.format(finalValue),
          icon: Icons.attach_money,
          valueColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildRecommendation(ThemeData theme) {
    if (goal.type != CalculationType.byMonthlyValue) {
      return const SizedBox.shrink();
    }

    final isReasonable = goal.isReasonableGoal();
    final suggestedValue = goal.getSuggestedMonthlyValue();

    if (isReasonable) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sugestão de Ajuste',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Para alcançar sua meta em até 2 anos, considere economizar ${_currencyFormat.format(suggestedValue)} por mês.',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onRecalculate,
        icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
        label: Text(
          'Recalcular',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
