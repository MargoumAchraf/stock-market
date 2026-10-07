import 'package:sqflite/sqflite.dart';
import 'package:stock_market/Database/DatabaseHelper.dart';
import 'package:stock_market/model/Stock.dart';

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

// Stock_db.dart
Future<Map<String, dynamic>?> getUserStock(String userId, String symbol) async {
  final db = await DatabaseHelper.instance.database; // use whatever getter you already have
  final rows = await db.query(
    'stocks',
    where: 'user_id = ? AND symbol = ?',
    whereArgs: [userId, symbol],
    limit: 1,
  );
  return rows.isEmpty ? null : rows.first;
}

Future<void> deleteStock(String id) async {
  final db = await DatabaseHelper.instance.database;
  await db.delete('stocks', where: 'id = ?', whereArgs: [id]);
}

Future<void> updateStock(String id, Map<String, dynamic> values) async {
  final db = await DatabaseHelper.instance.database;
  await db.update('stocks', values, where: 'id = ?', whereArgs: [id]);
}



  Future<Stock?> getStockByUserAndSymbol(String userId, String symbol) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'stocks',
      where: 'userId = ? AND symbol = ?',
      whereArgs: [userId, symbol],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Stock.fromMap(result.first);
  }

Future<bool> userHasSymbol(String userId, String symbol) async {
  final db = await DatabaseHelper.instance.database;

  final result = await db.query(
    'stocks',
    columns: ['id'],
    where: 'userId = ? AND symbol = ?',
    whereArgs: [userId, symbol],
    limit: 1,
  );

  return result.isNotEmpty;
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
