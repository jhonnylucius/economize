import 'package:flutter/foundation.dart';

class BudgetStateController extends ChangeNotifier {
  static final BudgetStateController _instance =
      BudgetStateController._internal();

  factory BudgetStateController() {
    return _instance;
  }

  BudgetStateController._internal();

  void notifyBudgetUpdated() {
    notifyListeners();
  }
}
