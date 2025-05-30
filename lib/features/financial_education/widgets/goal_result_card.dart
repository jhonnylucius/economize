import 'package:economize/data/goal_dao.dart';
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
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    theme,
                    'Recalcular',
                    Icons.refresh,
                    onRecalculate,
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    theme,
                    'Salvar Meta',
                    Icons.save,
                    () => _saveGoal(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para salvar a meta
  void _saveGoal(BuildContext context) async {
    final goalsDAO = GoalsDAO();
    final messenger = ScaffoldMessenger.of(context);

    // Converter SavingsGoal para Goal
    final goalToSave = Goal(
      name: goal.title,
      targetValue: goal.targetValue,
      currentValue: 0.0, // Começa em zero
      createdAt: DateTime.now(), // Data atual como criação
    );

    try {
      await goalsDAO.save(goalToSave);

      // Mostrar feedback positivo
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Meta salva com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Navegar após mostrar o SnackBar
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pushReplacementNamed(
            '/goals'); // Ajuste o nome da rota conforme necessário
      });
    } catch (e) {
      // Mostrar feedback de erro
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar meta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    if (outlined) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: theme.colorScheme.primary),
        label: Text(
          label,
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
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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
            color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
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
        color: theme.colorScheme.errorContainer.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error..withAlpha((0.3 * 255).toInt()),
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
}
