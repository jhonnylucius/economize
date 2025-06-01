import 'package:economize/data/database_helper.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class Goal {
  String? id; // Permite ser nulo temporariamente
  String name;
  double targetValue;
  double currentValue;
  DateTime? createdAt;

  Goal({
    this.id,
    required this.name,
    required this.targetValue,
    this.currentValue = 0,
    this.createdAt,
  }) {
    // Garante que a meta sempre tem um ID
    id = id ?? const Uuid().v4();
    // Garante que a meta sempre tem uma data de criação
    createdAt = createdAt ?? DateTime.now();
  }

  // Getter para calcular o percentual completo
  double get percentComplete =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  // Getter para valor restante a ser alcançado
  double get remainingValue =>
      targetValue > currentValue ? targetValue - currentValue : 0.0;

  // Getter para verificar se a meta foi concluída
  bool get isCompleted => currentValue >= targetValue;

  // Converte o objeto para um mapa para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_value': targetValue,
      'current_value': currentValue,
      'created_at': createdAt!.toIso8601String(),
    };
  }

  // Cria um objeto Goal a partir de um mapa do banco de dados
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      targetValue: map['target_value'],
      currentValue: map['current_value'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Cria uma cópia do objeto com valores específicos alterados
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

  // Cria a tabela no banco de dados
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

  // Busca todas as metas do banco de dados
  Future<List<Goal>> findAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName);

    // Log para depuração
    Logger().e('Encontradas ${maps.length} metas no banco');

    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  // Busca uma meta específica pelo ID
  Future<Goal?> findById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      Logger().e('Nenhuma meta encontrada com ID: $id');
      return null;
    }

    return Goal.fromMap(maps.first);
  }

  // Salva uma nova meta no banco de dados ou substitui uma existente
  Future<void> save(Goal goal) async {
    final db = await DatabaseHelper.instance.database;

    // Garante que a meta tem um ID válido
    if (goal.id == null || goal.id!.isEmpty) {
      final newId = const Uuid().v4();
      Logger().e('ID da meta estava nulo ou vazio. Gerando novo ID: $newId');
      goal = goal.copyWith(id: newId);
    }

    try {
      await db.insert(
        tableName,
        goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Logger().e('Meta salva com sucesso: ${goal.name} (ID: ${goal.id})');
    } catch (e) {
      Logger().e('Erro ao salvar meta: $e');
      rethrow;
    }
  }

  // Atualiza uma meta existente no banco de dados
  Future<void> update(Goal goal) async {
    final db = await DatabaseHelper.instance.database;

    // Verifica se o ID é válido
    if (goal.id == null || goal.id!.isEmpty) {
      Logger().e('Tentativa de atualizar meta sem ID válido');
      throw Exception('Não é possível atualizar uma meta sem um ID válido');
    }

    // Verifica se a meta existe antes de atualizar
    final existingGoal = await findById(goal.id!);
    if (existingGoal == null) {
      Logger().e('Tentativa de atualizar meta inexistente: ${goal.id}');
      throw Exception('Meta com ID ${goal.id} não encontrada para atualização');
    }

    try {
      final rowsUpdated = await db.update(
        tableName,
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );

      Logger().e(
          'Meta atualizada: ${goal.name} (ID: ${goal.id}) - Linhas afetadas: $rowsUpdated');
    } catch (e) {
      Logger().e('Erro ao atualizar meta: $e');
      rethrow;
    }
  }

  // Exclui uma meta do banco de dados
  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;

    if (id.isEmpty) {
      Logger().e('Tentativa de excluir meta com ID vazio');
      throw Exception('ID não pode ser vazio para exclusão');
    }

    try {
      final rowsDeleted = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      Logger().e('Meta excluída (ID: $id) - Linhas afetadas: $rowsDeleted');

      if (rowsDeleted == 0) {
        Logger().e('Nenhuma meta encontrada com ID: $id para exclusão');
      }
    } catch (e) {
      Logger().e('Erro ao excluir meta: $e');
      rethrow;
    }
  }

  // Método adicional para depuração - lista todas as metas na console
  Future<void> printAllGoals() async {
    final goals = await findAll();
    Logger().e('==== TODAS AS METAS ====');
    for (var goal in goals) {
      Logger().e(goal);
    }
    Logger().e('=======================');
  }
}
