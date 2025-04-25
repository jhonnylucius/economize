import 'package:economize/model/budget/price_history.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceHistoryChart extends StatefulWidget {
  final List<PriceHistory> history;
  final String itemName;
  final String locationName;

  const PriceHistoryChart({
    super.key,
    required this.history,
    required this.itemName,
    required this.locationName,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  // Cores fixas para melhor visualização
  static const _primaryBlue = Color(0xFF1E88E5);
  static const _textColor = Color(0xFF424242);
  static const _negativeRed = Color(0xFFE53935);
  static const _positiveGreen = Color(0xFF43A047);
  static const _backgroundColor = Colors.white;
  static const _gridColor = Color(0xFFEEEEEE);

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 48,
              color: _textColor.withAlpha((0.5 * 255).toInt()),
            ),
            const SizedBox(height: 16),
            Text(
              'Sem histórico de preços',
              style: TextStyle(
                color: _textColor.withAlpha((0.5 * 255).toInt()),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final minPrice = widget.history
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = widget.history
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      color: _backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildStatistics(minPrice, maxPrice),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                _createChartData(minPrice, maxPrice),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'Histórico de Preços - ${widget.itemName}',
          style: const TextStyle(
            color: _textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          widget.locationName,
          style: TextStyle(
            color: _textColor.withAlpha((0.6 * 255).toInt()),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(double minPrice, double maxPrice) {
    final variation = ((maxPrice - minPrice) / minPrice) * 100;
    final isPositive = variation > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          'Menor Preço',
          currencyFormat.format(minPrice),
          _positiveGreen,
        ),
        _buildStatItem(
          'Maior Preço',
          currencyFormat.format(maxPrice),
          _negativeRed,
        ),
        _buildStatItem(
          'Variação',
          '${variation.abs().toStringAsFixed(1)}%',
          isPositive ? _negativeRed : _positiveGreen,
          prefix: isPositive ? '↑' : '↓',
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color, {
    String? prefix,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _textColor.withAlpha((0.7 * 255).toInt()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          prefix != null ? '$prefix $value' : value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  LineChartData _createChartData(double minPrice, double maxPrice) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: _gridColor, strokeWidth: 1);
        },
      ),
      titlesData: _createTitlesData(),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: _gridColor),
      ),
      minX: 0,
      maxX: widget.history.length.toDouble() - 1,
      minY: minPrice * 0.9,
      maxY: maxPrice * 1.1,
      lineBarsData: [
        LineChartBarData(
          spots:
              widget.history
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.price))
                  .toList(),
          isCurved: true,
          color: _primaryBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: _backgroundColor,
                strokeWidth: 2,
                strokeColor: _primaryBlue,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: _primaryBlue.withAlpha((0.1 * 255).toInt()),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipMargin: 8,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipHorizontalOffset: 0,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final date = widget.history[barSpot.x.toInt()].date;
              return LineTooltipItem(
                '${DateFormat('dd/MM').format(date)}\n${currencyFormat.format(barSpot.y)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (event is FlTapUpEvent) {
              selectedIndex =
                  touchResponse?.lineBarSpots?.first.x.toInt() ?? -1;
            }
          });
        },
      ),
    );
  }

  FlTitlesData _createTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= 0 && value.toInt() < widget.history.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat(
                    'dd/MM',
                  ).format(widget.history[value.toInt()].date),
                  style: TextStyle(
                    color: _textColor.withAlpha((0.6 * 255).toInt()),
                    fontSize: 10,
                  ),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: null,
          getTitlesWidget: (value, meta) {
            return Text(
              currencyFormat.format(value),
              style: TextStyle(
                color: _textColor.withAlpha((0.6 * 255).toInt()),
                fontSize: 10,
              ),
            );
          },
          reservedSize: 56,
        ),
      ),
    );
  }
}
