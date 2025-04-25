import 'package:economize/data/costs_dao.dart';
import 'package:economize/model/costs.dart';

class CostsService {
  final CostsDAO _costsDAO = CostsDAO();

  Future<List<Costs>> getAllCosts() async {
    return await _costsDAO.findAll();
  }

  Future<void> saveCost(Costs cost) async {
    await _costsDAO.insert(cost);
  }

  Future<void> deleteCost(String id) async {
    await _costsDAO.delete(id);
  }
}
