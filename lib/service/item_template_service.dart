import 'package:economize/data/item_template_dao.dart';
import 'package:economize/model/budget/item_template.dart';

extension StringNormalization on String {
  String normalize() {
    return toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .trim();
  }
}

class ItemTemplateService {
  final ItemTemplateDAO _itemTemplateDAO = ItemTemplateDAO();

  List<ItemTemplate>? _cachedTemplates;
  Map<String, List<String>>? _cachedCategories;

  Future<List<ItemTemplate>> getAllTemplates() async {
    _cachedTemplates ??= await _itemTemplateDAO.findAll();
    return _cachedTemplates!;
  }

  Future<List<String>> getCategories() async {
    if (_cachedCategories == null) {
      final categories = await _itemTemplateDAO.getAllCategories();
      _cachedCategories = {};
      for (var category in categories) {
        _cachedCategories![category] = await _itemTemplateDAO
            .getSubcategoriesByCategory(category);
      }
    }
    return _cachedCategories!.keys.toList()..sort();
  }

  Future<List<ItemTemplate>> searchTemplates(
    String query, {
    String? category,
  }) async {
    final normalizedQuery = query.normalize();

    if (normalizedQuery.isEmpty && category == null) {
      return getAllTemplates();
    }

    if (normalizedQuery.isEmpty && category != null) {
      return _itemTemplateDAO.findByCategory(category);
    }

    // Busca por nome normalizado
    var results = await _itemTemplateDAO.searchByName(normalizedQuery);

    // Filtra resultados considerando normalização
    results =
        results.where((item) {
          final normalizedName = item.name.normalize();
          item.category.normalize();

          bool matchesName = normalizedName.contains(normalizedQuery);
          bool matchesCategory = category == null || item.category == category;

          return matchesName && matchesCategory;
        }).toList();

    // Ordena por relevância com normalização
    results.sort((a, b) {
      final aNormalized = a.name.normalize();
      final bNormalized = b.name.normalize();

      if (aNormalized == normalizedQuery) return -1;
      if (bNormalized == normalizedQuery) return 1;
      if (aNormalized.startsWith(normalizedQuery)) return -1;
      if (bNormalized.startsWith(normalizedQuery)) return 1;

      return aNormalized.compareTo(bNormalized);
    });

    return results;
  }

  Future<List<ItemTemplate>> getTemplatesByCategory(String category) async {
    return _itemTemplateDAO.findByCategory(category);
  }

  Future<List<String>> getSubcategories(String category) async {
    if (_cachedCategories != null && _cachedCategories!.containsKey(category)) {
      return _cachedCategories![category]!;
    }
    return _itemTemplateDAO.getSubcategoriesByCategory(category);
  }

  Future<ItemTemplate?> getTemplateByName(String name) async {
    final normalizedName = name.normalize();
    final templates = await _itemTemplateDAO.searchByName(normalizedName);
    return templates.isEmpty ? null : templates.first;
  }

  void clearCache() {
    _cachedTemplates = null;
    _cachedCategories = null;
  }

  Future<void> updateTemplate(ItemTemplate template) async {
    await _itemTemplateDAO.update(template);
    clearCache();
  }

  Future<void> addTemplate(ItemTemplate template) async {
    await _itemTemplateDAO.insert(template);
    clearCache();
  }

  Future<void> removeTemplate(int id) async {
    await _itemTemplateDAO.delete(id);
    clearCache();
  }
}
