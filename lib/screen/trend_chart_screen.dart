import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TrendChartScreen extends StatefulWidget {
  const TrendChartScreen({super.key});

  @override
  State<TrendChartScreen> createState() => _TrendChartScreenState();
}

class _TrendChartScreenState extends State<TrendChartScreen> {
  final CostsService _costsService = CostsService();
  final RevenuesService _revenuesService = RevenuesService(); // Adicionar
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _isLoading = true;
  List<FlSpot> _costSpots = []; // Renomear para _costSpots
  List<FlSpot> _revenueSpots = []; // Adicionar para receitas
  double _maxY = 0;
  double _minY = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Método _loadData **original** (sem alterações do anexo)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final costs = await _costsService.getAllCosts();
      final revenues = await _revenuesService.getAllRevenues();
      _processData(costs, revenues);
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Método _processData **original** (sem alterações do anexo)
  void _processData(List<Costs> costs, List<Revenues> revenues) {
    // Agrupa despesas por mês
    final monthlyTotalsCosts = <int, double>{};
    final monthlyTotalsRevenues = <int, double>{};

    for (var cost in costs) {
      final month = cost.data.month;
      monthlyTotalsCosts[month] = (monthlyTotalsCosts[month] ?? 0) + cost.preco;
    }

    for (var revenue in revenues) {
      final month = revenue.data.month;
      monthlyTotalsRevenues[month] =
          (monthlyTotalsRevenues[month] ?? 0) + revenue.preco;
    }

    // Cria spots para o gráfico
    _costSpots = monthlyTotalsCosts.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    _revenueSpots = monthlyTotalsRevenues.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // Calcula valores máximo e mínimo considerando ambas as linhas
    if (_costSpots.isNotEmpty || _revenueSpots.isNotEmpty) {
      final allSpots = [..._costSpots, ..._revenueSpots];
      _maxY = allSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      _minY = allSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      if (_maxY <= 0) _maxY = 1;
    } else {
      _maxY = 1;
      _minY = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      appBar: AppBar(
        title: const Text('Tendênciadas suas finanças'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.onPrimary,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      resizeToAvoidBottomInset: true,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _costSpots.isEmpty && _revenueSpots.isEmpty // Alterado aqui
              ? Center(
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: _buildChart(theme),
                  ),
                ),
    );
  }

  // Método _buildChart **original** (sem alterações do anexo)
  Widget _buildChart(ThemeData theme) {
    final themeManager = context.watch<ThemeManager>();

    // Usa os cálculos de intervalo originais (com a proteção contra divisão por zero)
    final horizontalInterval = (_maxY > 0) ? _maxY / 5 : 1.0;
    final verticalInterval = 1.0;

    // Usa os cálculos de min/max Y considerando ambas as listas
    final hasData = _costSpots.isNotEmpty || _revenueSpots.isNotEmpty;
    final minYAdjusted = hasData ? _minY * 0.8 : 0.0;
    final maxYAdjusted = hasData ? _maxY * 1.2 : 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval, // Usa intervalo calculado
          verticalInterval: verticalInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: themeManager.getTipCardTextColor(),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: themeManager.getTipCardTextColor(),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = [
                  'Jan',
                  'Fev',
                  'Mar',
                  'Abr',
                  'Mai',
                  'Jun',
                  'Jul',
                  'Ago',
                  'Set',
                  'Out',
                  'Nov',
                  'Dez',
                ];
                final index = value.toInt() - 1;
                if (index >= 0 && index < months.length) {
                  // **Remove a rotação que não estava no último anexo original**
                  return Text(
                    months[index],
                    style: TextStyle(
                      color: themeManager.getTipCardTextColor(),
                      fontSize: 12, // Mantém tamanho original
                    ),
                  );
                }
                return const Text('');
              },
              // **Remove reservedSize se não estava no último anexo original**
              // reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: horizontalInterval, // Usa intervalo calculado
              reservedSize: 60, // Mantém tamanho original
              getTitlesWidget: (value, meta) {
                // **Usa currencyFormat como no último anexo original**
                return Text(
                  currencyFormat.format(value),
                  style: TextStyle(
                    color: themeManager.getTipCardTextColor(),
                    fontSize: 12, // Mantém tamanho original
                  ),
                  // **Remove textAlign se não estava no último anexo original**
                  // textAlign: TextAlign.right,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: themeManager.getTipCardTextColor(),
          ), // Cor original
        ),
        minX: 1, // Mantém minX original
        maxX: 12, // Mantém maxX original
        minY: minYAdjusted, // Usa minY ajustado original
        maxY: maxYAdjusted, // Usa maxY ajustado original
        lineBarsData: [
          // Linha de Despesas
          LineChartBarData(
            spots: _costSpots,
            isCurved: true,
            color: Colors.red, // Cor para despesas
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: themeManager.getChartBackgroundColor(),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withAlpha((0.2 * 255).toInt()),
            ),
          ),
          // Linha de Receitas
          LineChartBarData(
            spots: _revenueSpots,
            isCurved: true,
            color: Colors.green, // Cor para receitas
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green,
                  strokeWidth: 2,
                  strokeColor: themeManager.getChartBackgroundColor(),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withAlpha((0.2 * 255).toInt()),
            ),
          ),
        ],
        // **Mantém o lineTouchData EXATAMENTE como no último anexo original**
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // **NÃO TEM tooltipBgColor no original**
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                // **NÃO TEM lista de meses completa no original**
                return LineTooltipItem(
                  '${currencyFormat.format(spot.y)}\n', // Valor formatado
                  TextStyle(
                    color: themeManager.getChartTextColor(), // Cor original
                    fontWeight: FontWeight.bold,
                    // **NÃO TEM fontSize: 12 no original**
                  ),
                  children: [
                    TextSpan(
                      text: 'Mês ${spot.x.toInt()}', // Texto original
                      style: TextStyle(
                        color: themeManager.getChartTextColor(), // Cor original
                        fontWeight: FontWeight.normal,
                        // **NÃO TEM fontSize: 10 no original**
                      ),
                    ),
                  ],
                  // **NÃO TEM textAlign no original**
                );
              }).toList();
            },
          ),
          // **NÃO TEM enabled: true no original**
        ),
      ),
    );
  }
}
