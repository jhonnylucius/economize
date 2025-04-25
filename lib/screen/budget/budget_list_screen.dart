import 'package:economize/data/default_items.dart';
import 'package:economize/icons/my_flutter_app_icons.dart';
import 'package:economize/model/budget/budget.dart';
import 'package:economize/service/budget_service.dart';
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
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            color: themeManager.getBudgetListHeaderTextColor(),
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
          color: themeManager
              .getBudgetListCardTextColor(), // Ajustado para usar cor do texto do card
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
        );
      },
    );
  }

  void _navigateToBudgetDetail(Budget budget) {
    Navigator.pushNamed(context, '/budget/detail', arguments: budget);
  }

  Future<void> _showCreateBudgetDialog(BuildContext context) async {
    final themeManager = context.read<ThemeManager>();
    final titleController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeManager.getBudgetListCardBackgroundColor(),
        title: Text(
          'Novo Orçamento',
          style: TextStyle(
            color: themeManager.getBudgetListCardTextColor(),
          ),
        ),
        // --- OVERFLOW FIX: Adicionado SingleChildScrollView ---
        content: SingleChildScrollView(
          child: TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Título do Orçamento',
              hintText: 'Ex: Compras do Mês',
              labelStyle: TextStyle(
                color: themeManager.getBudgetListCardTextColor(),
              ),
              hintStyle: TextStyle(
                color: themeManager.getBudgetListCardTextColor().withAlpha(
                      (0.7 * 255).toInt(),
                    ),
              ),
            ),
            style: TextStyle(
              color: themeManager.getBudgetListCardTextColor(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: themeManager.getBudgetListHeaderColor(),
              ),
            ),
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
              backgroundColor: themeManager.getBudgetListHeaderColor(),
              foregroundColor: themeManager.getBudgetListHeaderTextColor(),
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    final themeManager = context.read<ThemeManager>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeManager.getBudgetListCardBackgroundColor(),
        title: Text(
          'Excluir Orçamento',
          style: TextStyle(
            color: themeManager.getBudgetListCardTextColor(),
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir este orçamento? Esta ação não pode ser desfeita.',
          style: TextStyle(
            color: themeManager.getBudgetListCardTextColor(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: themeManager.getBudgetListHeaderColor(),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: themeManager.getBudgetListHeaderTextColor()),
        ),
        backgroundColor: themeManager.getBudgetListHeaderColor(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  const _BudgetCard({
    required this.budget,
    required this.onTap,
    required this.onDelete,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return Card(
      color: Colors.white, // Card branco fixo
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        color: themeManager.getBudgetListCardTitleColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(MyFlutterApp.trash_alt),
                    onPressed: onDelete,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Criado em: ${DateFormat('dd/MM/yyyy').format(budget.date)}',
                style: TextStyle(
                  color: themeManager.getBudgetListCardTextColor().withAlpha(
                        (0.7 * 255).toInt(),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoColumn(
                    label: 'Total Original',
                    value: currencyFormat.format(budget.summary.totalOriginal),
                    labelColor: themeManager.getBudgetListCardTextColor(),
                    valueColor: themeManager.getBudgetListCardTextColor(),
                  ),
                  _InfoColumn(
                    label: 'Melhor Preço',
                    value: currencyFormat.format(budget.summary.totalOptimized),
                    labelColor: themeManager.getBudgetListCardTextColor(),
                    valueColor: themeManager.getBudgetListCardTextColor(),
                  ),
                  _InfoColumn(
                    label: 'Economia',
                    value: currencyFormat.format(budget.summary.savings),
                    labelColor: themeManager.getBudgetListCardTextColor(),
                    valueColor: themeManager.getBudgetListCardTextColor(),
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
  final Color labelColor;
  final Color valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor.withAlpha((0.7 * 255).toInt()),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
