import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_location.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/utils/budget_utils.dart';
import 'package:economize/widgets/budget/budget_summary_card.dart';
import 'package:economize/widgets/budget/price_comparison_table.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BudgetCompareScreen extends StatelessWidget {
  final Budget budget;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  BudgetCompareScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    // Obtém o tema atual para usar as cores do esquema
    Theme.of(context);

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      appBar: AppBar(
        // Mantém a AppBar original
        title: Text(
          'Comparação - ${budget.title}',
          style: TextStyle(
            // Usa a cor definida no ThemeManager para o header
            color: themeManager.getCompareHeaderTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeManager.getCompareHeaderColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            color: themeManager.getCompareHeaderTextColor(),
          ),
        ],
      ),
      // Passa a cor de fundo original para o ResponsiveScreen
      backgroundColor: themeManager.getCompareCardBackgroundColor(),
      // Adiciona parâmetros obrigatórios/padrão do ResponsiveScreen
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Padrão
      resizeToAvoidBottomInset: true, // Padrão do Scaffold
      // O body original agora é o child do ResponsiveScreen, **colocado por último**
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BudgetSummaryCard(summary: budget.summary),
              const SizedBox(height: 16),
              _buildSavingsAnalysis(context),
              const SizedBox(height: 16),
              _buildBestPricesComparison(context),
              const SizedBox(height: 16),
              _buildLocationComparison(context),
              const SizedBox(height: 16),
              PriceComparisonTable(budget: budget),
            ],
          ),
        ),
      ),
    );
  }

  // Método _buildSavingsAnalysis original (sem alterações)
  Widget _buildSavingsAnalysis(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final savings =
        budget.items.map((item) {
            final saving = item.calculateSavings();
            return MapEntry(item.name, saving);
          }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      color: themeManager.getCompareCardBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise de Economia',
              style: TextStyle(
                color: themeManager.getCompareCardTitleColor(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSavingsChart(context, savings),
            const SizedBox(height: 8),
            _buildSavingsDetails(context, savings), // Chama o método corrigido
          ],
        ),
      ),
    );
  }

  // Método _buildSavingsChart original (sem alterações)
  Widget _buildSavingsChart(
    BuildContext context,
    List<MapEntry<String, double>> savings,
  ) {
    final themeManager = context.watch<ThemeManager>();

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            savings.map((entry) {
              // Calcula a altura da barra de forma segura
              double barHeight = entry.value > 0 ? entry.value / 2 : 0;
              // Limita a altura máxima se necessário para evitar barras gigantes
              barHeight = barHeight.clamp(0.0, 80.0); // Ex: Limita a 80 pixels

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Alinha barra na base
                  children: [
                    Container(
                      width: 50,
                      height: barHeight, // Usa altura calculada e limitada
                      color: themeManager.getCompareChartBarColor(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      // Limita a largura do texto para evitar overflow
                      width: 50,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: themeManager.getCompareCardTitleColor(),
                          fontSize: 12, // Reduzido para caber melhor
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Evita quebra de texto
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  // Método _buildSavingsDetails com cores do tema atual
  Widget _buildSavingsDetails(
    BuildContext context,
    List<MapEntry<String, double>> savings,
  ) {
    final themeManager = context.watch<ThemeManager>();
    // Obtém o esquema de cores do tema atual
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children:
          savings.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return ListTile(
              leading: CircleAvatar(
                // *** CORREÇÃO: Usa a cor primária do tema para o fundo do círculo ***
                backgroundColor: colorScheme.primary,
                radius: 12,
                child: Text(
                  '$index',
                  style: TextStyle(
                    // *** CORREÇÃO: Usa a cor 'onPrimary' do tema para o texto ***
                    color: colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                item.key,
                style: TextStyle(color: themeManager.getCompareCardTextColor()),
              ),
              subtitle: Text(
                'Economia: ${currencyFormat.format(item.value)}',
                style: TextStyle(
                  color: themeManager.getCompareSavingsTextColor(),
                ),
              ),
            );
          }).toList(),
    );
  }

  // Método _buildBestPricesComparison com cores do tema atual
  Widget _buildBestPricesComparison(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    // Obtém o esquema de cores do tema atual
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: themeManager.getCompareCardBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Melhores Preços por Item',
              style: TextStyle(
                color: themeManager.getCompareCardTitleColor(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...budget.items.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;
              final location = budget.locations.firstWhere(
                (loc) => loc.id == item.bestPriceLocation,
                orElse:
                    () => BudgetLocation(
                      id: '',
                      budgetId: budget.id,
                      name: 'Desconhecido',
                      address: '',
                      priceDate: DateTime.now(),
                    ),
              );

              return ListTile(
                leading: CircleAvatar(
                  // *** CORREÇÃO: Usa a cor primária do tema para o fundo do círculo ***
                  backgroundColor: colorScheme.primary,
                  radius: 12,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      // *** CORREÇÃO: Usa a cor 'onPrimary' do tema para o texto ***
                      color: colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    color: themeManager.getCompareCardTextColor(),
                  ),
                ),
                subtitle: Text(
                  'Melhor preço: ${currencyFormat.format(item.bestPrice)}',
                  style: TextStyle(
                    color: themeManager.getCompareSavingsTextColor(),
                  ),
                ),
                trailing: Text(
                  location.name,
                  style: TextStyle(
                    color: themeManager.getCompareCardTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Método _buildLocationComparison com cores do tema atual
  Widget _buildLocationComparison(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final totals = BudgetUtils.calculateTotalsByLocation(budget);
    // Obtém o esquema de cores do tema atual
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: themeManager.getCompareCardBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparação por Estabelecimento',
              style: TextStyle(
                color: themeManager.getCompareCardTitleColor(),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...budget.locations.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final location = entry.value;
              final total = totals[location.id] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  // *** CORREÇÃO: Usa a cor primária do tema para o fundo do círculo ***
                  backgroundColor: colorScheme.primary,
                  radius: 12,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      // *** CORREÇÃO: Usa a cor 'onPrimary' do tema para o texto ***
                      color: colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  location.name,
                  style: TextStyle(
                    color: themeManager.getCompareCardTextColor(),
                  ),
                ),
                subtitle: Text(
                  location.address,
                  style: TextStyle(
                    color: themeManager.getCompareSubtitleTextColor(),
                  ),
                ),
                trailing: Text(
                  currencyFormat.format(total),
                  style: TextStyle(
                    color: themeManager.getCompareCardTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
