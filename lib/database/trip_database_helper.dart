import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TripDatabaseHelper {
  static final TripDatabaseHelper _instance = TripDatabaseHelper._internal();
  factory TripDatabaseHelper() => _instance;
  TripDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'trip_planner.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Table des voyages
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        destination TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        budget REAL NOT NULL,
        description TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Table des lieux
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        type TEXT NOT NULL,
        price REAL,
        tripId INTEGER NOT NULL,
        visitDate INTEGER NOT NULL,
        rating INTEGER,
        notes TEXT,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Table des dépenses
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        tripId INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('''
      CREATE INDEX idx_places_trip_id ON places(tripId)
    ''');

    await db.execute('''
      CREATE INDEX idx_expenses_trip_id ON expenses(tripId)
    ''');
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<List<Map<String, dynamic>>> getByCondition(
      String tableName, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'id DESC'
    );
  }

  Future<Map<String, dynamic>?> getById(String tableName, int id) async {
    final db = await database;
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  Future<int> delete(String tableName, int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Trip-specific methods
  Future<List<Map<String, dynamic>>> getTripPlaces(int tripId) async {
    return await getByCondition('places', 'tripId = ?', [tripId]);
  }

  Future<List<Map<String, dynamic>>> getTripExpenses(int tripId) async {
    return await getByCondition('expenses', 'tripId = ?', [tripId]);
  }

  Future<double> getTotalExpenses(int tripId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE tripId = ?',
      [tripId],
    );
    return result.first['total']?.toDouble() ?? 0.0;
  }

  // Statistics methods
  Future<int> getTotalTripsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM trips');
    return result.first['count'] as int;
  }

  Future<int> getTotalPlacesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM places');
    return result.first['count'] as int;
  }

  Future<double> getTotalBudget() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(budget) as total FROM trips');
    return result.first['total']?.toDouble() ?? 0.0;
  }

  // Cleanup methods
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase(String path) async {
    final db = await database;
    final path = join(await getDatabasesPath(), 'trip_planner.db');
    await db.close();
    await deleteDatabase(path);
  }
}

extension on Object? {
  toDouble() {}
}