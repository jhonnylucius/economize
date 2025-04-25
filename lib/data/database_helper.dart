import 'package:economize/data/default_items.dart';
import 'package:economize/data/goal_dao.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final logger = Logger();

  DatabaseHelper._init();

  Future<Database> get database async {
    try {
      logger.d('Obtendo instância do banco...');
      if (_database != null) return _database!;
      _database = await _initDB('economize.db');
      return _database!;
    } catch (e, stack) {
      logger.e('Erro ao obter banco:', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      logger.d('Iniciando banco em: $path');

      // Tenta abrir o banco primeiro para ver se existe
      if (await databaseExists(path)) {
        logger.d('Banco já existe, abrindo...');
        return await openDatabase(
          path,
          version: 12,
          onUpgrade: (db, oldVersion, newVersion) async {
            logger.d('Atualizando banco de $oldVersion para $newVersion');
            await _onUpgrade(db, oldVersion, newVersion);
          },
        );
      }

      // Se não existe, cria novo
      logger.d('Criando novo banco...');
      return await openDatabase(
        path,
        version: 12,
        onCreate: (db, version) async {
          logger.d('Criando banco de dados pela primeira vez');
          await _createDB(db, version);
        },
      );
    } catch (e, stack) {
      logger.e('Erro fatal ao inicializar banco:', error: e, stackTrace: stack);
      // Force close para evitar estado inconsistente
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // 1. Criar tabelas independentes primeiro
      await GoalsDAO().createTable(db);

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          date INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS default_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          subcategory TEXT NOT NULL,
          defaultUnit TEXT NOT NULL
        )
      ''');

      // 2. Tabelas com dependências
      await db.execute('''
        CREATE TABLE IF NOT EXISTS locations(
          id TEXT PRIMARY KEY,
          budget_id TEXT NOT NULL,
          name TEXT NOT NULL,
          address TEXT,
          price_date INTEGER NOT NULL,
          FOREIGN KEY (budget_id) REFERENCES budgets (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_units(
          item_id INTEGER NOT NULL,
          unit TEXT NOT NULL,
          PRIMARY KEY (item_id, unit),
          FOREIGN KEY (item_id) REFERENCES default_items (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_items(
          id TEXT PRIMARY KEY,
          budget_id TEXT NOT NULL,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          unit TEXT NOT NULL,
          quantity REAL NOT NULL,
          best_price_location TEXT,
          best_price REAL,
          FOREIGN KEY (budget_id) REFERENCES budgets (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS prices(
          item_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          price REAL NOT NULL,
          PRIMARY KEY (item_id, location_id),
          FOREIGN KEY (item_id) REFERENCES budget_items (id),
          FOREIGN KEY (location_id) REFERENCES locations (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS price_history(
          id TEXT PRIMARY KEY,
          item_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          price REAL NOT NULL,
          date INTEGER NOT NULL,
          variation REAL NOT NULL,
          FOREIGN KEY (item_id) REFERENCES budget_items (id),
          FOREIGN KEY (location_id) REFERENCES locations (id)
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_price_history ON price_history(item_id, location_id, date)',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS costs(
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          preco REAL NOT NULL,
          descricaoDaDespesa TEXT,
          tipoDespesa TEXT NOT NULL
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_costs_data ON costs(data)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_costs_tipo ON costs(tipoDespesa)',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS revenues(
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          preco REAL NOT NULL,
          descricaoDaReceita TEXT NOT NULL,
          tipoReceita TEXT NOT NULL
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_revenues_data ON revenues(data)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_revenues_tipo ON revenues(tipoReceita)',
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_summaries(
          budget_id TEXT PRIMARY KEY,
          total_original REAL NOT NULL,
          total_optimized REAL NOT NULL,
          savings REAL NOT NULL,
          FOREIGN KEY (budget_id) REFERENCES budgets (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_totals(
          budget_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          total REAL NOT NULL,
          PRIMARY KEY (budget_id, location_id),
          FOREIGN KEY (budget_id) REFERENCES budgets (id),
          FOREIGN KEY (location_id) REFERENCES locations (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS location_summary(
          budget_id TEXT NOT NULL,
          location_id TEXT NOT NULL,
          total_items INTEGER NOT NULL,
          average_price REAL NOT NULL,
          total_value REAL NOT NULL,
          PRIMARY KEY (budget_id, location_id),
          FOREIGN KEY (budget_id) REFERENCES budgets (id),
          FOREIGN KEY (location_id) REFERENCES locations (id)
        )
      ''');

      // 3. Popular dados iniciais
      await _populateDefaultItems(db);
      await _populateItemUnits(db);

      logger.d('Banco criado com sucesso');
    } catch (e, stack) {
      logger.e('Erro ao criar banco:', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 12) {
        // 1. Backup dos dados existentes com segurança
        Map<String, List<Map<String, dynamic>>> backupData = {};

        final tables = [
          'locations',
          'budgets',
          'budget_items',
          'prices',
          'costs',
          'revenues',
          'default_items',
          'budget_summaries',
          'location_totals',
          'location_summary',
        ];

        for (var table in tables) {
          try {
            final data = await db.query(table);
            backupData[table] = data;
          } catch (e) {
            logger.w('Tabela $table não existe no backup');
          }
        }

        // 2. Recriar tabelas
        await _createDB(db, newVersion);

        // 3. Restaurar dados na ordem correta
        try {
          if (backupData['budgets'] != null) {
            for (var item in backupData['budgets']!) {
              await db.insert(
                'budgets',
                item,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          if (backupData['locations'] != null) {
            for (var item in backupData['locations']!) {
              await db.insert(
                'locations',
                item,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          if (backupData['default_items'] != null) {
            for (var item in backupData['default_items']!) {
              await db.insert(
                'default_items',
                item,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          if (backupData['budget_items'] != null) {
            for (var item in backupData['budget_items']!) {
              await db.insert(
                'budget_items',
                item,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }

          // Restaurar o resto dos dados
          for (var table in [
            'prices',
            'costs',
            'revenues',
            'budget_summaries',
            'location_totals',
            'location_summary',
          ]) {
            if (backupData[table] != null) {
              for (var item in backupData[table]!) {
                await db.insert(
                  table,
                  item,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            }
          }
        } catch (e, stack) {
          logger.e('Erro ao restaurar dados:', error: e, stackTrace: stack);
          // Continua mesmo com erro para garantir que o banco fique utilizável
        }
      }
      logger.d('Atualização do banco concluída com sucesso');
    } catch (e, stack) {
      logger.e('Erro durante upgrade:', error: e, stackTrace: stack);
      // Não propaga o erro para garantir que o app continue funcionando
    }
  }

  Future<void> _populateDefaultItems(Database db) async {
    for (var item in defaultItems) {
      try {
        await db.insert(
            'default_items',
            {
              'name': item['name'],
              'category': item['category'],
              'subcategory': item['subcategory'],
              'defaultUnit': item['defaultUnit'],
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        logger.e('Erro ao inserir item ${item['name']}: $e');
      }
    }
  }

  Future<void> _populateItemUnits(Database db) async {
    for (var item in defaultItems) {
      try {
        final itemResult = await db.query(
          'default_items',
          where: 'name = ?',
          whereArgs: [item['name']],
        );

        if (itemResult.isEmpty) continue;

        final itemId = itemResult.first['id'] as int;
        final units = item['availableUnits'] as List<dynamic>;

        for (var unit in units) {
          await db.insert(
              'item_units',
              {
                'item_id': itemId,
                'unit': unit,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        logger.e('Erro ao inserir unidades para item ${item['name']}: $e');
      }
    }
  }
}
