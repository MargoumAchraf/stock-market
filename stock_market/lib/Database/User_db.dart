import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_market/Database/DatabaseHelper.dart';
import 'package:stock_market/model/SessionManager.dart';

class UserDB {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<bool> emailExists(String email) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }

  static Future<String> registerUser(
    String username,
    String email,
    String password,
  ) async {
    final id = Uuid().generateV4();

    final db = await DatabaseHelper.instance.database;
    db.insert('users', {
      'id': id,
      'username': username,
      'email': email.trim().toLowerCase(),
      'password': hashPassword(password),
      'balance': 1000000.0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return id;
  }

  static Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashPassword(password)],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(Map<String, dynamic> user) async {
    final db = await _db;

    return db.update('users', user, where: 'id = ?', whereArgs: [user['id']]);
  }

  Future<int> delete(String id) async {
    final db = await _db;

    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final db = await DatabaseHelper.instance.database;

    final String? userId = await SessionManager.getUserId();
    final String? name = await SessionManager.getUsername();

    if (userId == null) {
      return null;
    }
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    return result.isNotEmpty ? result.first : null;
  }
}
