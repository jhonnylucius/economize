import 'package:economize/animations/fade_animation.dart';
import 'package:economize/animations/glass_container.dart';
import 'package:economize/animations/scale_animation.dart';
import 'package:economize/animations/slide_animation.dart';
import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/model/budget/budget_location.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:economize/screen/responsive_screen.dart';
import 'package:economize/service/budget_service.dart';
import 'package:economize/service/price_history_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/theme/theme_manager.dart';
import 'package:economize/widgets/budget/add_item_form.dart';
import 'package:economize/widgets/budget/budget_item_card.dart';
import 'package:economize/widgets/budget/budget_summary_card.dart';
import 'package:economize/widgets/budget/search/item_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BudgetService _budgetService = BudgetService();
  final PriceHistoryService _historyService = PriceHistoryService();
  late Budget currentBudget;
  bool _isEditingCard = false;
  bool _isLoading = false;
  // chaves para uso no tutorial interativo
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentBudget = widget.budget;
    _refreshBudget();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método _refreshBudget original (sem alterações)
  Future<void> _refreshBudget() async {
    setState(() => _isLoading = true);
    try {
      final updatedBudget = await _budgetService.getBudget(widget.budget.id);
      if (updatedBudget != null && mounted) {
        setState(() {
          currentBudget = updatedBudget;
          // Atualiza as referências no widget original também, se necessário
          widget.budget.locations = updatedBudget.locations;
          widget.budget.items = updatedBudget.items;
          widget.budget.summary = updatedBudget.summary;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao atualizar orçamento: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    // Substitui Scaffold por ResponsiveScreen
    return ResponsiveScreen(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // seta de voltar visível e identificável via GlobalKey
        leading: IconButton(
          key: _backButtonKey,
          icon: const Icon(Icons.arrow_back),
          color: themeManager.getDetailHeaderTextColor(),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.budget.title,
          style: TextStyle(
            color: themeManager.getDetailHeaderTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeManager.getDetailHeaderColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBudget,
            color: themeManager.getDetailHeaderTextColor(),
          ),
          // ícone de ajuda (substitui o home) com GlobalKey
          IconButton(
            key: _helpButtonKey,
            icon: const Icon(Icons.help_outline),
            color: themeManager.getDetailHeaderTextColor(),
            onPressed: () => _showBudgetDetailHelp(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeManager.getDetailHeaderTextColor(),
          unselectedLabelColor:
              themeManager.getDetailHeaderTextColor().withAlpha(
                    (0.7 * 255).toInt(),
                  ), // Ajustado para usar withAlpha
          indicatorColor: themeManager.getDetailHeaderTextColor(),
          tabs: const [
            Tab(text: 'Locais', icon: Icon(MyFlutterApp.location)),
            Tab(text: 'Itens', icon: Icon(MyFlutterApp.cube_1)),
            Tab(text: 'Visão Geral', icon: Icon(MyFlutterApp.eye)),
          ],
        ),
      ),
      // Passa a cor de fundo original para o ResponsiveScreen
      backgroundColor: themeManager.getDetailCardColor(),
      // Passa o FloatingActionButton original para o ResponsiveScreen
      floatingActionButton: _isEditingCard
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddLocationDialog();
                } else {
                  _showAddItemDialog();
                }
              },
              backgroundColor: themeManager.getDetailHeaderColor(),
              child: Icon(
                Icons.add,
                color: themeManager.getDetailHeaderTextColor(),
              ),
            ),
      // Parâmetro obrigatório para ResponsiveScreen
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // O body original agora é o child do ResponsiveScreen
      child: Column(
        // Esta é a Column em budget_detail_screen.dart:140
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: BudgetSummaryCard(
              summary: widget.budget.summary,
              showDetails: false,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLocationsTab(),
                _buildItemsTab(),
                _buildOverviewTab(),
              ],
            ),
          ),
        ],
      ), // Mantém a posição original
    );
  }

  // Adicione este método na classe _BudgetDetailScreenState
  void _showBudgetDetailHelp(BuildContext context) {
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
                                themeManager.getDetailHeaderColor(),
                            child: Icon(
                              Icons.list_alt,
                              color: themeManager.getDetailHeaderTextColor(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Detalhes do Orçamento",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: appThemes.getCardTitleColor(),
                                  ),
                                ),
                                Text(
                                  "Como gerenciar seu orçamento",
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

                    // Seção 1: Abas
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 100),
                      child: _buildHelpSection(
                        context: context,
                        title: "1. Navegação por Abas",
                        icon: Icons.tab,
                        iconColor: themeManager.getDetailHeaderColor(),
                        content:
                            "Esta tela possui três abas para organizar as informações do seu orçamento:\n\n"
                            "• Locais: Gerencie os estabelecimentos para comparação de preços\n\n"
                            "• Itens: Visualize e edite a lista de produtos do orçamento\n\n"
                            "• Visão Geral: Acesse o comparativo completo do orçamento",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 2: Aba de Locais
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 200),
                      child: _buildHelpSection(
                        context: context,
                        title: "2. Gerenciamento de Locais",
                        icon: Icons.store,
                        iconColor: Colors.blue,
                        content: "Na aba Locais, você pode:\n\n"
                            "• Visualizar todos os estabelecimentos adicionados\n\n"
                            "• Adicionar novos estabelecimentos clicando no botão '+'\n\n"
                            "• Remover estabelecimentos usando o ícone de lixeira\n\n"
                            "Os estabelecimentos são usados para comparar preços dos itens.",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 3: Aba de Itens
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 300),
                      child: _buildHelpSection(
                        context: context,
                        title: "3. Gerenciamento de Itens",
                        icon: Icons.shopping_basket,
                        iconColor: Colors.orange,
                        content: "Na aba Itens, você pode:\n\n"
                            "• Ver todos os produtos do seu orçamento\n\n"
                            "• Pesquisar itens específicos com a barra de pesquisa\n\n"
                            "• Adicionar novos itens clicando no botão '+'\n\n"
                            "• Expandir cada card para adicionar preços em diferentes estabelecimentos\n\n"
                            "• Remover itens indesejados",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 4: Card de Item
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 400),
                      child: _buildHelpSection(
                        context: context,
                        title: "4. Cards de Item",
                        icon: Icons.credit_card,
                        iconColor: Colors.green,
                        content: "Cada card de item contém:\n\n"
                            "• Nome e categoria do produto\n\n"
                            "• Quantidade e unidade de medida\n\n"
                            "• Melhor preço encontrado (destacado em verde)\n\n"
                            "• Expandindo o card, você pode adicionar o preço deste item em diferentes estabelecimentos",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 5: Visão Geral
                    SlideAnimation.fromLeft(
                      delay: const Duration(milliseconds: 500),
                      child: _buildHelpSection(
                        context: context,
                        title: "5. Visão Geral e Comparativo",
                        icon: Icons.compare,
                        iconColor: Colors.purple,
                        content: "Na aba Visão Geral:\n\n"
                            "• Acesse o botão 'Ver Comparativo Completo' para analisar onde comprar cada item\n\n"
                            "• O comparativo mostra qual estabelecimento oferece o melhor preço para cada produto\n\n"
                            "• Compare o custo total do orçamento em cada estabelecimento",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seção 6: Card de Resumo
                    SlideAnimation.fromRight(
                      delay: const Duration(milliseconds: 600),
                      child: _buildHelpSection(
                        context: context,
                        title: "6. Resumo do Orçamento",
                        icon: Icons.summarize,
                        iconColor: themeManager.getDetailHeaderColor(),
                        content: "No topo da tela, o card de resumo mostra:\n\n"
                            "• Total de itens no orçamento\n\n"
                            "• Número de estabelecimentos para comparação\n\n"
                            "• Valor total estimado\n\n"
                            "• Economia potencial ao comprar cada item pelo melhor preço",
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
                              .getDetailHeaderColor()
                              .withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeManager
                                .getDetailHeaderColor()
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
                                  color: themeManager.getDetailHeaderColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dica útil",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeManager.getDetailHeaderColor(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Para uma economia máxima, adicione pelo menos 3 estabelecimentos diferentes e cadastre os preços de todos os itens em cada um deles.",
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
                                themeManager.getDetailHeaderColor(),
                            foregroundColor:
                                themeManager.getDetailHeaderTextColor(),
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

  // Método _buildLocationsTab com cards atualizados
  Widget _buildLocationsTab() {
    final themeManager = context.watch<ThemeManager>();
    final appThemes = AppThemes();

    if (currentBudget.locations.isEmpty) {
      return Center(
        child: Text(
          'Nenhum local adicionado',
          style: TextStyle(color: themeManager.getDetailCardTextColor()),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        80,
      ), // Padding para evitar sobreposição do FAB
      itemCount: currentBudget.locations.length,
      itemBuilder: (context, index) {
        final location = currentBudget.locations[index];
        return Card(
          elevation: appThemes.getCardElevation(),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(appThemes.getCardBorderRadius()),
            side: BorderSide(color: appThemes.getCardBorderColor(), width: 0.5),
          ),
          color: appThemes.getCardBackgroundColor(),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appThemes.getTableHeaderBackgroundColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.store,
                color: appThemes.getCardIconColor(),
                size: 24,
              ),
            ),
            title: Text(
              location.name,
              style: TextStyle(
                color: appThemes.getCardTitleColor(),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              location.address,
              style: TextStyle(
                color: appThemes.getListTileSubtitleColor(),
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              color: appThemes.getInputErrorColor(),
              onPressed: () => _confirmAndRemoveLocation(location),
            ),
          ),
        );
      },
    );
  }

  // Método _buildItemsTab original (sem alterações)
  Widget _buildItemsTab() {
    final themeManager = context.watch<ThemeManager>();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: themeManager.getDetailLoadingColor(),
        ),
      );
    }

    if (widget.budget.items.isEmpty) {
      return Center(
        child: Text(
          'Nenhum item adicionado',
          style: TextStyle(color: themeManager.getDetailEmptyStateTextColor()),
        ),
      );
    }

    Map<String, String> locationNames = {
      for (var loc in widget.budget.locations) loc.id: loc.name,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ItemSearchBar(onItemSelected: _moveItemToTop),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              8,
              0,
              8,
              80,
            ), // Padding para evitar sobreposição do FAB
            itemCount: widget.budget.items.length,
            itemBuilder: (context, index) {
              final item = widget.budget.items[index];
              return BudgetItemCard(
                key: ValueKey(item.id), // Usa ValueKey para melhor performance
                item: item,
                locationNames: locationNames,
                budgetId: widget.budget.id,
                budget: widget.budget, // Passa o budget completo
                budgetService: _budgetService,
                priceHistoryService: _historyService,
                onDelete: () => _removeItem(item.id),
                onEditingStateChange: _handleEditingState,
              );
            },
          ),
        ),
      ],
    );
  }

  // Método _buildOverviewTab original (sem alterações)
  Widget _buildOverviewTab() {
    final themeManager = context.watch<ThemeManager>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: Icon(MyFlutterApp.check),
            label: const Text('Ver Comparativo Completo'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  themeManager.getDetailCompareButtonBackgroundColor(),
              foregroundColor: themeManager.getDetailCompareButtonTextColor(),
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              '/budget/compare',
              arguments: widget.budget,
            ),
          ),
        ],
      ),
    );
  }

  // Método _moveItemToTop original (sem alterações)
  void _moveItemToTop(ItemTemplate template) {
    setState(() {
      // Encontra o primeiro item correspondente ou o primeiro da lista
      final itemIndex = widget.budget.items.indexWhere(
        (item) =>
            item.name == template.name && item.category == template.category,
      );

      if (itemIndex != -1 && itemIndex > 0) {
        final item = widget.budget.items.removeAt(itemIndex);
        widget.budget.items.insert(0, item);
      } else if (itemIndex == -1 && widget.budget.items.isNotEmpty) {
        // Se não encontrou e a lista não está vazia, move o primeiro (comportamento original)
        // Embora isso possa não ser o ideal, mantém a lógica original.
        final item = widget.budget.items.removeAt(0);
        widget.budget.items.insert(0, item);
      }
    });
  }

  // Método _showAddLocationDialog com diálogo atualizado
  Future<void> _showAddLocationDialog() async {
    final appThemes = AppThemes();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemes.getDialogBackgroundColor(),
        title: Text(
          'Adicionar Local',
          style: appThemes.getDialogTitleStyle(),
        ),
        content: SizedBox(
          // Mantém SizedBox para limitar altura interna
          height: 200.0,
          width: double.maxFinite,
          child: SingleChildScrollView(
            // Mantém SingleChildScrollView interno
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: appThemes.getStandardInputDecoration(
                    'Nome do Local',
                    hint: 'Ex: Mercado Central',
                  ),
                  style: TextStyle(
                    color: appThemes.getInputTextColor(),
                  ),
                  cursorColor: appThemes.getInputCursorColor(),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: appThemes.getStandardInputDecoration(
                    'Endereço',
                    hint: 'Ex: Rua Principal, 123',
                  ),
                  style: TextStyle(
                    color: appThemes.getInputTextColor(),
                  ),
                  cursorColor: appThemes.getInputCursorColor(),
                ),
              ],
            ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final location = BudgetLocation(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  priceDate: DateTime.now(),
                  budgetId: widget.budget.id,
                );
                _addLocation(location);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: appThemes.getDialogButtonColor(),
              foregroundColor: appThemes.getDialogButtonTextColor(),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  // Método _showAddItemDialog com diálogo atualizado
  Future<void> _showAddItemDialog() async {
    final appThemes = AppThemes();
    return showDialog(
      context: context,
      // Usa Dialog em vez de AlertDialog para mais controle sobre o tamanho
      builder: (context) => Dialog(
        backgroundColor: appThemes.getDialogBackgroundColor(),
        // Define o preenchimento e o tamanho do Dialog
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            // Define largura e altura relativas à tela
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: AddItemForm(
              budgetId: widget.budget.id,
              onItemsAdded: (items) async {
                // Adiciona os itens um por um
                for (final item in items) {
                  await _addItem(item);
                }
                // Fecha o diálogo após adicionar todos os itens
                if (mounted) Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Método _addLocation original (sem alterações)
  Future<void> _addLocation(BudgetLocation location) async {
    setState(() => _isLoading = true);
    try {
      await _budgetService.addLocation(widget.budget.id, location);
      await _refreshBudget();
      if (mounted) {
        _showSuccess('Local adicionado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao adicionar local: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Método _addItem original (sem alterações)
  Future<void> _addItem(BudgetItem item) async {
    setState(() => _isLoading = true);
    try {
      await _budgetService.addItem(widget.budget.id, item);
      await _refreshBudget();
      if (mounted) {
        _showSuccess('Item adicionado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao adicionar item: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Método _removeItem original (sem alterações)
  Future<void> _removeItem(String itemId) async {
    final confirmed = await _showConfirmDialog(
      'Remover Item',
      'Deseja realmente remover este item?',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _budgetService.removeItem(widget.budget.id, itemId);
        await _refreshBudget();
        if (mounted) {
          _showSuccess('Item removido com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao remover item: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Método _confirmAndRemoveLocation original (sem alterações)
  Future<void> _confirmAndRemoveLocation(BudgetLocation location) async {
    final confirmed = await _showConfirmDialog(
      'Remover Local',
      'Deseja realmente remover este local?\nTodos os preços associados serão perdidos.',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _budgetService.removeLocation(widget.budget.id, location.id);
        await _refreshBudget();
        if (mounted) {
          _showSuccess('Local removido com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao remover local: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Método _handleEditingState original (sem alterações)
  void _handleEditingState(bool isEditing) {
    // Garante que a atualização do estado ocorra apenas se o widget estiver montado
    if (mounted) {
      setState(() => _isEditingCard = isEditing);
    }
  }

  // Método _showConfirmDialog com diálogo atualizado
  Future<bool?> _showConfirmDialog(String title, String message) async {
    final appThemes = AppThemes();
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemes.getDialogBackgroundColor(),
        title: Text(
          title,
          style: appThemes.getDialogTitleStyle(),
        ),
        content: Text(
          message,
          style: TextStyle(color: appThemes.getDialogTextColor()),
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
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  // Método _showSuccess com correção da cor do texto (mantido)
  void _showSuccess(String message) {
    // Garante que o ScaffoldMessenger seja acessado apenas se o widget estiver montado
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // --- COR DO TEXTO: Definida como branca ---
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // Texto branco
        ),
        backgroundColor:
            context.read<ThemeManager>().getDetailSuccessBackgroundColor(),
      ),
    );
  }

  // Método _showError original (sem alterações)
  void _showError(String message) {
    // Garante que o ScaffoldMessenger seja acessado apenas se o widget estiver montado
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.read<ThemeManager>().getDetailErrorColor(),
      ),
    );
  }
}
