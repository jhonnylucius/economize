import 'package:economize/features/financial_education/utils/goal_calculator.dart';

enum CalculationMode { calculateTime, calculateMonthlyAmount }

class SavingsGoal {
  String title; // Nome do objetivo (ex: "Geladeira Nova")
  double targetValue; // Valor total do objetivo
  double? monthlyValue; // Valor mensal planejado
  int? targetMonths; // Meses planejados
  double? cashDiscount; // Desconto para pagamento à vista (%)
  CalculationType type; // Tipo de cálculo escolhido
  DateTime createdAt; // Data de criação
  DateTime? targetDate; // Data prevista para alcançar

  SavingsGoal({
    required this.title,
    required this.targetValue,
    this.monthlyValue,
    this.targetMonths,
    this.cashDiscount,
    required this.type,
    DateTime? createdAt,
    this.targetDate,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calcula o tempo necessário (em meses)
  int calculateTimeNeeded() {
    if (type != CalculationType.byMonthlyValue || monthlyValue == null) {
      return 0;
    }

    return GoalCalculator.calculateMonthsNeeded(
      targetValue: targetValue,
      monthlyValue: monthlyValue!,
      cashDiscount: cashDiscount,
    );
  }

  // Calcula o valor mensal necessário
  double calculateMonthlyNeeded() {
    if (type != CalculationType.byDesiredTime || targetMonths == null) {
      return 0;
    }

    return GoalCalculator.calculateMonthlyValueNeeded(
      targetValue: targetValue,
      months: targetMonths!,
      cashDiscount: cashDiscount,
    );
  }

  // Calcula economia total com desconto à vista
  double calculateTotalSavings() {
    if (cashDiscount == null) return 0;

    return GoalCalculator.calculateTotalSavings(
      targetValue: targetValue,
      cashDiscount: cashDiscount!,
    );
  }

  // Calcula valor final com desconto
  double calculateFinalValue() {
    if (cashDiscount == null) return targetValue;

    return targetValue - calculateTotalSavings();
  }

  // Verifica se a meta é alcançável
  bool isReasonableGoal() {
    if (type != CalculationType.byMonthlyValue || monthlyValue == null) {
      return false;
    }

    return GoalCalculator.isReasonableGoal(
      targetValue: targetValue,
      monthlyValue: monthlyValue!,
    );
  }

  // Retorna sugestão de valor mensal
  double getSuggestedMonthlyValue() {
    return GoalCalculator.suggestMonthlyValue(targetValue: targetValue);
  }

  // Converte para Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetValue': targetValue,
      'monthlyValue': monthlyValue,
      'targetMonths': targetMonths,
      'cashDiscount': cashDiscount,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
    };
  }

  // Cria objeto a partir de um Map
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      title: map['title'],
      targetValue: map['targetValue'],
      monthlyValue: map['monthlyValue'],
      targetMonths: map['targetMonths'],
      cashDiscount: map['cashDiscount'],
      type: CalculationType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      createdAt: DateTime.parse(map['createdAt']),
      targetDate:
          map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
    );
  }
}
