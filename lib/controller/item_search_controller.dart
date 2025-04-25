import 'package:economize/data/item_template_dao.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:flutter/material.dart';

class ItemSearchController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final ItemTemplateDAO _itemTemplateDAO = ItemTemplateDAO();

  List<ItemTemplate> filteredItems = [];
  ItemTemplate? selectedItem;

  // Status do carregamento
  bool isLoading = false;
  String? error;

  ItemSearchController() {
    searchController.addListener(_filterItems);
    _loadInitialItems();
  }

  Future<void> _loadInitialItems() async {
    try {
      isLoading = true;
      notifyListeners();

      isLoading = false;
      error = null;
    } catch (e) {
      error = 'Erro ao carregar itens: $e';
      isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _filterItems() async {
    if (searchController.text.isEmpty) {
      filteredItems = [];
    } else {
      try {
        // Primeiro tenta buscar por nome exato
        filteredItems = await _itemTemplateDAO.searchByName(
          searchController.text,
        );

        // Se não encontrar, busca por categoria
        if (filteredItems.isEmpty) {
          filteredItems = await _itemTemplateDAO.findByCategory(
            searchController.text,
          );
        }
      } catch (e) {
        error = 'Erro na busca: $e';
      }
    }
    notifyListeners();
  }

  void selectItem(ItemTemplate item) {
    selectedItem = item;
    searchController.text = item.name;
    notifyListeners();
  }

  Future<List<String>> getCategories() async {
    try {
      return await _itemTemplateDAO.getAllCategories();
    } catch (e) {
      error = 'Erro ao carregar categorias: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<String>> getSubcategories(String category) async {
    try {
      return await _itemTemplateDAO.getSubcategoriesByCategory(category);
    } catch (e) {
      error = 'Erro ao carregar subcategorias: $e';
      notifyListeners();
      return [];
    }
  }

  void clear() {
    searchController.clear();
    selectedItem = null;
    filteredItems.clear();
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
