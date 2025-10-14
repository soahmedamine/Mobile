import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/event.dart';

class EventLocalService {
  static final EventLocalService _instance = EventLocalService._internal();
  factory EventLocalService() => _instance;
  EventLocalService._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<void> _initializeDatabaseFactory() async {
    if (_initialized) {
      return;
    }
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    await _initializeDatabaseFactory();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'events.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remoteId TEXT UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        city TEXT,
        venue TEXT,
        category TEXT,
        startDate TEXT,
        endDate TEXT,
        price REAL,
        currency TEXT,
        imageUrl TEXT,
        externalUrl TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_city ON events(city)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_category ON events(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_date ON events(startDate)');
    
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final samples = [
      {
        'title': 'Festival International de Carthage',
        'description': 'Le prestigieux festival de Carthage présente des spectacles de musique, danse et théâtre dans le cadre historique du théâtre romain. Une expérience culturelle unique sous les étoiles.',
        'city': 'Carthage',
        'venue': 'Théâtre Romain de Carthage',
        'category': 'Culture',
        'startDate': DateTime(now.year, now.month + 1, 15, 20, 0).toIso8601String(),
        'endDate': DateTime(now.year, now.month + 1, 15, 23, 0).toIso8601String(),
        'price': 50.0,
        'currency': 'TND',
        'imageUrl': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3',
        'externalUrl': 'https://www.festival-carthage.com.tn',
        'isFavorite': 0,
        'isActive': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'title': 'Concert Jazz à La Marsa',
        'description': 'Soirée jazz exceptionnelle avec des artistes internationaux et locaux. Ambiance intimiste dans un cadre méditerranéen magnifique.',
        'city': 'La Marsa',
        'venue': 'Théâtre de Plein Air',
        'category': 'Musique',
        'startDate': DateTime(now.year, now.month, now.day + 10, 21, 0).toIso8601String(),
        'endDate': DateTime(now.year, now.month, now.day + 10, 23, 30).toIso8601String(),
        'price': 30.0,
        'currency': 'TND',
        'imageUrl': 'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f',
        'externalUrl': null,
        'isFavorite': 0,
        'isActive': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'title': 'Exposition d\'Art Contemporain',
        'description': 'Découvrez les œuvres d\'artistes tunisiens et internationaux dans cette exposition d\'art contemporain unique. Peintures, sculptures et installations.',
        'city': 'Tunis',
        'venue': 'Musée d\'Art Moderne',
        'category': 'Art',
        'startDate': DateTime(now.year, now.month, now.day + 5, 10, 0).toIso8601String(),
        'endDate': DateTime(now.year, now.month + 2, now.day + 5, 18, 0).toIso8601String(),
        'price': 15.0,
        'currency': 'TND',
        'imageUrl': 'https://images.unsplash.com/photo-1561214115-f2f134cc4912',
        'externalUrl': null,
        'isFavorite': 0,
        'isActive': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'title': 'Marathon de Tunis',
        'description': 'Participez au marathon annuel de Tunis ! Parcours de 42km à travers les plus beaux quartiers de la capitale. Ambiance festive garantie.',
        'city': 'Tunis',
        'venue': 'Avenue Habib Bourguiba (Départ)',
        'category': 'Sport',
        'startDate': DateTime(now.year, now.month + 1, 1, 7, 0).toIso8601String(),
        'endDate': DateTime(now.year, now.month + 1, 1, 13, 0).toIso8601String(),
        'price': 25.0,
        'currency': 'TND',
        'imageUrl': 'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3',
        'externalUrl': null,
        'isFavorite': 0,
        'isActive': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'title': 'Soirée Gastronomique Tunisienne',
        'description': 'Découvrez les saveurs authentiques de la cuisine tunisienne lors de cette soirée gastronomique exceptionnelle. Menu dégustation avec accords mets et vins.',
        'city': 'Sidi Bou Said',
        'venue': 'Restaurant Dar El Jeld',
        'category': 'Gastronomie',
        'startDate': DateTime(now.year, now.month, now.day + 7, 19, 30).toIso8601String(),
        'endDate': DateTime(now.year, now.month, now.day + 7, 23, 0).toIso8601String(),
        'price': 75.0,
        'currency': 'TND',
        'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0',
        'externalUrl': null,
        'isFavorite': 0,
        'isActive': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    ];

    for (var sample in samples) {
      await db.insert('events', sample);
    }
  }

  Future<List<Event>> getEvents({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool favoritesOnly = false,
    bool includeInactive = false,
    double? minPrice,
    double? maxPrice,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (!includeInactive) {
      whereClauses.add('isActive = 1');
    }
    if (favoritesOnly) {
      whereClauses.add('isFavorite = 1');
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      final term = '%${keyword.trim().toLowerCase()}%';
      whereClauses.add('LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(city) LIKE ? OR LOWER(category) LIKE ?');
      whereArgs.addAll([term, term, term, term]);
    }
    if (city != null && city.isNotEmpty) {
      whereClauses.add('city = ?');
      whereArgs.add(city);
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (startDate != null) {
      whereClauses.add('startDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('startDate <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (minPrice != null) {
      whereClauses.add('(price IS NOT NULL AND price >= ?)');
      whereArgs.add(minPrice);
    }
    if (maxPrice != null) {
      whereClauses.add('(price IS NOT NULL AND price <= ?)');
      whereArgs.add(maxPrice);
    }
    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final maps = await db.query(
      'events',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'startDate IS NULL, startDate ASC, title ASC',
    );
    return maps.map(Event.fromMap).toList();
  }

  Future<List<Event>> getFavorites() async {
    return getEvents(favoritesOnly: true);
  }

  Future<Event?> getEventById(int id) async {
    final db = await database;
    final maps = await db.query('events', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return Event.fromMap(maps.first);
  }

  Future<Event?> getEventByRemoteId(String remoteId) async {
    final db = await database;
    final maps = await db.query('events', where: 'remoteId = ?', whereArgs: [remoteId], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return Event.fromMap(maps.first);
  }

  Future<int> insertEvent(Event event) async {
    final db = await database;
    final data = event.toMap();
    data.remove('id');
    return db.insert('events', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateEvent(Event event) async {
    if (event.id == null) {
      return insertEvent(event);
    }
    final db = await database;
    final data = event.toMap();
    await db.update('events', data, where: 'id = ?', whereArgs: [event.id]);
    return event.id!;
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertEvents(List<Event> events) async {
    if (events.isEmpty) {
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final event in events) {
        final data = event.toMap();
        data.remove('id');
        if (event.remoteId != null && event.remoteId!.isNotEmpty) {
          final existing = await txn.query(
            'events',
            columns: ['id', 'isFavorite', 'createdAt'],
            where: 'remoteId = ?',
            whereArgs: [event.remoteId],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            data['id'] = existing.first['id'];
            data['isFavorite'] = existing.first['isFavorite'];
            data['createdAt'] = existing.first['createdAt'];
          }
        }
        await txn.insert('events', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> setFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'events',
      {'isFavorite': isFavorite ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setFavoriteByRemoteId(String remoteId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'events',
      {'isFavorite': isFavorite ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'remoteId = ?',
      whereArgs: [remoteId],
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      'events',
      {'isActive': isActive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getDistinctCities() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT city FROM events WHERE city IS NOT NULL AND city != "" ORDER BY city');
    return result.map((row) => row['city'] as String).toList();
  }

  Future<List<String>> getDistinctCategories() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM events WHERE category IS NOT NULL AND category != "" ORDER BY category');
    return result.map((row) => row['category'] as String).toList();
  }
}
