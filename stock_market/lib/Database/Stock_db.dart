import 'package:sqflite/sqflite.dart';
import 'package:stock_market/Database/DatabaseHelper.dart';

class StockDB {
  Future<Database> get _db async => DatabaseHelper.instance.database;
  Future<int> insert(Map<String, dynamic> stock) async {
    final db = await _db;

    return await db.insert(
      'stocks',
      stock.entries.fold<Map<String, dynamic>>({}, (map, entry) {
        if (entry.value != null) {
          map[entry.key] = entry.value;
        }
        return map;
      }),
    );
    
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    return db.query('stocks');
  }

  Future<Map<String, dynamic>?> getBySymbol(String symbol) async {
    final db = await _db;

    final result = await db.query(
      'stocks',
      where: 'symbol = ?',
      whereArgs: [symbol],
    );

    return result.isEmpty ? null : result.first;
  }
}
