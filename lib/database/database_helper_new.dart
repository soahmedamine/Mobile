import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Database instance
  Database? _database;
  // SharedPreferences instance
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Constants for column names
  static const String tableReclamations = 'reclamations';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnSubject = 'subject';
  static const String columnMessage = 'message';
  static const String columnDate = 'date';
  static const String columnStatus = 'status';
  static const String columnResponse = 'response';
  static const String columnAttachment = 'attachment';

  // Check if database is initialized
  bool get isInitialized => _isInitialized;

  // Get database instance
  Future<Database> get database async {
    if (_database != null && _isInitialized) return _database!;
    await init();
    return _database!;
  }

  // Initialize the database
  Future<void> init() async {
    if (_isInitialized && _database != null) {
      debugPrint('Database already initialized');
      return;
    }
    
    try {
      debugPrint('Initializing SQLite database for WEB...');
      
      // For WEB: Use sqflite_common_ffi_web
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
        _database = await databaseFactory.openDatabase(
          'reclamations.db',
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              // Create reclamations table
              await db.execute('''
                CREATE TABLE $tableReclamations (
                  $columnId TEXT PRIMARY KEY,
                  $columnName TEXT,
                  $columnEmail TEXT,
                  $columnSubject TEXT,
                  $columnMessage TEXT,
                  $columnDate TEXT,
                  $columnStatus TEXT,
                  $columnResponse TEXT,
                  $columnAttachment TEXT
                )
              ''');
              debugPrint('✅ Created reclamations table');
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < 2) {
                await db.execute('''
                  ALTER TABLE $tableReclamations ADD COLUMN $columnAttachment TEXT
                ''');
                debugPrint('✅ Added attachment column');
              }
            },
          ),
        );
      } else {
        // For mobile/desktop: Use regular sqflite
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, 'reclamations.db');
        
        _database = await openDatabase(
          path,
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE $tableReclamations (
                $columnId TEXT PRIMARY KEY,
                $columnName TEXT,
                $columnEmail TEXT,
                $columnSubject TEXT,
                $columnMessage TEXT,
                $columnDate TEXT,
                $columnStatus TEXT,
                $columnResponse TEXT,
                $columnAttachment TEXT
              )
            ''');
            debugPrint('✅ Created reclamations table');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('''
                ALTER TABLE $tableReclamations ADD COLUMN $columnAttachment TEXT
              ''');
              debugPrint('✅ Added attachment column');
            }
          },
        );
      }
      
      _isInitialized = true;
      debugPrint('✅ SQLite database initialized successfully (WEB: $kIsWeb)');
      
      // Log record count
      final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $tableReclamations')
      );
      debugPrint('📊 Total reclamations in database: $count');
      
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  // Insert a new reclamation
  Future<int> insertReclamation(Map<String, dynamic> reclamation) async {
    final db = await database;
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      reclamation[columnId] = id;
      reclamation[columnDate] = DateTime.now().toIso8601String();
      reclamation[columnStatus] = reclamation[columnStatus] ?? 'new';
      reclamation[columnResponse] = reclamation[columnResponse] ?? '';
      
      final key = '$tableReclamations-$id';
      await _prefs.setString(key, jsonEncode(reclamation));
      return 1; // Success
    } catch (e) {
      debugPrint('Error inserting reclamation: $e');
      rethrow;
    }
  }

  // Get all reclamations
  Future<List<Map<String, dynamic>>> getReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final allKeys = _prefs.getKeys();
      final keys = allKeys.where((key) => key.startsWith('$tableReclamations-')).toList();
      
      final reclamations = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final reclamation = Map<String, dynamic>.from(jsonDecode(jsonString));
            reclamations.add(reclamation);
          } catch (e) {
            debugPrint('Error parsing reclamation $key: $e');
          }
        }
      }
      
      // Sort by date in descending order (newest first)
      reclamations.sort((a, b) => (b[columnDate] as String).compareTo((a[columnDate] as String)));
      
      return reclamations;
    } catch (e) {
      debugPrint('Error getting reclamations: $e');
      rethrow;
    }
  }

  // Get a specific reclamation by ID
  Future<Map<String, dynamic>?> getReclamation(String id) async {
    if (!_isInitialized) await init();
    
    try {
      final key = '$tableReclamations-$id';
      final jsonString = _prefs.getString(key);
      
      if (jsonString == null) return null;
      
      return Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Error getting reclamation: $e');
      rethrow;
    }
  }

  // Update an existing reclamation
  Future<int> updateReclamation(Map<String, dynamic> reclamation) async {
    if (!_isInitialized) await init();
    
    try {
      final id = reclamation[columnId];
      if (id == null) {
        throw Exception('Cannot update reclamation without an ID');
      }
      
      // Ensure the date is preserved if not provided
      if (!reclamation.containsKey(columnDate)) {
        final existing = await getReclamation(id);
        if (existing != null) {
          reclamation[columnDate] = existing[columnDate];
        }
      }
      
      final key = '$tableReclamations-$id';
      await _prefs.setString(key, jsonEncode(reclamation));
      return 1; // Success
    } catch (e) {
      debugPrint('Error updating reclamation: $e');
      rethrow;
    }
  }

  // Delete a reclamation
  Future<int> deleteReclamation(String id) async {
    if (!_isInitialized) await init();
    
    try {
      final key = '$tableReclamations-$id';
      final success = await _prefs.remove(key);
      return success ? 1 : 0;
    } catch (e) {
      debugPrint('Error deleting reclamation: $e');
      rethrow;
    }
  }

  // Clear all reclamations (for testing)
  Future<void> clearAllReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final keys = _prefs.getKeys()
          .where((key) => key.startsWith('$tableReclamations-'))
          .toList();
      
      for (final key in keys) {
        await _prefs.remove(key);
      }
      
      debugPrint('All reclamations cleared successfully');
    } catch (e) {
      debugPrint('Error clearing reclamations: $e');
      rethrow;
    }
  }
}
