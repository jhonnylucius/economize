import 'package:economize/data/database_helper.dart';
import 'package:economize/model/budget/item_template.dart';
import 'package:sqflite/sqflite.dart';

class ItemTemplateDAO {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static const String tableName = 'default_items';

  // Corrigir todos os métodos para usar a constante tableName
  Future<List<ItemTemplate>> findAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((map) => ItemTemplate.fromMap(map)).toList();
  }

  Future<List<ItemTemplate>> findByCategory(String category) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((map) => ItemTemplate.fromMap(map)).toList();
  }

  Future<ItemTemplate?> findById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ItemTemplate.fromMap(maps.first);
  }

  Future<List<String>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      distinct: true,
      columns: ['category'],
      where: 'category IS NOT NULL',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<List<String>> getSubcategoriesByCategory(String category) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      distinct: true,
      columns: ['subcategory'],
      where: 'category = ? AND subcategory IS NOT NULL',
      whereArgs: [category],
    );
    return maps.map((map) => map['subcategory'] as String).toList();
  }

  Future<List<ItemTemplate>> searchByName(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '''
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(
                            REPLACE(
                              REPLACE(LOWER(name),
                              'á', 'a'),
                            'à', 'a'),
                          'ã', 'a'),
                        'â', 'a'),
                      'é', 'e'),
                    'ê', 'e'),
                  'í', 'i'),
                'ó', 'o'),
              'õ', 'o'),
            'ô', 'o'),
          'ú', 'u'),
        'ç', 'c')
        LIKE ?
      ''',
      whereArgs: ['%${query.toLowerCase()}%'],
    );
    return maps.map((map) => ItemTemplate.fromMap(map)).toList();
  }

  Future<int> insert(ItemTemplate item) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(ItemTemplate item) async {
    final db = await _databaseHelper.database;
    await db.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
