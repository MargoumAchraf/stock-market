import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('stock_market.sqlite');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, 
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN password TEXT NOT NULL DEFAULT ""',
      );
    }
  }

Future _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      balance REAL NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE stocks (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      symbol TEXT NOT NULL,
      price REAL NOT NULL,
      country INTEGER NOT NULL,
      changePercent REAL NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
    )
  ''');
}

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
