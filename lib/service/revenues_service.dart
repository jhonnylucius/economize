import 'package:economize/data/revenues_dao.dart';
import 'package:economize/model/revenues.dart';

class RevenuesService {
  final RevenuesDAO _revenuesDAO = RevenuesDAO();

  Future<List<Revenues>> getAllRevenues() async {
    return await _revenuesDAO.findAll();
  }

  Future<void> saveRevenue(Revenues revenue) async {
    await _revenuesDAO.insert(revenue);
  }

  Future<void> deleteRevenue(String id) async {
    await _revenuesDAO.delete(id);
  }
}
