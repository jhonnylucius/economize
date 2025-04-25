import 'package:economize/features/financial_education/models/savings_goal.dart';
import 'package:economize/features/financial_education/utils/goal_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoalForm extends StatefulWidget {
  final Function(SavingsGoal) onSave;

  const GoalForm({super.key, required this.onSave});

  @override
  State<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _monthlyValueController = TextEditingController();
  final _monthsController = TextEditingController();
  final _discountController = TextEditingController();

  CalculationType _calculationType = CalculationType.byMonthlyValue;

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    _monthlyValueController.dispose();
    _monthsController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TextFormField Objetivo ---
          TextFormField(
            controller: _titleController,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ), // Texto visível
            decoration: InputDecoration(
              labelText: 'Objetivo',
              hintText: 'Ex: Geladeira Nova',
              prefixIcon: Icon(
                Icons.bookmark_outline,
                color: theme.colorScheme.primary,
              ),
              // Garante fundo branco e texto/label visíveis
              filled: true,
              fillColor: theme.colorScheme.surface,
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
              // Define as bordas
              border: OutlineInputBorder(
                // Borda padrão (igual enabled)
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              enabledBorder: OutlineInputBorder(
                // Borda quando não focado
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              focusedBorder: OutlineInputBorder(
                // Borda quando focado
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ), // Cor primária
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _targetValueController,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ), // Texto visível
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Valor Total',
              hintText: 'Ex: 2000',
              prefixIcon: Icon(
                Icons.attach_money,
                color: theme.colorScheme.primary,
              ),
              // Garante fundo branco e texto/label visíveis
              filled: true,
              fillColor: theme.colorScheme.surface,
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
              // Define as bordas
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ), // Cor primária
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Digite o valor do objetivo';
              final number = double.tryParse(value!) ?? 0;
              if (number <= 0) return 'Valor deve ser maior que zero';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildCalculationTypeSelector(theme), // Sem alterações aqui
          const SizedBox(height: 16),
          if (_calculationType == CalculationType.byMonthlyValue)
            _buildMonthlyValueInput(theme) // Ajustes dentro deste método
          else
            _buildMonthsInput(theme), // Ajustes dentro deste método
          const SizedBox(height: 16),
          TextFormField(
            controller: _discountController,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ), // Texto visível
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Desconto à Vista (%)',
              hintText: 'Ex: 10',
              prefixIcon: Icon(
                Icons.discount_outlined,
                color: theme.colorScheme.primary,
              ),
              // Garante fundo branco e texto/label visíveis
              filled: true,
              fillColor: theme.colorScheme.surface,
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
              // Define as bordas
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ), // <<< Cor visível
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ), // Cor primária
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitForm,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Calcular',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como deseja calcular?',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<CalculationType>(
                title: Text(
                  'Por valor mensal',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: CalculationType.byMonthlyValue,
                groupValue: _calculationType,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _calculationType = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<CalculationType>(
                title: Text(
                  'Por tempo',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: CalculationType.byDesiredTime,
                groupValue: _calculationType,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _calculationType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyValueInput(ThemeData theme) {
    return TextFormField(
      controller: _monthlyValueController,
      style: TextStyle(color: theme.colorScheme.onSurface), // Texto visível
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Valor Mensal',
        hintText: 'Ex: 200',
        prefixIcon: Icon(
          Icons.savings_outlined,
          color: theme.colorScheme.primary,
        ),
        // Garante fundo branco e texto/label visíveis
        filled: true,
        fillColor: theme.colorScheme.surface,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
        ),
        // Define as bordas
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
          ), // <<< Cor visível
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
          ), // <<< Cor visível
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          ), // Cor primária
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Digite o valor mensal';
        final number = double.tryParse(value!) ?? 0;
        if (number <= 0) return 'Valor deve ser maior que zero';
        return null;
      },
    );
  }

  Widget _buildMonthsInput(ThemeData theme) {
    return TextFormField(
      controller: _monthsController,
      style: TextStyle(color: theme.colorScheme.onSurface), // Texto visível
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Quantidade de Meses',
        hintText: 'Ex: 12',
        prefixIcon: Icon(
          Icons.calendar_today,
          color: theme.colorScheme.primary,
        ),
        // Garante fundo branco e texto/label visíveis
        filled: true,
        fillColor: theme.colorScheme.surface,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface),
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
        ),
        // Define as bordas
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
          ), // <<< Cor visível
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
          ), // <<< Cor visível
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          ), // Cor primária
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Digite o número de meses';
        final number = int.tryParse(value!) ?? 0;
        if (number <= 0) return 'Meses deve ser maior que zero';
        return null;
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final goal = SavingsGoal(
        title: _titleController.text,
        targetValue: double.parse(_targetValueController.text),
        type: _calculationType,
        monthlyValue:
            _calculationType == CalculationType.byMonthlyValue
                ? double.parse(_monthlyValueController.text)
                : null,
        targetMonths:
            _calculationType == CalculationType.byDesiredTime
                ? int.parse(_monthsController.text)
                : null,
        cashDiscount:
            _discountController.text.isNotEmpty
                ? double.parse(_discountController.text)
                : null,
      );

      widget.onSave(goal);
    }
  }
}
