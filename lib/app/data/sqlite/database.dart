import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE detection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feature TEXT NOT NULL,
        detect TEXT NOT NULL,
        percentage TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertDetection(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('detection', row);
  }

  Future<List<Map<String, dynamic>>> getAllDetections() async {
    final db = await instance.database;
    return await db.query('detection');
  }

  Future<int> updateDetection(Map<String, dynamic> row) async {
    final db = await instance.database;
    String id = row['id'];
    return await db.update('detection', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDetection(String id) async {
    final db = await instance.database;
    return await db.delete('detection', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getDetectionsByDate(String date) async {
    final db = await instance.database;
    return await db.query('detection', where: 'date = ?', whereArgs: [date]);
  }

  Future<void> insertDummyData() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    for (int i = 1; i <= 50; i++) {
      final dummy = {
        'feature': 'Feature $i',
        'detect':
            i % 3 == 0 ? 'Drowsy' : (i % 2 == 0 ? 'Neutral' : 'Distracted'),
        'percentage': '${(80 + i % 20)}%',
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${(now.minute + i) % 60}'
                .padLeft(2, '0'),
        'timestamp': now.add(Duration(seconds: i * 10)).toIso8601String(),
      };
      await db.insert('detection', dummy);
    }

    for (int i = 51; i <= 100; i++) {
      final offsetDays = i % 7 + 1;
      final date = now.subtract(Duration(days: offsetDays));

      final dummy = {
        'feature': 'Feature $i',
        'detect':
            i % 3 == 0 ? 'Drowsy' : (i % 2 == 0 ? 'Neutral' : 'Distracted'),
        'percentage': '${(60 + i % 30)}%',
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'time':
            '${date.hour.toString().padLeft(2, '0')}:${(date.minute + i) % 60}'
                .padLeft(2, '0'),
        'timestamp': date.add(Duration(seconds: i * 10)).toIso8601String(),
      };
      await db.insert('detection', dummy);
    }
  }

  Future<void> deleteDataExceptToday() async {
    final db = await instance.database;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await db.delete('detection', where: 'date != ?', whereArgs: [todayStr]);

    debugPrint('🧹 Data selain hari ini telah dihapus.');
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('detection');
    debugPrint('🗑️ Semua data telah dihapus.');
  }
}
