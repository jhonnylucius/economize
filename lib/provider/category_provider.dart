import 'package:flutter/foundation.dart';
import 'package:economize/model/category.dart' as app;

class CategoryProvider with ChangeNotifier {
  List<app.Category> _categories = [];

  List<app.Category> get categories => [..._categories];

  void toggleCategory(String id) {
    final category = _categories.firstWhere((cat) => cat.id == id);
    category.isEnabled = !category.isEnabled;
    notifyListeners();
  }

  void addCategory(app.Category category) {
    _categories.add(category);
    notifyListeners();
  }

  void removeCategory(String id) {
    _categories.removeWhere((cat) => cat.id == id && !cat.isDefault);
    notifyListeners();
  }
}
