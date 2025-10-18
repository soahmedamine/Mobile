import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Storage service using SQLite via sqflite_common_ffi_web on web and sqflite on other platforms.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  static const String _tableName = 'reclamations';
  
  factory StorageService() => _instance;

  StorageService._internal();

  Database? _database;
  bool _isInitialized = false;

  DatabaseFactory? get databaseFactoryFfiWeb => null;

  // Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      if (kIsWeb) {
        // Use the FFI web implementation backed by IndexedDB
        databaseFactory = databaseFactoryFfiWeb;
        _database = await openDatabase(
          'reclamations.db',
          version: 1,
          onCreate: (db, version) async {
            await _createTable(db);
          },
        );
      } else {
        final dbPath = await getDatabasesPath();
        final path = p.join(dbPath, 'reclamations.db');
        _database = await openDatabase(
          path,
          version: 1,
          onCreate: (db, version) async {
            await _createTable(db);
          },
        );
      }

      await _ensureSchema();
      _isInitialized = true;
      debugPrint('Database initialized successfully (web: $kIsWeb)');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _ensureSchema() async {
    if (_database == null) return;

    final columns = await _database!.rawQuery('PRAGMA table_info($_tableName)');
    final hasResponseColumn = columns.any((col) => col['name'] == 'response');

    if (!hasResponseColumn) {
      debugPrint('Adding missing response column to $_tableName');
      await _database!.execute(
        'ALTER TABLE $_tableName ADD COLUMN response TEXT DEFAULT ""',
      );
    }
  }

  Future<void> _createTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS $_tableName(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        subject TEXT,
        message TEXT,
        date TEXT,
        status TEXT,
        response TEXT
      )
      '''.trim(),
    );
  }

  // Save data to storage
  Future<int> saveData(String key, Map<String, dynamic> data) async {
    await init();

    try {
      final id = key.split('-').last;
      
      // Create a new map with only the expected fields and ensure proper types
      final Map<String, dynamic> sanitizedData = {
        'id': id,
        'name': data['name']?.toString() ?? '',
        'email': data['email']?.toString() ?? '',
        'subject': data['subject']?.toString() ?? '',
        'message': data['message']?.toString() ?? '',
        'date': data['date']?.toString() ?? DateTime.now().toIso8601String(),
        'status': (data['status'] ?? 'new')?.toString() ?? 'new',
        'response': (data['response'] ?? '')?.toString() ?? '',
      };

      if (kDebugMode) {
        print('Saving data with key: $key');
        print('Sanitized data: $sanitizedData');
      }

      final result = await _database!.insert(
        _tableName,
        sanitizedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Saved reclamation with id=$id (conflict replace result: $result)');
      return result;
    } catch (e) {
      debugPrint('Error saving data: $e');
      rethrow;
    }
  }

  Future<int> updateData(String key, Map<String, dynamic> data) async {
    await init();

    final id = key.split('-').last;
    data['id'] = id;
    data.putIfAbsent('response', () => data['response'] ?? '');

    try {
      final result = await _database!.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Updated reclamation with id=$id (result: $result)');
      return result;
    } catch (e) {
      debugPrint('Error updating data: $e');
      rethrow;
    }
  }
  
  // Get data by key
  Future<Map<String, dynamic>?> getData(String key) async {
    await init();
    try {
      final id = key.split('-').last;
      final List<Map<String, dynamic>> result = await _database!.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting data: $e');
      rethrow;
    }
  }
  
  // Get all data with optional prefix filtering
  Future<List<Map<String, dynamic>>> getAllData(String prefix) async {
    await init();
    try {
      final results = await _database!.query(
        _tableName,
        orderBy: 'date DESC',
      );
      return results;
    } catch (e) {
      debugPrint('Error getting all data: $e');
      rethrow;
    }
  }
  
  // Delete data from storage
  Future<int> deleteData(String key) async {
    await init();

    try {
      final id = key.split('-').last;
      final count = await _database!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return count;
    } catch (e) {
      debugPrint('Error deleting data: $e');
      return 0; // Failed
    }
  }

  // Close the database
  Future<void> close() async {
    if (_isInitialized) {
      await _database?.close();
      _isInitialized = false;
      _database = null;
    }
  }
}
