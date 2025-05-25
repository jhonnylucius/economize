import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _isLoading = true;
  double _totalRevenues = 0.0;
  double _totalCosts = 0.0;
  double _balance = 0.0;
  double _expensePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentMonthData();
  }

  Future<void> _loadCurrentMonthData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final List<Costs> costs = await _costsService.getAllCosts();
      final List<Revenues> revenues = await _revenuesService.getAllRevenues();

      final currentMonthCosts = costs.where((cost) {
        return cost.data.isAfter(firstDayOfMonth) &&
            cost.data.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      }).toList();

      final currentMonthRevenues = revenues.where((revenue) {
        return revenue.data.isAfter(firstDayOfMonth) &&
            revenue.data.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      }).toList();

      final totalCosts =
          currentMonthCosts.fold<double>(0, (sum, cost) => sum + cost.preco);
      final totalRevenues = currentMonthRevenues.fold<double>(
          0, (sum, revenue) => sum + revenue.preco);

      final balance = totalRevenues - totalCosts;
      final expensePercentage = totalRevenues > 0
          ? (totalCosts / totalRevenues).clamp(0.0, 1.0)
          : 0.0;

      if (mounted) {
        setState(() {
          _totalCosts = totalCosts;
          _totalRevenues = totalRevenues;
          _balance = balance;
          _expensePercentage = expensePercentage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMonth =
        DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldo Mensal'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mês atual logo abaixo do AppBar
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Center(
                      child: Text(
                        "Mês atual - ${currentMonth.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onInverseSurface,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Círculo de saldo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 14.0,
                        percent: 1.0,
                        backgroundColor: Colors.transparent,
                        progressColor: const Color.fromARGB(255, 60, 184, 78),
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 1000,
                      ),
                      CircularPercentIndicator(
                        radius: 120.0,
                        lineWidth: 14.0,
                        animation: true,
                        animationDuration: 1500,
                        percent: _expensePercentage,
                        backgroundColor: Colors.transparent,
                        progressColor: const Color.fromARGB(255, 207, 62, 42),
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Text(
                          _currencyFormat.format(_balance),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Receitas',
                            _totalRevenues,
                            Colors.green[700]!,
                            theme.colorScheme.inverseSurface,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Despesas',
                            _totalCosts,
                            Colors.red[700]!,
                            theme.colorScheme.inverseSurface,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Saldo',
                            _balance,
                            _balance >= 0
                                ? Colors.green[700]!
                                : Colors.red[700]!,
                            theme.colorScheme.inverseSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _balance >= 0
                        ? 'Suas finanças estão saudáveis!'
                        : 'Atenção! Suas despesas estão maiores que suas receitas.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          _balance >= 0 ? Colors.green[500] : Colors.red[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
      String label, double value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
