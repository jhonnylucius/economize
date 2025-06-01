import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/interactive_animations.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
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

class _GoalFormState extends State<GoalForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _monthlyValueController = TextEditingController();
  final _monthsController = TextEditingController();
  final _discountController = TextEditingController();

  // Cores fixas em roxo independente do tema
  final Color _primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color.fromARGB(255, 252, 252, 252);
  final Color _errorColor = Colors.red.shade700;
  final Color _textColor = Colors.black87; // Texto sempre em preto

  CalculationType _calculationType = CalculationType.byMonthlyValue;
  late AnimationController _animationController;
  late Animation<double> _calculateButtonAnimation;
  bool _formComplete = false;

  @override
  void initState() {
    super.initState();

    // Configura o controlador de animação para o botão de calcular
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _calculateButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Adiciona listeners para atualizar o estado do botão de calcular
    _titleController.addListener(_checkFormCompletion);
    _targetValueController.addListener(_checkFormCompletion);
    _monthlyValueController.addListener(_checkFormCompletion);
    _monthsController.addListener(_checkFormCompletion);
  }

  void _checkFormCompletion() {
    bool isComplete = _titleController.text.isNotEmpty &&
        _targetValueController.text.isNotEmpty &&
        (_calculationType == CalculationType.byMonthlyValue
            ? _monthlyValueController.text.isNotEmpty
            : _monthsController.text.isNotEmpty);

    if (isComplete != _formComplete) {
      setState(() {
        _formComplete = isComplete;
      });

      if (isComplete) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    _monthlyValueController.dispose();
    _monthsController.dispose();
    _discountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ignoramos o tema e usamos cores fixas
    // final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de Objetivo
          SlideAnimation.fromLeft(
            delay: const Duration(milliseconds: 100),
            child: _buildFormField(
              controller: _titleController,
              label: 'Objetivo',
              hint: 'Ex: Geladeira Nova',
              icon: Icons.bookmark_outline,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Digite o objetivo';
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Campo de Valor Total
          SlideAnimation.fromRight(
            delay: const Duration(milliseconds: 200),
            child: _buildFormField(
              controller: _targetValueController,
              label: 'Valor Total',
              hint: 'Ex: 2000',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o valor do objetivo';
                }
                final number = double.tryParse(value) ?? 0;
                if (number <= 0) return 'Valor deve ser maior que zero';
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Seletor de Tipo de Cálculo
          FadeAnimation(
            delay: const Duration(milliseconds: 300),
            child: _buildCalculationTypeSelector(),
          ),

          const SizedBox(height: 16),

          // Campo baseado no tipo de cálculo
          ScaleAnimation(
            fromScale: 0.95,
            delay: const Duration(milliseconds: 400),
            child: _calculationType == CalculationType.byMonthlyValue
                ? _buildMonthlyValueInput()
                : _buildMonthsInput(),
          ),

          const SizedBox(height: 16),

          // Campo de Desconto
          SlideAnimation.fromLeft(
            delay: const Duration(milliseconds: 500),
            child: _buildFormField(
              controller: _discountController,
              label: 'Desconto à Vista (%)',
              hint: 'Ex: 10',
              icon: Icons.discount_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              isOptional: true,
            ),
          ),

          const SizedBox(height: 24),

          // Botão de Calcular com animação
          Center(
            child: AnimatedBuilder(
              animation: _calculateButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_calculateButtonAnimation.value * 0.2),
                  child: PressableCard(
                    pressedScale: 0.9,
                    onPress: _formComplete ? _submitForm : null,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _formComplete
                          ? _primaryPurple
                          : _primaryPurple.withAlpha((0.3 * 255).toInt()),
                      boxShadow: _formComplete
                          ? [
                              BoxShadow(
                                color: _primaryPurple
                                    .withAlpha((0.3 * 255).toInt()),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _formComplete ? _submitForm : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor:
                              Colors.white, // Texto branco no botão
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              color: Colors.white, // Ícone branco
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Calcular',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Texto branco
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return GlassContainer(
      blur: 3,
      opacity: 0.05,
      borderRadius: 12,
      borderColor: _primaryPurple.withAlpha((0.2 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: TextFormField(
          controller: controller,
          style: TextStyle(color: _textColor), // Texto sempre preto
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label + (isOptional ? ' (opcional)' : ''),
            hintText: hint,
            prefixIcon: Icon(icon, color: _primaryPurple), // Ícone roxo
            floatingLabelStyle:
                TextStyle(color: _primaryPurple), // Label roxo quando focado

            // Garante fundo e texto/label visíveis
            filled: true,
            fillColor: Colors.white, // Fundo sempre branco
            labelStyle: TextStyle(color: _textColor), // Label preto
            hintStyle: TextStyle(
              color: _textColor.withAlpha((0.6 * 255).toInt()), // Hint cinza
            ),

            // Define as bordas
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _textColor.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _textColor.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _primaryPurple, // Borda roxa quando focado
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _errorColor, // Erro em vermelho
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _errorColor, // Erro em vermelho quando focado
                width: 2.0,
              ),
            ),
          ),
          validator: isOptional
              ? null
              : (validator ??
                  ((value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo é obrigatório';
                    }
                    return null;
                  })),
        ),
      ),
    );
  }

  Widget _buildCalculationTypeSelector() {
    return GlassContainer(
      blur: 3,
      opacity: 0.05,
      borderRadius: 12,
      borderColor: _primaryPurple.withAlpha((0.2 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: _primaryPurple, // Ícone roxo
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Como deseja calcular?',
                  style: TextStyle(
                    color: _textColor, // Texto preto
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Opções de cálculo em formato de cards
            Row(
              children: [
                _buildCalculationTypeCard(
                  title: 'Por valor mensal',
                  subtitle: 'Quanto posso guardar por mês',
                  icon: Icons.savings_outlined,
                  isSelected:
                      _calculationType == CalculationType.byMonthlyValue,
                  onTap: () {
                    setState(() {
                      _calculationType = CalculationType.byMonthlyValue;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildCalculationTypeCard(
                  title: 'Por tempo',
                  subtitle: 'Em quantos meses desejo atingir',
                  icon: Icons.calendar_month_outlined,
                  isSelected: _calculationType == CalculationType.byDesiredTime,
                  onTap: () {
                    setState(() {
                      _calculationType = CalculationType.byDesiredTime;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableCard(
        onPress: onTap,
        pressedScale: 0.95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _primaryPurple // Borda roxa quando selecionado
                : _textColor.withAlpha((0.2 * 255).toInt()),
            width: isSelected ? 2.0 : 1.0,
          ),
          color: isSelected
              ? Colors.white // Fundo roxo claro quando selecionado
              : Colors.white, // Fundo branco quando não selecionado
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? _primaryPurple.withAlpha((0.2 * 255).toInt())
                    : _textColor.withAlpha((0.1 * 255).toInt()),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? _primaryPurple // Ícone roxo quando selecionado
                    : _textColor.withAlpha((0.7 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? _primaryPurple // Texto roxo quando selecionado
                    : _textColor, // Texto preto quando não selecionado
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: _textColor.withAlpha((0.7 * 255).toInt()), // Texto cinza
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyValueInput() {
    return _buildFormField(
      controller: _monthlyValueController,
      label: 'Valor Mensal',
      hint: 'Ex: 200',
      icon: Icons.savings_outlined,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Digite o valor mensal';
        final number = double.tryParse(value) ?? 0;
        if (number <= 0) return 'Valor deve ser maior que zero';
        return null;
      },
    );
  }

  Widget _buildMonthsInput() {
    return _buildFormField(
      controller: _monthsController,
      label: 'Quantidade de Meses',
      hint: 'Ex: 12',
      icon: Icons.calendar_today,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Digite o número de meses';
        final number = int.tryParse(value) ?? 0;
        if (number <= 0) return 'Meses deve ser maior que zero';
        return null;
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Cria um efeito de pressionamento no botão
      ScaffoldMessenger.of(context).clearSnackBars();

      final goal = SavingsGoal(
        title: _titleController.text,
        targetValue: double.parse(_targetValueController.text),
        type: _calculationType,
        monthlyValue: _calculationType == CalculationType.byMonthlyValue
            ? double.parse(_monthlyValueController.text)
            : null,
        targetMonths: _calculationType == CalculationType.byDesiredTime
            ? int.parse(_monthsController.text)
            : null,
        cashDiscount: _discountController.text.isNotEmpty
            ? double.parse(_discountController.text)
            : null,
      );

      widget.onSave(goal);
    }
  }
}
