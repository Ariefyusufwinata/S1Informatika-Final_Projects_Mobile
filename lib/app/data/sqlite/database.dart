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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''');
  }

  // CRUD example
  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('users', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
