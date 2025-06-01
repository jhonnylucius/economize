import 'package:economize/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Goal {
  String? id; // Alterado para poder ser nulo em casos específicos
  String name;
  double targetValue;
  double currentValue;
  DateTime? createdAt; // Alterado para poder ser nulo

  Goal({
    this.id,
    required this.name,
    required this.targetValue,
    this.currentValue = 0,
    this.createdAt,
  }) {
    createdAt = createdAt ?? DateTime.now();
  }

  double get percentComplete => currentValue / targetValue;
  double get remainingValue => targetValue - currentValue;
  bool get isCompleted => currentValue >= targetValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_value': targetValue,
      'current_value': currentValue,
      'created_at': createdAt!.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      targetValue: map['target_value'],
      currentValue: map['current_value'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class GoalsDAO {
  static const tableName = 'goals';

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_value REAL NOT NULL,
        current_value REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<Goal>> findAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName);
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  // Novo método findById para buscar uma meta específica pelo ID
  Future<Goal?> findById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Goal.fromMap(maps.first);
  }

  Future<void> save(Goal goal) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      tableName,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Goal goal) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      tableName,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
