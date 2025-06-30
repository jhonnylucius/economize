import 'dart:async';

import 'package:economize/model/budget/budget_item.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:economize/service/item_template_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:economize/widgets/budget/unit_selector.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddItemForm extends StatefulWidget {
  final Function(List<BudgetItem>) onItemsAdded;
  final String budgetId;

  const AddItemForm({
    super.key,
    required this.onItemsAdded,
    required this.budgetId,
  });

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final TextEditingController _searchController = TextEditingController();
  final ItemTemplateService _itemService = ItemTemplateService();
  final _debouncer = Debouncer(milliseconds: 300); // Mover para cá

  String _selectedCategory = '';
  final List<ItemTemplate> _selectedItems = [];
  List<ItemTemplate> _filteredItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Todas'; // Começa com categoria vazia (Todas)
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _itemService.getCategories();
      if (categories.isNotEmpty) {
        _selectedCategory = 'Todas';
        await _updateFilteredItems();
      }
    } catch (e) {
      setState(() => _error = 'Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Modifique o método _updateFilteredItems para não afetar o teclado:
  Future<void> _updateFilteredItems() async {
    _debouncer.run(() async {
      if (!mounted) return;

      try {
        final List<ItemTemplate> results;
        if (_searchController.text.isEmpty) {
          results = _selectedCategory.isEmpty || _selectedCategory == 'Todas'
              ? await _itemService.getAllTemplates()
              : await _itemService.getTemplatesByCategory(
                  _selectedCategory,
                );
        } else {
          results = await _itemService.searchTemplates(
            _searchController.text,
            category: _selectedCategory.isEmpty || _selectedCategory == 'Todas'
                ? null
                : _selectedCategory,
          );
        }

        if (mounted) {
          setState(() {
            _filteredItems = results;
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'Erro na busca: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appThemes = AppThemes();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: appThemes.getCardIconColor(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: appThemes.getInputErrorColor()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemes.getDialogButtonColor(),
                foregroundColor: appThemes.getDialogButtonTextColor(),
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<List<String>>(
          future: _itemService.getCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator(
                color: appThemes.getCardIconColor(),
              );
            }

            // Adiciona "Todas" como primeira opção
            final List<String> categories = ['Todas', ...snapshot.data!];

            return DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? 'Todas' : _selectedCategory,
              decoration: appThemes.getStandardInputDecoration('Categoria'),
              dropdownColor: appThemes.getDialogBackgroundColor(),
              style: TextStyle(color: appThemes.getInputTextColor()),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(
                    () => _selectedCategory = value == 'Todas' ? '' : value,
                  );
                  await _updateFilteredItems();
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: appThemes.getStandardInputDecoration(
            'Pesquisar itens...',
            prefixIcon:
                Icon(Icons.search, color: appThemes.getInputIconColor()),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.clear, color: appThemes.getInputIconColor()),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilteredItems();
                    },
                  )
                : null,
          ),
          style: TextStyle(color: appThemes.getInputTextColor()),
          cursorColor: appThemes.getInputCursorColor(),
          onChanged: (value) {
            // Não chama setState aqui para evitar rebuild desnecessário
            _updateFilteredItems();
          },
          // Remove onSubmitted para evitar fechamento do teclado
          autofocus: false, // Evita foco automático
          enableInteractiveSelection: true, // Permite seleção de texto
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'Nenhum item encontrado',
                    style: TextStyle(color: appThemes.getCardTextColor()),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _selectedItems.contains(item);

                    return Card(
                      color: appThemes.getCardBackgroundColor(),
                      elevation: appThemes.getCardElevation(),
                      margin: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            appThemes.getCardBorderRadius()),
                        side: BorderSide(
                            color: appThemes.getCardBorderColor(), width: 0.5),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          item.name,
                          style:
                              TextStyle(color: appThemes.getCardTitleColor()),
                        ),
                        subtitle: Text(
                          '${item.category} • ${item.defaultUnit}',
                          style: TextStyle(
                            color: appThemes.getListTileSubtitleColor(),
                          ),
                        ),
                        secondary: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: appThemes.getCardIconColor(),
                              )
                            : null,
                        checkColor: appThemes.getCheckboxCheckColor(),
                        activeColor: appThemes.getCheckboxActiveColor(),
                        side: BorderSide(
                          color: appThemes.getCheckboxBorderColor(),
                          width: 1.5,
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked!) {
                              _selectedItems.add(item);
                            } else {
                              _selectedItems.remove(item);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                'Selecionados: ${_selectedItems.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: appThemes.getCardTextColor(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _selectedItems.isEmpty ? null : _addItems,
                style: FilledButton.styleFrom(
                  backgroundColor: appThemes.getDialogButtonColor(),
                  foregroundColor: appThemes.getDialogButtonTextColor(),
                  disabledBackgroundColor: appThemes
                      .getDialogButtonColor()
                      .withAlpha((0.5 * 255).round()),
                  disabledForegroundColor: appThemes
                      .getDialogButtonTextColor()
                      .withAlpha((0.5 * 255).round()),
                ),
                child: const Text('Adicionar Selecionados'),
              ),
              const SizedBox(height: 8), // Espaçamento entre os botões
              FilledButton(
                onPressed: () {
                  // Navegar para a tela de gerenciamento de itens
                  Navigator.pushNamed(context, '/items/manage').then((_) {
                    // Ao retornar, atualiza a lista de itens
                    _updateFilteredItems();
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: appThemes.getCardButtonColor(),
                  foregroundColor: appThemes.getCardButtonTextColor(),
                ),
                child: const Text('Adicionar novo item'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addItems() {
    final items = _selectedItems
        .map(
          (template) => BudgetItem(
            id: const Uuid().v4(),
            budgetId: widget.budgetId,
            name: template.name,
            category: template.category,
            unit: template.defaultUnit,
            quantity: 1,
            prices: {},
            bestPriceLocation: '',
            bestPrice: 0,
          ),
        )
        .toList();

    widget.onItemsAdded(items);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }
}
