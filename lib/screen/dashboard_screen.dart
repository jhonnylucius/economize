import 'package:economize/model/costs.dart';
import 'package:economize/model/revenues.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/costs_service.dart';
import 'package:economize/service/revenues_service.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key}); // Removido user

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  List<Costs> listCosts = [];
  List<Revenues> listRevenues = [];
  double totalCosts = 0.0;
  double totalRevenues = 0.0;
  double averageCosts = 0.0;
  double averageRevenues = 0.0;
  double saldo = 0.0;
  int selectedMonth = DateTime.now().month; // Mês atual como padrão
  List<String> monthList = [
    'Todas',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final costsService = CostsService();
      final revenuesService = RevenuesService();

      final costs = await costsService.getAllCosts();
      final revenues = await revenuesService.getAllRevenues();

      setState(() {
        listCosts = costs;
        listRevenues = revenues;

        totalCosts = listCosts.fold(0.0, (sum, item) => sum + item.preco);
        totalRevenues = listRevenues.fold(0.0, (sum, item) => sum + item.preco);

        averageCosts =
            listCosts.isNotEmpty ? totalCosts / listCosts.length : 0.0;
        averageRevenues =
            listRevenues.isNotEmpty ? totalRevenues / listRevenues.length : 0.0;

        saldo = totalRevenues - totalCosts;
      });
    } catch (e) {
      Logger().e('Erro ao carregar dados: $e');
    }
  }

  // Função para filtrar receitas por mês
  List<Revenues> filterRevenuesByMonth(int month) {
    return listRevenues.where((revenues) {
      // A data já é DateTime, não precisa fazer parse
      return revenues.data.month == month;
    }).toList();
  }

  // Função para filtrar despesas por mês
  List<Costs> _filterCostsByMonth(int month) {
    return listCosts.where((cost) {
      // Agora cost.data já é DateTime, não precisa fazer parse
      return cost.data.month == month;
    }).toList();
  }

  // Modifique o método _filterAllCosts
  List<Costs> _filterAllCosts(int month) {
    if (month == 1) {
      // 1 representa a opção "Todas"
      return listCosts; // Retorna todas as despesas
    } else {
      return _filterCostsByMonth(month); // Usa o filtro por mês existente
    }
  }

  // Função para calcular o total de receitas por tipo
  Map<String, double> _calculateRevenuesByType(List<Revenues> revenues) {
    Map<String, double> revenuesByType = {};
    for (var revenues in revenues) {
      revenuesByType[revenues.tipoReceita] =
          (revenuesByType[revenues.tipoReceita] ?? 0) + revenues.preco;
    }
    return revenuesByType;
  }

  // Função para calcular o total de despesas por tipo
  Map<String, double> _calculateCostsByType(List<Costs> costs) {
    Map<String, double> costsByType = {};
    for (var cost in costs) {
      costsByType[cost.tipoDespesa] =
          (costsByType[cost.tipoDespesa] ?? 0) + cost.preco;
    }
    return costsByType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = context.watch<ThemeManager>();

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      appBar: AppBar(
        // Mantém a AppBar original
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: themeManager.getDashboardHeaderTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeManager.getDashboardHeaderBackgroundColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Ir para Home',
            color: themeManager.getDashboardHeaderIconColor(),
          ),
        ],
      ),
      // Passa a cor de fundo original para o ResponsiveScreen
      backgroundColor: theme.scaffoldBackgroundColor,
      // Adiciona parâmetros obrigatórios/padrão do ResponsiveScreen
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Padrão
      resizeToAvoidBottomInset: true, // Padrão do Scaffold
      // O body original agora é o child do ResponsiveScreen, **colocado por último**
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildInfoCard(theme),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Receitas por tipo x Ano',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPieChart(listRevenues, 'Receitas Anuais'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tipo despesa x Mês',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<int>(
                        value: selectedMonth,
                        underline: Container(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                        dropdownColor: theme.colorScheme.surface,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        items: monthList.asMap().entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key + 1,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedMonth = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildPieChart(
                _filterAllCosts(selectedMonth),
                selectedMonth == 1 ? 'Todas as Despesas' : 'Despesas Mensais',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método _buildInfoCard original (sem alterações)
  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(14),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de Despesas: \$${totalCosts.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Total de Receitas: \$${totalRevenues.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Média de Despesas: \$${averageCosts.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Média de Receitas: \$${averageRevenues.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Saldo: \$${saldo.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método _buildPieChart original (sem alterações)
  Widget _buildPieChart(List<dynamic> items, String title) {
    final theme = Theme.of(context);
    Map<String, double> dataByType;
    if (title.contains('Receitas')) {
      dataByType = _calculateRevenuesByType(items.cast<Revenues>());
    } else {
      dataByType = _calculateCostsByType(items.cast<Costs>());
    }

    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.lime,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
      Colors.brown,
      Colors.grey,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
    ];
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  children: [
                    AppBar(
                      title: Text(title),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildChartContentPie(dataByType, colors),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.all(14),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              SizedBox(
                height: 200,
                child: _buildChartContentPie(dataByType, colors),
              ),
              Text(
                'Clique aqui e segure para visualizar maior',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Função _buildChartContentPie original (sem alterações)
Widget _buildChartContentPie(
  Map<String, double> dataByType,
  List<Color> colors,
) {
  List<PieChartSectionData> pieChartSections = [];
  int colorIndex = 0;
  double totalValue = dataByType.values.fold(0, (sum, value) => sum + value);

  dataByType.forEach((type, value) {
    double percentage = (value / totalValue) * 100;
    pieChartSections.add(
      PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    colorIndex++;
  });

  return Row(
    children: [
      Expanded(
        child: PieChart(
          PieChartData(
            sections: pieChartSections,
            centerSpaceRadius: 30,
            borderData: FlBorderData(show: false),
            sectionsSpace: 0,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                //Implementar a lógica de toque aqui, caso seja necessário
              },
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: dataByType.length,
          itemBuilder: (context, index) {
            final type = dataByType.keys.toList()[index];
            final value = dataByType.values.toList()[index];
            return ListTile(
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[index % colors.length],
                ),
              ),
              title: Text(
                '$type : ${value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
            );
          },
        ),
      ),
    ],
  );
}
