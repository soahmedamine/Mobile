import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/city_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'cities.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertCity(City city) async {
    final db = await database;
    await db.insert('cities', city.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<City>> getCities() async {
    final db = await database;
    final maps = await db.query('cities', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => City.fromMap(maps[i]));
  }

  Future<void> deleteCity(int id) async {
    final db = await database;
    await db.delete('cities', where: 'id = ?', whereArgs: [id]);
  }
}
