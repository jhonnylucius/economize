enum CalculationType {
  byMonthlyValue, // Calcula tempo baseado no valor mensal
  byDesiredTime, // Calcula valor mensal baseado no tempo desejado
}

class GoalCalculator {
  // Calcula meses necessários dado um valor mensal
  static int calculateMonthsNeeded({
    required double targetValue,
    required double monthlyValue,
    double? cashDiscount,
  }) {
    if (monthlyValue <= 0) return 0;

    final valueWithDiscount =
        cashDiscount != null
            ? targetValue * (1 - (cashDiscount / 100))
            : targetValue;

    return (valueWithDiscount / monthlyValue).ceil();
  }

  // Calcula valor mensal necessário dado um número de meses
  static double calculateMonthlyValueNeeded({
    required double targetValue,
    required int months,
    double? cashDiscount,
  }) {
    if (months <= 0) return 0;

    final valueWithDiscount =
        cashDiscount != null
            ? targetValue * (1 - (cashDiscount / 100))
            : targetValue;

    return valueWithDiscount / months;
  }

  // Calcula economia total com desconto à vista
  static double calculateTotalSavings({
    required double targetValue,
    required double cashDiscount,
  }) {
    return targetValue * (cashDiscount / 100);
  }

  // Formata o número de meses em texto amigável
  static String formatTimeToReach(int months) {
    if (months <= 0) return 'Tempo inválido';

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years > 0 && remainingMonths > 0) {
      return '$years ano${years > 1 ? 's' : ''} e $remainingMonths mês${remainingMonths > 1 ? 'es' : ''}';
    } else if (years > 0) {
      return '$years ano${years > 1 ? 's' : ''}';
    } else {
      return '$months mês${months > 1 ? 'es' : ''}';
    }
  }

  // Verifica se o objetivo é alcançável em um tempo razoável
  static bool isReasonableGoal({
    required double targetValue,
    required double monthlyValue,
    int maxYears = 5, // Padrão de 5 anos como tempo máximo razoável
  }) {
    final months = calculateMonthsNeeded(
      targetValue: targetValue,
      monthlyValue: monthlyValue,
    );

    return months <= (maxYears * 12);
  }

  // Sugere valor mensal para alcançar meta em tempo razoável
  static double suggestMonthlyValue({
    required double targetValue,
    int targetMonths = 24, // Padrão de 2 anos como sugestão inicial
  }) {
    return calculateMonthlyValueNeeded(
      targetValue: targetValue,
      months: targetMonths,
    );
  }
}
