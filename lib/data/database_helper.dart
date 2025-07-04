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

  // ✅ VERSÃO ATUALIZADA - INCREMENTEI PARA 18
  static const int _currentVersion = 18;

  // --- SEÇÃO DE CRIAÇÃO DE TABELAS (QUERIES COMO STRING) ---
  // Centralizamos aqui todas as queries que são strings estáticas.
  static final Map<String, String> _tableCreationQueries = {
    'achievements': AchievementDao.createTable,
    'budgets': '''
      CREATE TABLE budgets(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date INTEGER NOT NULL
      )
    ''',
    'default_items': '''
      CREATE TABLE default_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT NOT NULL,
        subcategory TEXT NOT NULL, defaultUnit TEXT NOT NULL
      )
    ''',
    'locations': '''
      CREATE TABLE locations(
        id TEXT PRIMARY KEY, budget_id TEXT NOT NULL, name TEXT NOT NULL,
        address TEXT, price_date INTEGER NOT NULL,
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
      )
    ''',
    'item_units': '''
      CREATE TABLE item_units(
        item_id INTEGER NOT NULL, unit TEXT NOT NULL,
        PRIMARY KEY (item_id, unit),
        FOREIGN KEY (item_id) REFERENCES default_items (id) ON DELETE CASCADE
      )
    ''',
    'budget_items': '''
      CREATE TABLE budget_items(
        id TEXT PRIMARY KEY, budget_id TEXT NOT NULL, name TEXT NOT NULL,
        category TEXT NOT NULL, unit TEXT NOT NULL, quantity REAL NOT NULL,
        best_price_location TEXT, best_price REAL,
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
      )
    ''',
    'prices': '''
      CREATE TABLE prices(
        item_id TEXT NOT NULL, location_id TEXT NOT NULL, price REAL NOT NULL,
        PRIMARY KEY (item_id, location_id),
        FOREIGN KEY (item_id) REFERENCES budget_items (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
      )
    ''',
    'price_history': '''
      CREATE TABLE price_history(
        id TEXT PRIMARY KEY, item_id TEXT NOT NULL, location_id TEXT NOT NULL,
        price REAL NOT NULL, date INTEGER NOT NULL, variation REAL NOT NULL,
        FOREIGN KEY (item_id) REFERENCES budget_items (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
      )
    ''',
    // ✅ TABELA COSTS ATUALIZADA COM OS NOVOS CAMPOS
    'costs': '''
    CREATE TABLE costs(
      id TEXT PRIMARY KEY,
      accountId INTEGER,
      data TEXT NOT NULL,
      preco REAL NOT NULL,
      descricaoDaDespesa TEXT,
      tipoDespesa TEXT NOT NULL,
      recorrente INTEGER DEFAULT 0,
      pago INTEGER DEFAULT 0,
      category TEXT,
      isLancamentoFuturo INTEGER DEFAULT 0,
      recorrenciaOrigemId TEXT,
      quantidadeMesesRecorrentes INTEGER DEFAULT 6
    )
  ''',
    'revenues': '''
      CREATE TABLE revenues(
        id TEXT PRIMARY KEY, accountId INTEGER, data TEXT NOT NULL, preco REAL NOT NULL,
        descricaoDaReceita TEXT NOT NULL, tipoReceita TEXT NOT NULL
      )
    ''',
    'budget_summaries': '''
      CREATE TABLE budget_summaries(
        budget_id TEXT PRIMARY KEY, total_original REAL NOT NULL,
        total_optimized REAL NOT NULL, savings REAL NOT NULL,
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
      )
    ''',
    'location_totals': '''
      CREATE TABLE location_totals(
        budget_id TEXT NOT NULL, location_id TEXT NOT NULL, total REAL NOT NULL,
        PRIMARY KEY (budget_id, location_id),
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
      )
    ''',
    'location_summary': '''
      CREATE TABLE location_summary(
        budget_id TEXT NOT NULL, location_id TEXT NOT NULL, total_items INTEGER NOT NULL,
        average_price REAL NOT NULL, total_value REAL NOT NULL,
        PRIMARY KEY (budget_id, location_id),
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE,
        FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
      )
    ''',
    // --- NOVAS TABELAS PARA A FEATURE DE CONTAS ---
    'accounts': '''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type INTEGER NOT NULL,
        balance REAL NOT NULL, icon INTEGER NOT NULL, currency TEXT NOT NULL
      )
    ''',
    'account_transactions': '''
      CREATE TABLE account_transactions (
        id TEXT PRIMARY KEY, accountId INTEGER NOT NULL, value REAL NOT NULL, date TEXT NOT NULL,
        type INTEGER NOT NULL, description TEXT, relatedAccountId INTEGER,
        FOREIGN KEY (accountId) REFERENCES accounts (id) ON DELETE CASCADE
      )
    '''
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('economize.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    logger.d('Iniciando banco em: $path com a versão $_currentVersion');
    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Chamado apenas para NOVOS usuários que não têm banco de dados.
  Future<void> _createDB(Database db, int version) async {
    logger.i("--- Criando um novo banco de dados na versão $version ---");
    final batch = db.batch();

    // 1. Executa as queries que são strings
    _tableCreationQueries.forEach((tableName, query) {
      logger.d("Executando query para criar tabela: $tableName");
      batch.execute(query);
    });
    await batch.commit();

    // 2. Executa as criações que são métodos de DAOs
    logger.d("Executando método para criar tabela: goals");
    await GoalsDAO().createTable(db);

    // 3. Cria os índices
    logger.d("Criando índices...");
    await db
        .execute('CREATE INDEX IF NOT EXISTS idx_costs_data ON costs(data)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_revenues_data ON revenues(data)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_price_history ON price_history(item_id, location_id, date)');
    // ✅ NOVOS ÍNDICES PARA RECORRÊNCIA
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_costs_recorrente ON costs(recorrente)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_costs_futuro ON costs(isLancamentoFuturo)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_costs_origem ON costs(recorrenciaOrigemId)');

    // 4. Popula com dados iniciais
    logger.d("Populando com dados iniciais...");
    await _populateDefaultItems(db);
    await _populateItemUnits(db);

    logger.i("✅ Novo banco de dados criado com sucesso!");
  }

  /// Chamado para usuários EXISTENTES quando você aumentar a versão do banco.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logger.i(
        "--- Atualizando banco de dados da v$oldVersion para a v$newVersion ---");

    if (oldVersion < 13) {
      logger.i("🚀 [Migrando para V13] Adicionando colunas em 'costs'...");
      try {
        await db.execute(
            'ALTER TABLE costs ADD COLUMN recorrente INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE costs ADD COLUMN pago INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE costs ADD COLUMN category TEXT');
        await db.execute(
            'UPDATE costs SET category = tipoDespesa WHERE category IS NULL');
      } catch (e) {
        logger.w(
            '[V13] Erro ao adicionar colunas em costs (pode já existir): $e');
      }
    }

    if (oldVersion < 15) {
      logger.i("🎯 [Migrando para V15] Criando tabela 'achievements'...");
      try {
        await db.execute(_tableCreationQueries['achievements']!);
      } catch (e) {
        logger
            .w('[V15] Erro ao criar tabela achievements (pode já existir): $e');
      }
    }

    if (oldVersion < 16) {
      logger.i("🏦 [Migrando para V16] Adicionando sistema de Contas...");
      try {
        await db.execute(_tableCreationQueries['accounts']!);
        await db.execute(_tableCreationQueries['account_transactions']!);
        logger.d("[V16] Adicionando 'accountId' em 'costs' e 'revenues'");
        await db.execute('ALTER TABLE costs ADD COLUMN accountId INTEGER');
        await db.execute('ALTER TABLE revenues ADD COLUMN accountId INTEGER');
      } catch (e) {
        logger.e('[V16] Erro durante a migração para a V16: $e');
      }
    }

    // ✅ NOVA MIGRAÇÃO PARA V17 - CAMPOS DE RECORRÊNCIA
    if (oldVersion < 17) {
      logger.i("🔄 [Migrando para V17] Adicionando campos de recorrência...");
      try {
        // Adiciona os novos campos para despesas recorrentes
        await db.execute(
            'ALTER TABLE costs ADD COLUMN isLancamentoFuturo INTEGER DEFAULT 0');
        await db
            .execute('ALTER TABLE costs ADD COLUMN recorrenciaOrigemId TEXT');

        // Cria índices para melhor performance
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_costs_futuro ON costs(isLancamentoFuturo)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_costs_origem ON costs(recorrenciaOrigemId)');

        logger.i("✅ [V17] Campos de recorrência adicionados com sucesso!");
      } catch (e) {
        logger.e('[V17] Erro durante a migração para a V17: $e');
      }
    }

    // ✅ NOVA MIGRAÇÃO PARA V18 - quantidadeMesesRecorrentes
    if (oldVersion < 18) {
      logger.i(
          "📊 [Migrando para V18] Adicionando campo quantidadeMesesRecorrentes...");
      try {
        await db.execute(
            'ALTER TABLE costs ADD COLUMN quantidadeMesesRecorrentes INTEGER DEFAULT 6');
        logger.i("✅ [V18] Campo quantidadeMesesRecorrentes adicionado!");
      } catch (e) {
        logger.e('[V18] Erro durante a migração para a V18: $e');
      }
    }

    logger.i("✅ Migração do banco de dados concluída!");
  }

  Future<void> _populateDefaultItems(Database db) async {
    for (var item in defaultItems) {
      await db.insert(
          'default_items',
          {
            'name': item['name'],
            'category': item['category'],
            'subcategory': item['subcategory'],
            'defaultUnit': item['defaultUnit'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _populateItemUnits(Database db) async {
    for (var item in defaultItems) {
      final itemResult = await db
          .query('default_items', where: 'name = ?', whereArgs: [item['name']]);
      if (itemResult.isEmpty) continue;
      final itemId = itemResult.first['id'] as int;
      final units = item['availableUnits'] as List<dynamic>;
      for (var unit in units) {
        await db.insert('item_units', {'item_id': itemId, 'unit': unit},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }
}
