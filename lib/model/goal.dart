import 'package:economize/data/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Goal {
  String? id; // Alterado para poder ser nulo em casos específicos
  String name;
  double targetValue;
  double currentValue;
  DateTime? createdAt; // Alterado para poder ser nulo

  double get percentComplete =>
      targetValue > 0 ? (currentValue / targetValue) : 0.0;

  IconData get rarityIcon {
    final percent = percentComplete;
    if (percent >= 1.0) return Icons.emoji_events;
    if (percent >= 0.8) return Icons.stars;
    if (percent >= 0.5) return Icons.military_tech;
    return Icons.emoji_events;
  }

  Color get rarityColor {
    final percent = percentComplete;
    if (percent >= 1.0) return Colors.amber;
    if (percent >= 0.8) return Colors.orange;
    if (percent >= 0.5) return Colors.blue;
    return Colors.grey;
  }

  Goal({
    this.id,
    required this.name,
    required this.targetValue,
    this.currentValue = 0,
    this.createdAt,
  }) {
    // Inicializa valores default
    id = id ?? const Uuid().v4(); // Gera um ID se não for fornecido
    createdAt =
        createdAt ?? DateTime.now(); // Define a data atual se não fornecida
  }

  // Getter para o valor restante (não permite valores negativos)
  double get remainingValue =>
      (targetValue - currentValue).clamp(0.0, double.infinity);

  // Getter para verificar se a meta foi alcançada
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

  Goal copyWith({
    String? id,
    String? name,
    double? targetValue,
    double? currentValue,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, targetValue: $targetValue, currentValue: $currentValue, progress: ${(percentComplete * 100).toStringAsFixed(1)}%)';
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

    // Garante que o ID esteja definido
    final goalToSave =
        goal.id == null ? goal.copyWith(id: const Uuid().v4()) : goal;

    await db.insert(
      tableName,
      goalToSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // IMPLEMENTAÇÃO DO MÉTODO UPDATE
  Future<void> update(Goal goal) async {
    final db = await DatabaseHelper.instance.database;

    // Garante que o ID está presente
    if (goal.id == null) {
      throw Exception('Cannot update goal without an ID');
    }

    await db.update(
      tableName,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // IMPLEMENTAÇÃO DO MÉTODO DELETE
  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
