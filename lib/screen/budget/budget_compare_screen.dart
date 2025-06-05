import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
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
  // chaves para tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();
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
        // seta de voltar visível e identificável
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: themeManager.getCompareHeaderTextColor(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comparação - ${budget.title}',
          style: TextStyle(
            // Usa a cor definida no ThemeManager para o header
            color: themeManager.getCompareHeaderTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        // Deixe o header igual ao das outras telas:
        backgroundColor: themeManager.getCompareHeaderColor(),
        foregroundColor: themeManager.getCompareHeaderTextColor(),
        elevation: 0,
        actions: [
          // ícone de ajuda em vez de casa
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline),
            color: themeManager.getCompareHeaderTextColor(),
            onPressed: () => _showBudgetCompareHelp(context),
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

  // Adicione este método na classe BudgetCompareScreen
  void _showBudgetCompareHelp(BuildContext context) {
    final themeManager = context.read<ThemeManager>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            blur: 10,
            opacity: 0.2,
            borderRadius: 24,
            borderColor: Colors.white.withAlpha((0.3 * 255).round()),
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
                    SlideAnimation.fromTop(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.compare_arrows,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Comparação de Orçamentos",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeManager.getCompareCardTitleColor(),
                                  ),
                                ),
                                Text(
                                  "Como usar a ferramenta de comparação",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeManager
                                        .getCompareSubtitleTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 1: Resumo do Orçamento
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Resumo do \nOrçamento",
                        icon: Icons.summarize,
                        iconColor: Theme.of(context).colorScheme.primary,
                        content:
                            "O card de resumo mostra os dados gerais do seu orçamento:\n\n"
                            "• Total geral dos itens\n"
                            "• Número de estabelecimentos comparados\n"
                            "• Economia total identificada\n"
                            "• Data de criação do orçamento",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Análise de Economia
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Análise de \nEconomia",
                        icon: Icons.savings,
                        iconColor: Colors.green,
                        content:
                            "Este gráfico mostra quanto você economiza em cada item:\n\n"
                            "• As barras representam o valor economizado por item\n"
                            "• Quanto mais alta a barra, maior a economia\n"
                            "• Abaixo do gráfico, há uma lista detalhada com os valores exatos\n"
                            "• Classificados do maior para o menor valor de economia",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Melhores Preços
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Melhores Preços\n por Item",
                        icon: Icons.local_offer,
                        iconColor: Colors.amber,
                        content:
                            "Esta seção mostra onde encontrar o melhor preço para cada item:\n\n"
                            "• Nome do item\n"
                            "• Melhor preço encontrado\n"
                            "• Estabelecimento onde o preço foi encontrado\n\n"
                            "Use esta seção para decidir onde comprar cada item específico.",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Comparação por Estabelecimento
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Comparação por\n Estabelecimento",
                        icon: Icons.store,
                        iconColor: Colors.blue,
                        content:
                            "Aqui você vê o custo total do orçamento em cada estabelecimento:\n\n"
                            "• Nome do estabelecimento\n"
                            "• Endereço\n"
                            "• Valor total da compra\n\n"
                            "Use esta seção para decidir se vale a pena comprar tudo em um só lugar.",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Tabela de Comparação de Preços
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Tabela de \nComparação de Preços",
                        icon: Icons.table_chart,
                        iconColor: Colors.purple,
                        content:
                            "A tabela completa mostra todos os preços de cada item em todos os estabelecimentos:\n\n"
                            "• As linhas representam os itens\n"
                            "• As colunas representam os estabelecimentos\n"
                            "• O melhor preço para cada item é destacado\n"
                            "• Use o butão de compartilhamento para partilhar seu orçamento com a \nfamília e amigos(única função que precisa de conexão com internet\n"
                            "• Use esta tabela para uma análise detalhada e visual",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Para economizar ao máximo, considere comprar diferentes itens em diferentes estabelecimentos, conforme indicado na seção 'Melhores Preços por Item'.",
                              style: TextStyle(
                                  color:
                                      themeManager.getCompareCardTextColor()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 700),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              const Text(
                                "Entendi!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Método auxiliar para construir seções de ajuda
  Widget _buildHelpSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    final themeManager = context.read<ThemeManager>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconColor.withAlpha((0.2 * 255).round()),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeManager.getCompareCardTitleColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: themeManager.getCompareCardTextColor(),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método _buildSavingsAnalysis original (sem alterações)
  Widget _buildSavingsAnalysis(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final savings = budget.items.map((item) {
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
        children: savings.map((entry) {
          // Calcula a altura da barra de forma segura
          double barHeight = entry.value > 0 ? entry.value / 2 : 0;
          // Limita a altura máxima se necessário para evitar barras gigantes
          barHeight = barHeight.clamp(0.0, 80.0); // Ex: Limita a 80 pixels

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Alinha barra na base
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
                    overflow: TextOverflow.ellipsis, // Evita quebra de texto
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
      children: savings.asMap().entries.map((entry) {
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
                orElse: () => BudgetLocation(
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
