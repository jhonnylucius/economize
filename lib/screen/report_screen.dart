import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/moedas/currency_service.dart';
import 'package:economize/service/report_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  late CurrencyService _currencyService;
  List<dynamic> _reportData = [];
  String _selectedType = 'receitas';
  String _selectedSpecificType = 'Todas';
  bool _isLoading = false;
  double _total = 0;
  Map<String, double> _totalsByType = {};
  Map<String, List<String>> _availableTypes = {'receitas': [], 'despesas': []};
  late AnimationController _filterAnimationController;
  bool _isFiltering = false;
  // chaves para uso no tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currencyService = context.read<CurrencyService>();
    _fetchAvailableTypesAndGenerateReport();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableTypesAndGenerateReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _availableTypes = await _reportService.getAvailableTypes();
      await _generateReport(isInitialLoad: true);
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao buscar tipos iniciais: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateReport({bool isInitialLoad = false}) async {
    if (!isInitialLoad && mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    } else if (!mounted) {
      return;
    }

    try {
      final now = DateTime.now();
      final period = '${now.month.toString().padLeft(2, '0')}/${now.year}';
      _validateSelectedSpecificTypeOnDemand();

      if (!isInitialLoad) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;

      final result = await _reportService.generateReport(
        type: _selectedType,
        period: period,
        specificType: _selectedSpecificType,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _reportData = result['items'];
            _total = result['total'];
            _totalsByType = Map<String, double>.from(result['totals']);
            if (result['availableTypes'] != null) {
              _availableTypes = result['availableTypes'];
              _validateSelectedSpecificTypeOnDemand();
            }
          });
        } else {
          _showErrorDialog('Erro ao gerar relatório: ${result['error']}');
          setState(() {
            _reportData = [];
            _total = 0;
            _totalsByType = {};
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao gerar relatório: $e');
        setState(() {
          _reportData = [];
          _total = 0;
          _totalsByType = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validateSelectedSpecificTypeOnDemand() {
    final currentList = _availableTypes[
            _selectedType == 'receitas' ? 'receitas' : 'despesas'] ??
        [];
    final validItems = ['Todas', ...currentList.where((t) => t != 'Todas')];
    if (!validItems.contains(_selectedSpecificType)) {
      _selectedSpecificType = 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();
    final theme = Theme.of(context);
    final isDarkTheme = themeManager.currentThemeType != ThemeType.light;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return ResponsiveScreen(
      appBar: _buildAppBar(theme, themeManager, isDarkTheme),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: _buildBody(themeManager),
    );
  }

  AppBar _buildAppBar(
      ThemeData theme, ThemeManager themeManager, bool isDarkTheme) {
    return AppBar(
      title: SlideAnimation.fromTop(
        child: const Text(
          'Relatórios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: themeManager.getCurrentPrimaryColor(),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 100),
          child: IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.view_list,
              progress: _filterAnimationController,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFiltering = !_isFiltering;
                if (_isFiltering) {
                  _filterAnimationController.forward();
                } else {
                  _filterAnimationController.reverse();
                }
              });
            },
            tooltip: 'Alternar visualização',
          ),
        ),
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 150),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _generateReport(),
            tooltip: 'Atualizar relatório',
          ),
        ),
        SlideAnimation.fromTop(
          delay: const Duration(milliseconds: 200),
          child: IconButton(
            key: _helpButtonKey, // Chave para tutorial
            tooltip: 'Ajuda', // Texto do tooltip
            icon: const Icon(
              Icons.help_outline, // Ícone de ajuda
              color: Colors.white,
            ),
            onPressed: () =>
                _showReportScreenHelp(context), // Chama o método de ajuda
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Adicione este método na classe _ReportScreenState
  void _showReportScreenHelp(BuildContext context) {
    final themeManager = context.read<ThemeManager>();
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final textColor = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GlassContainer(
            frostedEffect: true,
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
                                const Color.fromARGB(255, 216, 78, 196),
                            child: Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Relatórios Financeiros",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Como analisar suas finanças em detalhes",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
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

                    // Seção 1: Filtros
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Filtros de Relatório",
                        icon: Icons.filter_list,
                        iconColor: const Color.fromARGB(255, 216, 78, 196),
                        content:
                            "Personalize seus relatórios com filtros específicos:\n\n"
                            "• Botões de Receitas/Despesas: Alterne entre visualizar receitas ou despesas\n\n"
                            "• Tipo Específico: Filtre por categorias como 'Salário', 'Alimentação', etc.\n\n"
                            "• Período: O relatório mostra dados do mês atual\n\n"
                            "• Os filtros aplicados atualizam automaticamente os dados mostrados",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Visualização em lista ou grade
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Modos de Visualização",
                        icon: Icons.view_list,
                        iconColor: Colors.blue,
                        content:
                            "Escolha como deseja visualizar seus dados:\n\n"
                            "• Clique no botão de alternar visualização (lista/grade)\n\n"
                            "• Visualização em Lista: Mostra detalhes em formato de lista\n\n"
                            "• Visualização em Grade: Exibe dados em formato de cards\n\n"
                            "• Cada formato facilita diferentes tipos de análise",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Totais por categoria
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Totais por Categoria",
                        icon: Icons.pie_chart_outline,
                        iconColor: Colors.green,
                        content:
                            "Analise a distribuição de suas finanças por categoria:\n\n"
                            "• O card 'Total por Categoria' mostra quanto você gastou/recebeu em cada tipo\n\n"
                            "• Barras de progresso indicam a proporção de cada categoria em relação ao total\n\n"
                            "• As categorias são ordenadas da maior para a menor\n\n"
                            "• Use essa análise para identificar seus maiores gastos ou fontes de receita",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Lista de itens
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Lista de Transações",
                        icon: Icons.list_alt,
                        iconColor: Colors.orange,
                        content: "Veja todas as transações filtradas:\n\n"
                            "• Cada item mostra descrição, categoria e valor\n\n"
                            "• Ícones indicam se é uma receita (seta para cima) ou despesa (seta para baixo)\n\n"
                            "• Valores são destacados para fácil visualização\n\n"
                            "• A lista é animada para melhor experiência de usuário",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Card de total
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Total do Relatório",
                        icon: Icons.calculate,
                        iconColor: Colors.purple,
                        content:
                            "Na parte inferior, veja o total consolidado:\n\n"
                            "• Card destacado mostra o valor total das transações filtradas\n\n"
                            "• 'Total Recebido' para receitas ou 'Total Gasto' para despesas\n\n"
                            "• Valor destacado para fácil visualização\n\n"
                            "• Representa a soma de todas as transações exibidas no relatório",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Exportação e atualização
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Atualização de Dados",
                        icon: Icons.refresh,
                        iconColor: Colors.teal,
                        content: "Mantenha seus relatórios atualizados:\n\n"
                            "• O botão de atualização recarrega os dados mais recentes\n\n"
                            "• Utilize sempre que adicionar novas receitas ou despesas\n\n"
                            "• Uma animação de carregamento indica que os dados estão sendo atualizados\n\n"
                            "• Os relatórios mostram apenas dados do mês atual por padrão",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 216, 78, 196)
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(255, 216, 78, 196)
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
                                  color:
                                      const Color.fromARGB(255, 216, 78, 196),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 216, 78, 196),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Analise seus relatórios regularmente para identificar padrões de gastos. Compare 'Total por Categoria' de um mês para outro para verificar onde você está economizando ou gastando mais.",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão para fechar
                    Center(
                      child: ScaleAnimation.bounceIn(
                        delay: const Duration(milliseconds: 800),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeManager.getFundoTextoButtonsRelatorios(),
                            foregroundColor:
                                themeManager.getTextoButtonsRelatorios(),
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
                  color: Colors.black87,
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
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final textColor = isDark ? Colors.white : Colors.black;

    return Stack(
      children: [
        // Troque o fundo decorativo pelo fundo branco do getter
        Container(
          color:
              themeManager.getFundosTelaEFundoFiltrosRelatorios(), // <-- aqui!
        ),
        Column(
          children: [
            _buildFilters(themeManager, textColor),
            Expanded(
              child: _buildScrollableArea(themeManager, textColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeManager themeManager, Color textColor) {
    Theme.of(context);
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return SlideAnimation.fromTop(
      child: Container(
        decoration: BoxDecoration(
          color: themeManager.getFundosTelaEFundoFiltrosRelatorios(),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            SlideAnimation.fromLeft(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Filtrar Relatório',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeManager.getTextosRelatorios(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões para escolher entre Receitas e Despesas
            SlideAnimation.fromRight(
              delay: const Duration(milliseconds: 150),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        'receitas',
                        'Receitas',
                        Icons.attach_money,
                        Colors.green,
                        themeManager,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterButton(
                        'despesas',
                        'Despesas',
                        Icons.money_off,
                        Colors.red,
                        themeManager,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dropdown para tipos específicos
            SlideAnimation.fromLeft(
              delay: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                child: FutureBuilder<Map<String, List<String>>>(
                  future: Future.value(_availableTypes),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return SizedBox(
                        height: 60,
                        child: (snapshot.hasError)
                            ? Center(
                                child: Text(
                                  'Erro ao carregar tipos',
                                  style: TextStyle(
                                      color:
                                          themeManager.getTextosRelatorios()),
                                ),
                              )
                            : null,
                      );
                    }

                    final typesMap = snapshot.data!;
                    final currentTypeList = typesMap[_selectedType == 'receitas'
                            ? 'receitas'
                            : 'despesas'] ??
                        [];
                    final dropdownItems = [
                      'Todas',
                      ...currentTypeList.where((t) => t != 'Todas')
                    ];
                    final validSelectedValue =
                        dropdownItems.contains(_selectedSpecificType)
                            ? _selectedSpecificType
                            : 'Todas';

                    if (_selectedSpecificType != validSelectedValue) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedSpecificType = validSelectedValue;
                          });
                        }
                      });
                    }

                    return Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager.getTextosRelatorios(),
                            width: 1,
                          ),
                          color: isDark
                              ? themeManager.getFundosCardsRelatorios()
                              : themeManager.getFundosCardsRelatorios()),
                      child: DropdownButtonFormField<String>(
                        value: validSelectedValue,
                        decoration: InputDecoration(
                          labelText: 'Tipo Específico',
                          labelStyle: TextStyle(
                            color: themeManager.getTextoButtonsRelatorios(),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        dropdownColor:
                            themeManager.getFundosTelaEFundoFiltrosRelatorios(),
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_circle,
                          color: themeManager.getIconesRelatorios(),
                        ),
                        items: dropdownItems.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            themeManager.getTextosRelatorios(),
                                        width: 2),
                                    borderRadius: BorderRadius.circular(4),
                                    color: validSelectedValue == tipo
                                        ? themeManager.getTextosRelatorios()
                                        : themeManager.getTextosRelatorios(),
                                  ),
                                  child: validSelectedValue == tipo
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color:
                                              Color.fromARGB(255, 216, 78, 196),
                                        )
                                      : null,
                                ),
                                Expanded(
                                  child: Text(
                                    tipo,
                                    style: TextStyle(
                                      color: themeManager.getTextosRelatorios(),
                                      fontWeight: validSelectedValue == tipo
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedSpecificType) {
                            setState(() => _selectedSpecificType = value);
                            _generateReport();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String type, String label, IconData icon,
      Color accentColor, ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final isSelected = _selectedType == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_selectedType != type) {
            setState(() {
              _selectedType = type;
              _selectedSpecificType = 'Todas';
            });
            _generateReport();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? accentColor.withAlpha((0.2 * 255).toInt())
                : isDark
                    ? themeManager.getBosdasRelatorios()
                    : Colors.white,
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : isDark
                      ? themeManager.getBosdasRelatorios()
                      : themeManager.getBosdasRelatorios(),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? accentColor
                    : isDark
                        ? Colors.white70
                        : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? accentColor
                      : isDark
                          ? Colors.white
                          : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableArea(ThemeManager themeManager, Color textColor) {
    Theme.of(context);

    if (_isLoading && _reportData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color.fromARGB(255, 216, 78, 196),
            ),
            const SizedBox(height: 16),
            Text(
              'Carregando relatório...',
              style: TextStyle(
                color: themeManager.getTextosRelatorios(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoading && _reportData.isEmpty) {
      return _buildEmptyState(themeManager);
    }

    return Container(
      color: themeManager.getRelatorioFundoTemaRoxo(), // <-- aqui!
      child: _isFiltering
          ? _buildGridView(themeManager, textColor)
          : _buildListView(themeManager, textColor),
    );
  }

  Widget _buildEmptyState(ThemeManager themeManager) {
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final textColor = isDark ? Colors.white : Colors.black;

    return Center(
      child: SlideAnimation.fromBottom(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon_removedbg.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado encontrado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeManager.getTextosRelatorios(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Não encontramos registros para os filtros selecionados. Tente outros critérios de busca.',
                style: TextStyle(
                  fontSize: 16,
                  color: themeManager.getTextosRelatorios(),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _generateReport(),
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeManager.getFundoTextoButtonsRelatorios(),
                foregroundColor: themeManager.getTextoButtonsRelatorios(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(ThemeManager themeManager, Color textColor) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Total por Tipo Card
        _buildTotalsByType(themeManager, textColor),

        // Lista de itens
        ..._buildReportListItems(themeManager, textColor),

        // Total geral
        _buildTotal(themeManager, textColor),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGridView(ThemeManager themeManager, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // ✅ Total por Tipo Card - DENTRO DO SCROLL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTotalsByType(themeManager, textColor),
          ),

          // ✅ Total geral - DENTRO DO SCROLL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTotal(themeManager, textColor),
          ),

          // ✅ Grid de itens - DENTRO DO SCROLL com altura fixa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GridView.builder(
              shrinkWrap:
                  true, // ✅ IMPORTANTE: Permite o grid crescer conforme necessário
              physics:
                  const NeverScrollableScrollPhysics(), // ✅ Desabilita scroll próprio do grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: _reportData.length,
              itemBuilder: (context, index) {
                final item = _reportData[index];
                return _buildGridItem(item, index, themeManager, textColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      dynamic item, int index, ThemeManager themeManager, Color textColor) {
    final isDark = themeManager.currentThemeType != ThemeType.light;
    final titleText = _selectedType == 'receitas'
        ? (item['descricaoDaReceita'] ?? 'Sem descrição')
        : (item['descricaoDaDespesa'] ?? 'Sem descrição');
    final subtitleText = _selectedType == 'receitas'
        ? (item['tipoReceita'] ?? 'Tipo não especificado')
        : (item['tipoDespesa'] ?? 'Tipo não especificado');
    final amount = item['preco'] ?? 0.0;

    return ScaleAnimation(
      fromScale: 0.9,
      delay: Duration(milliseconds: 50 * index % 300),
      child: Card(
        elevation: 3,
        color: themeManager.getFundosCardsRelatorios(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: themeManager.getBosdasRelatorios(),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone centralizado
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (_selectedType == 'receitas' ? Colors.green : Colors.red)
                          .withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedType == 'receitas'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color:
                      _selectedType == 'receitas' ? Colors.green : Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              // Valor logo abaixo do ícone
              Text(
                _currencyService.formatCurrency(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color.fromARGB(255, 216, 78, 196),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Título
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: themeManager.getTextosRelatorios(),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Subtítulo
              Text(
                subtitleText,
                style: TextStyle(
                  fontSize: 13,
                  color: themeManager.getTextosRelatorios(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Tipo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: themeManager.getBosdasRelatorios()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedType == 'receitas'
                          ? Icons.account_balance_wallet_outlined
                          : Icons.shopping_bag_outlined,
                      size: 12,
                      color: themeManager.getTextosRelatorios(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedType == 'receitas' ? 'Receita' : 'Despesa',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeManager.getTextosRelatorios(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsByType(ThemeManager themeManager, Color textColor) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    if (_totalsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = _totalsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SlideAnimation.fromTop(
      child: Card(
        margin: const EdgeInsets.all(8),
        color: themeManager.getFundosCardsRelatorios(),
        elevation: isDark ? 2 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: themeManager.getBosdasRelatorios(),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    color: themeManager.getIconesRelatorios(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total por Categoria',
                    style: TextStyle(
                      color: themeManager.getTextosRelatorios(),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: themeManager.getTextosRelatorios(),
                  thickness: 1,
                ),
              ),
              Column(
                children: sortedEntries.map((entry) {
                  final percentageOfTotal =
                      _total > 0 ? entry.value / _total : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: themeManager.getTextosRelatorios(),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _currencyService.formatCurrency(entry.value),
                              style: TextStyle(
                                color: _selectedType == 'receitas'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Barra de progresso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: percentageOfTotal.toDouble(),
                            backgroundColor: isDark
                                ? Colors.white.withAlpha((0.1 * 255).toInt())
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _selectedType == 'receitas'
                                  ? Colors.green.withAlpha((0.8 * 255).toInt())
                                  : Colors.red.withAlpha((0.8 * 255).toInt()),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReportListItems(
      ThemeManager themeManager, Color textColor) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    if (_reportData.isEmpty) {
      return [const SizedBox.shrink()];
    }

    return List.generate(_reportData.length, (index) {
      final item = _reportData[index];
      final titleText = _selectedType == 'receitas'
          ? (item['descricaoDaReceita']?.isNotEmpty == true
              ? item['descricaoDaReceita']
              : (item['tipoReceita'] ?? 'Sem descrição'))
          : (item['descricaoDaDespesa']?.isNotEmpty == true
              ? item['descricaoDaDespesa']
              : (item['tipoDespesa'] ?? 'Sem descrição'));
      final subtitleText = _selectedType == 'receitas'
          ? (item['tipoReceita'] ?? 'Tipo não especificado')
          : (item['tipoDespesa'] ?? 'Tipo não especificado');
      final amount = item['preco'] ?? 0.0;

      return SlideAnimation.fromRight(
        delay: Duration(milliseconds: 50 * index % 300),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: themeManager.getFundosCardsRelatorios(),
          elevation: isDark ? 1 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: themeManager.getBosdasRelatorios(),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_selectedType == 'receitas' ? Colors.green : Colors.red)
                    .withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _selectedType == 'receitas'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: _selectedType == 'receitas' ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            title: Text(
              titleText,
              style: TextStyle(
                color: themeManager.getTextosRelatorios(),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 12,
                  color: themeManager.getIconesRelatorios(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitleText,
                    style: TextStyle(
                      color: themeManager.getTextosRelatorios(),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 216, 78, 196)
                    .withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currencyService.formatCurrency(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color.fromARGB(255, 216, 78, 196),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTotal(ThemeManager themeManager, Color textColor) {
    final isDark = themeManager.currentThemeType != ThemeType.light;

    return SlideAnimation.fromBottom(
      delay: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        color: themeManager.getFundosCardsRelatorios(), // <-- aqui!
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: themeManager.getBosdasRelatorios(), // <-- aqui!
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total ${_selectedType == 'receitas' ? 'Recebido' : 'Gasto'}',
                    style: TextStyle(
                      color: themeManager.getTextosRelatorios(),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _selectedType == 'receitas'
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: themeManager.getFundosCardsRelatorios(),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Período atual',
                        style: TextStyle(
                          color: themeManager.getTextosRelatorios(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _currencyService.formatCurrency(_total),
                style: TextStyle(
                  color: themeManager.getTextosRelatorios(),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    final themeManager = context.read<ThemeManager>();
    final isDark = themeManager.currentThemeType != ThemeType.light;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          Icons.error_outline,
          color: Colors.red.shade700,
          size: 32,
        ),
        title: Text(
          'Erro',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: themeManager.getTextosRelatorios(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 216, 78, 196),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PatternPainter extends CustomPainter {
  final Color color;
  final math.Random random = math.Random(42); // Seed fixo para padrão estático

  _PatternPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar padrão de formas geométricas não piscantes
    // Grade de formas de fundo fixa
    final cellSize = size.width / 8; // Ajustado para mais densidade

    for (int i = -1; i < 15; i++) {
      for (int j = -1; j < 30; j++) {
        final x = i * cellSize + random.nextDouble() * (cellSize * 0.5);
        final y = j * cellSize + random.nextDouble() * (cellSize * 0.5);

        final shapeType = (i + j) % 4;

        switch (shapeType) {
          case 0:
            // Gráfico de barras
            _drawChart(canvas, paint, x, y, cellSize * 0.4);
            break;
          case 1:
            // Círculos
            final radius = cellSize * (0.1 + random.nextDouble() * 0.1);
            canvas.drawCircle(Offset(x, y), radius, paint);
            break;
          case 2:
            // Símbolo %
            _drawPercentSign(canvas, paint, x, y, cellSize * 0.4);
            break;
          case 3:
            // Ícone de documento/relatório
            _drawReportIcon(canvas, paint, x, y, cellSize * 0.4);
            break;
        }
      }
    }
  }

  void _drawChart(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    final halfSize = size / 2;

    // Linha base
    path.moveTo(x - halfSize, y + halfSize * 0.8);
    path.lineTo(x + halfSize, y + halfSize * 0.8);

    // Barras do gráfico
    final barWidth = size / 5;

    // Barra 1
    path.moveTo(x - halfSize + barWidth * 0.5, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 0.5, y);

    // Barra 2
    path.moveTo(x - halfSize + barWidth * 1.8, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 1.8, y - halfSize * 0.3);

    // Barra 3
    path.moveTo(x - halfSize + barWidth * 3.1, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 3.1, y + halfSize * 0.4);

    // Barra 4
    path.moveTo(x - halfSize + barWidth * 4.4, y + halfSize * 0.8);
    path.lineTo(x - halfSize + barWidth * 4.4, y - halfSize * 0.5);

    canvas.drawPath(path, paint);
  }

  void _drawPercentSign(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    final halfSize = size / 2;

    // Linha diagonal do símbolo %
    path.moveTo(x - halfSize * 0.7, y + halfSize * 0.7);
    path.lineTo(x + halfSize * 0.7, y - halfSize * 0.7);

    // Círculo superior
    canvas.drawCircle(
        Offset(x - halfSize * 0.5, y - halfSize * 0.5), size * 0.15, paint);

    // Círculo inferior
    canvas.drawCircle(
        Offset(x + halfSize * 0.5, y + halfSize * 0.5), size * 0.15, paint);

    canvas.drawPath(path, paint);
  }

  void _drawReportIcon(
      Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    final halfSize = size / 2;

    // Forma do documento
    path.moveTo(x - halfSize * 0.7, y - halfSize * 0.8);
    path.lineTo(x + halfSize * 0.7, y - halfSize * 0.8);
    path.lineTo(x + halfSize * 0.7, y + halfSize * 0.8);
    path.lineTo(x - halfSize * 0.7, y + halfSize * 0.8);
    path.close();

    // Linhas de texto
    path.moveTo(x - halfSize * 0.5, y - halfSize * 0.5);
    path.lineTo(x + halfSize * 0.5, y - halfSize * 0.5);

    path.moveTo(x - halfSize * 0.5, y);
    path.lineTo(x + halfSize * 0.5, y);

    path.moveTo(x - halfSize * 0.5, y + halfSize * 0.5);
    path.lineTo(x + halfSize * 0.3, y + halfSize * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => oldDelegate.color != color;
}
