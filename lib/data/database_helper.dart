import 'package:economize/data/default_items.dart';
import 'package:economize/data/gamification/achievement_dao.dart';
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
          version: 15, // Atualizamos de 14 para 15
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
        version: 15, // Atualizamos de 14 para 15
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

      // Tabela costs atualizada com os novos campos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS costs(
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          preco REAL NOT NULL,
          descricaoDaDespesa TEXT,
          tipoDespesa TEXT NOT NULL,
          recorrente INTEGER DEFAULT 0,
          pago INTEGER DEFAULT 0,
          category TEXT
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

      // ADICIONAR: Tabela de conquistas
      await db.execute(AchievementDao.createTable);

      Logger().e('✅ Tabela de conquistas criada!');

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
      logger.d(
          'Iniciando upgrade do banco de dados de $oldVersion para $newVersion');

      // ✅ NOVA MIGRAÇÃO PARA V15 - CONQUISTAS
      if (oldVersion < 15) {
        logger.i('🎯 [V15] Adicionando sistema de conquistas...');

        try {
          // Verificar se tabela já existe
          final tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='achievements'");

          if (tables.isEmpty) {
            logger.d('📝 [V15] Criando tabela achievements...');
            await db.execute(AchievementDao.createTable);
            logger.i('✅ [V15] Tabela achievements criada com sucesso!');
          } else {
            logger.d('⚠️ [V15] Tabela achievements já existe, pulando...');
          }

          // Verificar quantos registros existem
          final count =
              await db.rawQuery('SELECT COUNT(*) as count FROM achievements');
          final recordCount = count.first['count'] as int;
          logger.i('📊 [V15] Registros na tabela achievements: $recordCount');
        } catch (e) {
          logger.e('❌ [V15] Erro ao criar tabela achievements: $e');
          // Continua mesmo com erro para não quebrar o app
        }

        logger.i('🎉 [V15] Migração para v15 concluída!');
      }

      // Migração específica da versão 12 para 13
      if (oldVersion < 13) {
        logger.d('Aplicando migrações para versão 13');

        // Verificação e adição da coluna recorrente
        try {
          var tableInfo = await db.rawQuery("PRAGMA table_info(costs)");
          bool recorrenteExists =
              tableInfo.any((column) => column['name'] == 'recorrente');

          if (!recorrenteExists) {
            logger.d('Adicionando coluna recorrente à tabela costs');
            await db.execute(
                'ALTER TABLE costs ADD COLUMN recorrente INTEGER DEFAULT 0');
          }
        } catch (e) {
          logger.e('Erro ao adicionar coluna recorrente: $e');
          // Continua mesmo com erro
        }

        // Verificação e adição da coluna pago
        try {
          var tableInfo = await db.rawQuery("PRAGMA table_info(costs)");
          bool pagoExists = tableInfo.any((column) => column['name'] == 'pago');

          if (!pagoExists) {
            logger.d('Adicionando coluna pago à tabela costs');
            await db
                .execute('ALTER TABLE costs ADD COLUMN pago INTEGER DEFAULT 0');
          }
        } catch (e) {
          logger.e('Erro ao adicionar coluna pago: $e');
          // Continua mesmo com erro
        }

        // Verificação e adição da coluna category
        try {
          var tableInfo = await db.rawQuery("PRAGMA table_info(costs)");
          bool categoryExists =
              tableInfo.any((column) => column['name'] == 'category');

          if (!categoryExists) {
            logger.d('Adicionando coluna category à tabela costs');
            await db.execute('ALTER TABLE costs ADD COLUMN category TEXT');
          }

          // Atualizar valores existentes (categoria baseada no tipoDespesa)
          logger.d('Atualizando valores existentes para category');
          await db.execute(
              'UPDATE costs SET category = tipoDespesa WHERE category IS NULL');
        } catch (e) {
          logger.e('Erro ao adicionar coluna category: $e');
          // Continua mesmo com erro
        }

        logger.d('Migração para versão 13 concluída com sucesso');
      }

      // Migrações da versão anterior
      if (oldVersion < 12) {
        logger.d('Aplicando migrações anteriores à versão 12');

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
                try {
                  await db.insert(
                    table,
                    item,
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                } catch (e) {
                  logger.w('Erro ao restaurar item na tabela $table: $e');
                  // Continua mesmo com erro
                }
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
