import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/data/default_items.dart';
import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/service/budget_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/utils/budget_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final BudgetService _budgetService = BudgetService();
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  List<Budget>? _budgets;
  String? _error;
  // chaves para uso no tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetService.getAllBudgets();
      setState(() {
        _budgets = budgets;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Erro ao carregar orçamentos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Budget> _getFilteredBudgets() {
    if (_budgets == null) return [];
    var filtered = List<Budget>.from(_budgets!);

    if (_searchController.text.isNotEmpty) {
      final searchResults = BudgetUtils.searchProducts(_searchController.text);
      filtered = filtered.where((budget) {
        return budget.items.any(
          (item) => searchResults.any((result) => result['name'] == item.name),
        );
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((budget) {
        return budget.items.any(
          (item) => item.category == _selectedCategory,
        );
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Scaffold(
      appBar: AppBar(
        // seta de voltar visível e com GlobalKey
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: themeManager.getBudgetListHeaderTextColor(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meus Orçamentos',
          style: TextStyle(
            color: themeManager.getBudgetListHeaderTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeManager.getBudgetListHeaderColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBudgets,
            color: themeManager.getBudgetListHeaderTextColor(),
          ),
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline),
            color: themeManager.getBudgetListHeaderTextColor(),
            onPressed: () => _showBudgetListHelp(context),
          ),
        ],
      ),
      backgroundColor: themeManager.getBudgetListCardBackgroundColor(),
      body: _buildBody(themeManager),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_budget',
        onPressed: () => _showCreateBudgetDialog(context),
        label: Text(
          'Novo Orçamento',
          style: TextStyle(color: themeManager.getBudgetListHeaderTextColor()),
        ),
        icon: Icon(
          MyFlutterApp.building,
          color: themeManager.getBudgetListHeaderTextColor(),
        ),
        backgroundColor: themeManager.getBudgetListHeaderColor(),
      ),
    );
  }

  Widget _buildBody(ThemeManager themeManager) {
    if (_isLoading && _budgets == null) {
      return Center(
        child: CircularProgressIndicator(
          color: themeManager.getBudgetListHeaderColor(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(
                color: themeManager.getBudgetListCardTextColor(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBudgets,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeManager.getBudgetListHeaderColor(),
                foregroundColor: themeManager.getBudgetListHeaderTextColor(),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(themeManager),
        _buildCategoryFilter(themeManager),
        Expanded(child: _buildBudgetList(themeManager)),
      ],
    );
  }

  // Adicione este método na classe _BudgetListScreenState
  void _showBudgetListHelp(BuildContext context) {
    final themeManager = context.read<ThemeManager>();
    final appThemes = AppThemes();

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
                                themeManager.getBudgetListHeaderColor(),
                            child: Icon(
                              MyFlutterApp.building,
                              color:
                                  themeManager.getBudgetListHeaderTextColor(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Lista de Orçamentos",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: appThemes.getCardTitleColor(),
                                  ),
                                ),
                                Text(
                                  "Como gerenciar seus orçamentos",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: appThemes.getListTileSubtitleColor(),
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

                    // Seção 1: Barra de Pesquisa
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Barra de Pesquisa",
                        icon: Icons.search,
                        iconColor: themeManager.getBudgetListHeaderColor(),
                        content:
                            "Use a barra de pesquisa para encontrar orçamentos específicos:\n\n"
                            "• Digite o nome de um produto para filtrar os orçamentos que o contêm\n\n"
                            "• A pesquisa é instantânea e mostra resultados à medida que você digita\n\n"
                            "• Clique no ícone de 'X' para limpar sua pesquisa atual",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Filtro por Categorias
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Filtro por Categorias",
                        icon: Icons.category,
                        iconColor: Colors.blue,
                        content:
                            "Use os chips de categorias para filtrar orçamentos:\n\n"
                            "• Selecione 'Todos' para ver todos os orçamentos\n\n"
                            "• Clique em uma categoria específica para ver apenas os orçamentos que contêm itens dessa categoria\n\n"
                            "• É possível combinar a pesquisa de texto com o filtro por categoria",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Lista de Orçamentos
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Cards de Orçamento",
                        icon: MyFlutterApp.building,
                        iconColor: Colors.orange,
                        content:
                            "Cada card mostra informações importantes sobre um orçamento:\n\n"
                            "• Título do orçamento\n\n"
                            "• Data de criação\n\n"
                            "• Total original: soma dos preços médios ou padrão\n\n"
                            "• Melhor preço: custo total comprando cada item pelo menor preço\n\n"
                            "• Economia: diferença entre o total original e o melhor preço",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Interação com os Cards
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Gerenciando Orçamentos",
                        icon: Icons.touch_app,
                        iconColor: Colors.green,
                        content:
                            "Você pode interagir com os orçamentos de várias formas:\n\n"
                            "• Toque em um card para abrir os detalhes do orçamento\n\n"
                            "• Use o ícone de lixeira para excluir um orçamento\n\n"
                            "• Ao excluir, será solicitada uma confirmação para evitar exclusões acidentais\n\n"
                            "• A exclusão de um orçamento não pode ser desfeita",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Botão Novo Orçamento
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Criando Novos Orçamentos",
                        icon: Icons.add_circle,
                        iconColor: Colors.purple,
                        content: "Para criar um novo orçamento:\n\n"
                            "• Clique no botão flutuante 'Novo Orçamento' no canto inferior direito\n\n"
                            "• Digite um título descritivo para seu orçamento\n\n"
                            "• Clique em 'Criar' para confirmar\n\n"
                            "• Você será direcionado para a tela de detalhes do orçamento, onde poderá adicionar itens e locais",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Botão de Atualização
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Atualizando a Lista",
                        icon: Icons.refresh,
                        iconColor: themeManager.getBudgetListHeaderColor(),
                        content: "Caso não esteja vendo mudanças recentes:\n\n"
                            "• Use o botão de atualização no canto superior direito\n\n"
                            "• Isso recarregará todos os orçamentos do banco de dados\n\n"
                            "• Útil após adicionar ou modificar orçamentos em outra parte do aplicativo",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dicas
                    FadeAnimation(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeManager
                              .getBudgetListHeaderColor()
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager
                                .getBudgetListHeaderColor()
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
                                      themeManager.getBudgetListHeaderColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        themeManager.getBudgetListHeaderColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Crie orçamentos separados para diferentes finalidades, como 'Compras da Semana', 'Material Escolar' ou 'Reforma'. Isso facilita o acompanhamento e comparação de preços para cada projeto.",
                              style: TextStyle(
                                  color: appThemes.getCardTextColor()),
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
                                themeManager.getBudgetListHeaderColor(),
                            foregroundColor:
                                themeManager.getBudgetListHeaderTextColor(),
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
    final appThemes = AppThemes();

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
                  color: appThemes.getCardTitleColor(),
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
                color: appThemes.getCardTextColor(),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeManager themeManager) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SearchBar(
        controller: _searchController,
        hintText: 'Buscar produtos...',
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: themeManager.getBudgetListSearchIconColor()),
        ),
        leading: Icon(
          Icons.search,
          color: themeManager.getBudgetListSearchIconColor(),
        ),
        trailing: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: themeManager.getBudgetListSearchIconColor(),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
        onChanged: (_) => setState(() {}),
        backgroundColor: WidgetStatePropertyAll(
          themeManager.getBudgetListSearchBarColor(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeManager themeManager) {
    final appThemes = AppThemes();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(
              'Todos',
              style: TextStyle(
                color: themeManager.getBudgetListCardTextColor(),
              ),
            ),
            selected: _selectedCategory == null,
            onSelected: (selected) => setState(() => _selectedCategory = null),
            backgroundColor: themeManager.getBudgetListCardBackgroundColor(),
            selectedColor: themeManager.getBudgetListCardBackgroundColor(),
            checkmarkColor: themeManager.getBudgetListCardTextColor(),
            side: BorderSide(color: appThemes.getCardBorderColor(), width: 1),
          ),
          ...defaultItems.map((e) => e['category'] as String).toSet().map(
                (category) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: themeManager.getBudgetListCardTextColor(),
                      ),
                    ),
                    selected: _selectedCategory == category,
                    onSelected: (selected) => setState(() {
                      _selectedCategory = selected ? category : null;
                    }),
                    backgroundColor:
                        themeManager.getBudgetListCardBackgroundColor(),
                    selectedColor:
                        themeManager.getBudgetListCardBackgroundColor(),
                    checkmarkColor: themeManager.getBudgetListCardTextColor(),
                    side: BorderSide(
                        color: appThemes.getCardBorderColor(), width: 1),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(ThemeManager themeManager) {
    final filteredBudgets = _getFilteredBudgets();

    if (filteredBudgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: themeManager.getBudgetListCardTextColor().withAlpha(
                    (0.5 * 255).toInt(),
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum orçamento encontrado',
              style: TextStyle(
                color: themeManager.getBudgetListCardTextColor(),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredBudgets.length,
      itemBuilder: (context, index) {
        final budget = filteredBudgets[index];
        return _BudgetCard(
          budget: budget,
          onTap: () => _navigateToBudgetDetail(budget),
          onDelete: () => _deleteBudget(budget),
          currencyFormat: currencyFormat,
          themeManager: themeManager,
        );
      },
    );
  }

  void _navigateToBudgetDetail(Budget budget) {
    Navigator.pushNamed(context, '/budget/detail', arguments: budget);
  }

  Future<void> _showCreateBudgetDialog(BuildContext context) async {
    context.read<ThemeManager>();
    final appThemes = AppThemes();
    final titleController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemes.getDialogBackgroundColor(),
        title: Text(
          'Novo Orçamento',
          style: TextStyle(
            color: appThemes.getDialogTitleColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: TextField(
            controller: titleController,
            decoration: appThemes.getStandardInputDecoration(
              'Título do Orçamento',
              hint: 'Ex: Compras do Mês',
            ),
            style: TextStyle(
              color: appThemes.getInputTextColor(),
            ),
            cursorColor: appThemes.getInputCursorColor(),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: appThemes.getDialogCancelButtonTextColor(),
              backgroundColor: appThemes.getDialogCancelButtonColor(),
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                try {
                  final budget = await _budgetService.createBudget(
                    titleController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _navigateToBudgetDetail(budget);
                    _showSuccess('Orçamento criado com sucesso!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showError('Erro ao criar orçamento: $e');
                  }
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: appThemes.getDialogButtonColor(),
              foregroundColor: appThemes.getDialogButtonTextColor(),
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    final appThemes = AppThemes();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemes.getDialogBackgroundColor(),
        title: Text(
          'Excluir Orçamento',
          style: TextStyle(
            color: appThemes.getDialogTitleColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir este orçamento? Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: appThemes.getDialogTextColor(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: appThemes.getDialogCancelButtonTextColor(),
              backgroundColor: appThemes.getDialogCancelButtonColor(),
            ),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: appThemes.getInputErrorColor(),
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _budgetService.deleteBudget(budget.id);
        await Future.delayed(const Duration(milliseconds: 300));
        final updatedBudgets = await _budgetService.getAllBudgets();

        if (mounted) {
          setState(() => _budgets = updatedBudgets);
          _showSuccess('Orçamento excluído com sucesso');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao excluir orçamento: $e');
        }
      }
    }
  }

  void _showSuccess(String message) {
    final themeManager = context.read<ThemeManager>();
    final appThemes = AppThemes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: appThemes.getCardButtonTextColor()),
        ),
        backgroundColor: themeManager.getBudgetListHeaderColor(),
      ),
    );
  }

  void _showError(String message) {
    final appThemes = AppThemes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: appThemes.getCardButtonTextColor()),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final NumberFormat currencyFormat;
  final ThemeManager themeManager;

  const _BudgetCard({
    required this.budget,
    required this.onTap,
    required this.onDelete,
    required this.currencyFormat,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    final appThemes = AppThemes();

    return Card(
      color: appThemes.getCardBackgroundColor(),
      elevation: appThemes.getCardElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(appThemes.getCardBorderRadius()),
        side: BorderSide(color: appThemes.getCardBorderColor(), width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(appThemes.getCardBorderRadius()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      budget.title,
                      style: TextStyle(
                        color: appThemes.getCardTitleColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(MyFlutterApp.trash_alt),
                    onPressed: onDelete,
                    color: appThemes.getInputErrorColor(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Criado em: ${DateFormat('dd/MM/yyyy').format(budget.date)}',
                style: TextStyle(
                  color: appThemes.getCardTextColor().withAlpha(
                        (0.7 * 255).toInt(),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: appThemes.getCardDividerColor()),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColumn(
                    label: 'Total Original',
                    value: currencyFormat.format(budget.summary.totalOriginal),
                    appThemes: appThemes,
                  ),
                  _InfoColumn(
                    label: 'Melhor Preço',
                    value: currencyFormat.format(budget.summary.totalOptimized),
                    appThemes: appThemes,
                  ),
                  _InfoColumn(
                    label: 'Economia',
                    value: currencyFormat.format(budget.summary.savings),
                    appThemes: appThemes,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final AppThemes appThemes;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.appThemes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: appThemes.getListTileSubtitleColor(),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: appThemes.getCardTextColor(),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
