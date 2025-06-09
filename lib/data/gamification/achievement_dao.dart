import 'package:economize/data/database_helper.dart';
import 'package:economize/model/gamification/achievement.dart';
import 'package:sqflite/sqflite.dart';

class AchievementDao {
  static const String tableName = 'achievements';

  // Criar tabela de conquistas
  static const String createTable = '''
  CREATE TABLE $tableName(
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    secret_description TEXT NOT NULL,
    type TEXT NOT NULL,
    rarity TEXT NOT NULL,
    image_path TEXT,                    
    unlocked_at TEXT,
    is_unlocked INTEGER DEFAULT 0,
    progress REAL DEFAULT 0.0,
    metadata TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''';

  // CORRIGIR: Usar instância em vez de estático
  static Future<void> insert(Achievement achievement) async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    await db.insert(
      tableName,
      achievement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Achievement>> findAll() async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'rarity ASC, unlocked_at DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  static Future<List<Achievement>> findUnlocked() async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_unlocked = ?',
      whereArgs: [1],
      orderBy: 'unlocked_at DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  static Future<List<Achievement>> findByRarity(
      AchievementRarity rarity) async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'rarity = ?',
      whereArgs: [rarity.toString()],
      orderBy: 'is_unlocked DESC, progress DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  static Future<Achievement?> findById(String id) async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Achievement.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateProgress(String id, double progress) async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    await db.update(
      tableName,
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> unlock(String id) async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    await db.update(
      tableName,
      {
        'is_unlocked': 1,
        'unlocked_at': DateTime.now().toIso8601String(),
        'progress': 1.0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> exists(String id) async {
    final achievement = await findById(id);
    return achievement != null;
  }

  static Future<int> countTotal() async {
    final db = await DatabaseHelper.instance.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }

  static Future<int> countUnlocked() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE is_unlocked = ?', [1]);
    return result.first['count'] as int;
  }

  static Future<List<Achievement>> findWithProgress() async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'progress > ? AND is_unlocked = ?',
      whereArgs: [0.0, 0],
      orderBy: 'progress DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  static Future<void> deleteAll() async {
    final db = await DatabaseHelper.instance.database; // ✅ INSTÂNCIA
    await db.delete(tableName);
  }

  // 🔄 RESETAR TODAS AS CONQUISTAS (Para desenvolvimento/teste)
  static Future<void> resetAll() async {
    final db = await DatabaseHelper.instance.database;

    // Resetar status de todas as conquistas
    await db.update(
      tableName,
      {
        'is_unlocked': 0,
        'unlocked_at': null,
        'progress': 0.0,
      },
    );
  }

  // 🔄 RESETAR CONQUISTA ESPECÍFICA
  static Future<void> resetAchievement(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      tableName,
      {
        'is_unlocked': 0,
        'unlocked_at': null,
        'progress': 0.0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 📊 ESTATÍSTICAS POR TIPO
  static Future<Map<String, int>> getStatsByType() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT 
        type,
        COUNT(*) as total,
        SUM(CASE WHEN is_unlocked = 1 THEN 1 ELSE 0 END) as unlocked
      FROM $tableName 
      GROUP BY type
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      final type = row['type'] as String;
      stats['${type}_total'] = row['total'] as int;
      stats['${type}_unlocked'] = row['unlocked'] as int;
    }

    return stats;
  }

  // 🏆 BUSCAR CONQUISTAS RECENTES (últimas 7 desbloqueadas)
  static Future<List<Achievement>> findRecentUnlocked({int limit = 7}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_unlocked = ?',
      whereArgs: [1],
      orderBy: 'unlocked_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  // 🎯 BUSCAR CONQUISTAS PRÓXIMAS (com progresso > 50%)
  static Future<List<Achievement>> findNearCompletion() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_unlocked = ? AND progress >= ?',
      whereArgs: [0, 0.5],
      orderBy: 'progress DESC',
    );
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }
}
