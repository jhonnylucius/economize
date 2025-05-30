import 'package:economize/model/budget/item_template.dart';
import 'package:economize/service/item_template_service.dart';
import 'package:economize/theme/app_themes.dart';
import 'package:flutter/material.dart';

class ItemSelector extends StatefulWidget {
  final Function(List<ItemTemplate>) onItemsSelected;
  final String? initialCategory;

  const ItemSelector({
    super.key,
    required this.onItemsSelected,
    this.initialCategory,
  });

  @override
  State<ItemSelector> createState() => _ItemSelectorState();
}

class _ItemSelectorState extends State<ItemSelector> {
  final ItemTemplateService _itemService = ItemTemplateService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = '';
  final List<ItemTemplate> _selectedItems = [];
  List<ItemTemplate> _filteredItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _itemService.getCategories();
      if (categories.isNotEmpty) {
        _selectedCategory = widget.initialCategory ?? categories.first;
        await _updateFilteredItems();
      }
    } catch (e) {
      setState(() => _error = 'Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSearch() async {
    await _updateFilteredItems();
  }

  Future<void> _updateFilteredItems() async {
    setState(() => _isLoading = true);
    try {
      if (_searchController.text.isEmpty) {
        _filteredItems = await _itemService.getTemplatesByCategory(
          _selectedCategory,
        );
      } else {
        _filteredItems = await _itemService.searchTemplates(
          _searchController.text,
          category: _selectedCategory,
        );
      }
      _error = null;
    } catch (e) {
      setState(() => _error = 'Erro na busca: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appThemes = AppThemes();

    if (_isLoading && _filteredItems.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: appThemes.getCardBackgroundColor(),
      child: Column(
        children: [
          _buildCategoryDropdown(),
          const SizedBox(height: 8),
          _buildSearchField(),
          const SizedBox(height: 8),
          Expanded(child: _buildItemsList()),
          _buildSelectionSummary(),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final theme = Theme.of(context);
    final appThemes = AppThemes();

    return FutureBuilder<List<String>>(
      future: _itemService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LinearProgressIndicator(color: theme.colorScheme.primary);
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: appThemes.getStandardInputDecoration(
            'Categoria',
          ),
          dropdownColor: appThemes.getDialogBackgroundColor(),
          style: TextStyle(color: appThemes.getInputTextColor()),
          items: snapshot.data!.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              setState(() => _selectedCategory = value);
              await _updateFilteredItems();
            }
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    final appThemes = AppThemes();

    return SearchBar(
      controller: _searchController,
      hintText: 'Pesquisar itens...',
      backgroundColor:
          WidgetStateProperty.all(appThemes.getInputBackgroundColor()),
      hintStyle: WidgetStateProperty.all(
        TextStyle(color: appThemes.getHintTextColor()),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(color: appThemes.getInputTextColor()),
      ),
      leading: Icon(Icons.search, color: appThemes.getInputIconColor()),
      trailing: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear, color: appThemes.getInputIconColor()),
            onPressed: () {
              _searchController.clear();
              _updateFilteredItems();
            },
          ),
      ],
    );
  }

  Widget _buildItemsList() {
    final appThemes = AppThemes();

    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'Nenhum item encontrado',
          style: TextStyle(color: appThemes.getCardTextColor()),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = _selectedItems.contains(item);

        return Card(
          color: appThemes.getCardBackgroundColor(),
          elevation: appThemes.getCardElevation(),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(appThemes.getCardBorderRadius()),
            side: BorderSide(color: appThemes.getCardBorderColor(), width: 0.5),
          ),
          child: CheckboxListTile(
            value: isSelected,
            title: Text(
              item.name,
              style: TextStyle(color: appThemes.getCardTitleColor()),
            ),
            subtitle: Text(
              '${item.category} • ${item.defaultUnit}',
              style: TextStyle(
                color: appThemes.getListTileSubtitleColor(),
              ),
            ),
            secondary: isSelected
                ? Icon(Icons.check_circle, color: appThemes.getCardIconColor())
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
                widget.onItemsSelected(_selectedItems);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectionSummary() {
    final appThemes = AppThemes();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Selecionados: ${_selectedItems.length}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: appThemes.getCardTextColor(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
