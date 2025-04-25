import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/widgets/goal_form.dart';
import 'package:economize/features/financial_education/widgets/goal_result_card.dart';
import 'package:flutter/material.dart';

class GoalCalculatorScreen extends StatefulWidget {
  const GoalCalculatorScreen({super.key});

  @override
  State<GoalCalculatorScreen> createState() => _GoalCalculatorScreenState();
}

class _GoalCalculatorScreenState extends State<GoalCalculatorScreen> {
  SavingsGoal? _currentGoal;
  bool _showResult = false;

  void _handleGoalSubmit(SavingsGoal goal) {
    setState(() {
      _currentGoal = goal;
      _showResult = true;
    });
  }

  void _handleRecalculate() {
    setState(() {
      _showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Metas'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_showResult) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Defina sua Meta',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preencha os dados para calcular o tempo necessário ou o valor mensal para atingir seu objetivo.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GoalForm(onSave: _handleGoalSubmit),
                        ],
                      ),
                    ),
                  ),
                ] else if (_currentGoal != null) ...[
                  GoalResultCard(
                    goal: _currentGoal!,
                    onRecalculate: _handleRecalculate,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
