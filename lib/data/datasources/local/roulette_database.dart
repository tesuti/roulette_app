import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class RouletteDatabase {
  RouletteDatabase._();

  static final RouletteDatabase instance = RouletteDatabase._();

  static const String rouletteTable = 'roulettes';
  static const String itemTable = 'items';
  static const String spinHistoryTable = 'spin_history';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'roulette_app.db');
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await createSchema(db);
      },
    );
    return db;
  }

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $rouletteTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        color_hex TEXT DEFAULT '#FFFFFF',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $itemTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roulette_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        weight REAL NOT NULL DEFAULT 1.0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (roulette_id) REFERENCES $rouletteTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $spinHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roulette_id INTEGER NOT NULL,
        item_id INTEGER,
        result_label TEXT NOT NULL,
        spun_at INTEGER NOT NULL,
        notes TEXT DEFAULT '',
        FOREIGN KEY (roulette_id) REFERENCES $rouletteTable(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES $itemTable(id) ON DELETE SET NULL
      )
    ''');
  }

  static Future<void> reset(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $spinHistoryTable');
    await db.execute('DROP TABLE IF EXISTS $itemTable');
    await db.execute('DROP TABLE IF EXISTS $rouletteTable');
    await createSchema(db);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
