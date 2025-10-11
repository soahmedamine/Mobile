import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/travel.dart';

class TravelService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'travel1.db');

    // Supprime la DB existante pour éviter les erreurs de colonnes
    // await deleteDatabase(path); // Décommenter seulement si en dev

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE travels(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            destination TEXT,
            description TEXT,
            dateDepart TEXT,
            dateRetour TEXT,
            prix REAL,
            placesDisponibles INTEGER,
            transport TEXT,
            hebergement TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertTravel(Travel travel) async {
    final db = await database;
    await db.insert('travels', travel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Travel>> getTravels() async {
    final db = await database;
    final maps = await db.query('travels');
    return List.generate(maps.length, (i) => Travel.fromMap(maps[i]));
  }

  Future<void> updateTravel(Travel travel) async {
    final db = await database;
    await db.update('travels', travel.toMap(),
        where: 'id = ?', whereArgs: [travel.id]);
  }

  Future<void> deleteTravel(int id) async {
    final db = await database;
    await db.delete('travels', where: 'id = ?', whereArgs: [id]);
  }
}
