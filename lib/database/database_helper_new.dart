import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      debugPrint('✅ Database already initialized');
      return;
    }
    
    try {
      // Initialize SharedPreferences first
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ SharedPreferences initialized');
      
      debugPrint('🔄 Initializing SQLite database...');
      
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
                  $columnName TEXT NOT NULL,
                  $columnEmail TEXT NOT NULL,
                  $columnSubject TEXT NOT NULL,
                  $columnMessage TEXT NOT NULL,
                  $columnDate TEXT NOT NULL,
                  $columnStatus TEXT NOT NULL DEFAULT 'new',
                  $columnResponse TEXT,
                  $columnAttachment TEXT
                )
              ''');
              debugPrint('✅ Created reclamations table (WEB)');
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < 2) {
                try {
                  await db.execute('''
                    ALTER TABLE $tableReclamations ADD COLUMN $columnAttachment TEXT
                  ''');
                  debugPrint('✅ Added attachment column');
                } catch (e) {
                  debugPrint('Column attachment may already exist: $e');
                }
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
                $columnName TEXT NOT NULL,
                $columnEmail TEXT NOT NULL,
                $columnSubject TEXT NOT NULL,
                $columnMessage TEXT NOT NULL,
                $columnDate TEXT NOT NULL,
                $columnStatus TEXT NOT NULL DEFAULT 'new',
                $columnResponse TEXT,
                $columnAttachment TEXT
              )
            ''');
            debugPrint('✅ Created reclamations table (MOBILE)');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              try {
                await db.execute('''
                  ALTER TABLE $tableReclamations ADD COLUMN $columnAttachment TEXT
                ''');
                debugPrint('✅ Added attachment column');
              } catch (e) {
                debugPrint('Column attachment may already exist: $e');
              }
            }
          },
        );
      }
      
      // Migrate data from SharedPreferences to SQLite if needed
      await _migrateFromSharedPreferences();
      
      _isInitialized = true;
      
      // Log record count
      final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM $tableReclamations')
      );
      debugPrint('✅ SQLite database initialized successfully (WEB: $kIsWeb)');
      debugPrint('📊 Total reclamations in database: $count');
      
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  // Migrate existing data from SharedPreferences to SQLite
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final allKeys = _prefs.getKeys();
      final reclamationKeys = allKeys.where((key) => key.startsWith('$tableReclamations-')).toList();
      
      if (reclamationKeys.isEmpty) {
        debugPrint('✅ No data to migrate from SharedPreferences');
        return;
      }
      
      debugPrint('🔄 Migrating ${reclamationKeys.length} reclamations from SharedPreferences to SQLite...');
      int migratedCount = 0;
      
      for (final key in reclamationKeys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final reclamation = Map<String, dynamic>.from(jsonDecode(jsonString));
            
            // Check if this reclamation already exists in SQLite
            final id = reclamation[columnId];
            if (id != null) {
              final existing = await _database!.query(
                tableReclamations,
                where: '$columnId = ?',
                whereArgs: [id],
              );
              
              if (existing.isEmpty) {
                // Insert into SQLite
                await _database!.insert(
                  tableReclamations,
                  reclamation,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                migratedCount++;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error migrating reclamation $key: $e');
          }
        }
      }
      
      if (migratedCount > 0) {
        debugPrint('✅ Successfully migrated $migratedCount reclamations to SQLite');
        debugPrint('🗑️ You can now safely clear SharedPreferences reclamations');
      }
    } catch (e) {
      debugPrint('⚠️ Error during migration: $e');
    }
  }

  // Insert a new reclamation (compatible with both old and new code)
  Future<int> insertReclamation(Map<String, dynamic> reclamation) async {
    final db = await database;
    
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      reclamation[columnId] = id;
      reclamation[columnDate] = reclamation[columnDate] ?? DateTime.now().toIso8601String();
      reclamation[columnStatus] = reclamation[columnStatus] ?? 'new';
      reclamation[columnResponse] = reclamation[columnResponse] ?? '';
      
      // Insert into SQLite database
      await db.insert(
        tableReclamations,
        reclamation,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('✅ Inserted reclamation with ID: $id');
      return 1; // Success
    } catch (e) {
      debugPrint('❌ Error inserting reclamation: $e');
      rethrow;
    }
  }

  // Insert method (alias for compatibility with reclamation_form_screen.dart)
  Future<int> insert(Map<String, dynamic> reclamation) async {
    return insertReclamation(reclamation);
  }

  // Get all reclamations from SQLite
  Future<List<Map<String, dynamic>>> getReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final db = await database;
      final reclamations = await db.query(
        tableReclamations,
        orderBy: '$columnDate DESC', // Newest first
      );
      
      debugPrint('📋 Retrieved ${reclamations.length} reclamations from SQLite');
      return reclamations;
    } catch (e) {
      debugPrint('❌ Error getting reclamations: $e');
      rethrow;
    }
  }

  // Get a specific reclamation by ID from SQLite
  Future<Map<String, dynamic>?> getReclamation(String id) async {
    if (!_isInitialized) await init();
    
    try {
      final db = await database;
      final results = await db.query(
        tableReclamations,
        where: '$columnId = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (results.isEmpty) {
        debugPrint('⚠️ Reclamation with ID $id not found');
        return null;
      }
      
      return results.first;
    } catch (e) {
      debugPrint('❌ Error getting reclamation: $e');
      rethrow;
    }
  }

  // Update an existing reclamation in SQLite
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
      
      final db = await database;
      final rowsAffected = await db.update(
        tableReclamations,
        reclamation,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      if (rowsAffected > 0) {
        debugPrint('✅ Updated reclamation with ID: $id');
      } else {
        debugPrint('⚠️ No reclamation found with ID: $id');
      }
      
      return rowsAffected;
    } catch (e) {
      debugPrint('❌ Error updating reclamation: $e');
      rethrow;
    }
  }

  // Delete a reclamation from SQLite
  Future<int> deleteReclamation(String id) async {
    if (!_isInitialized) await init();
    
    try {
      final db = await database;
      final rowsDeleted = await db.delete(
        tableReclamations,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      
      if (rowsDeleted > 0) {
        debugPrint('✅ Deleted reclamation with ID: $id');
      } else {
        debugPrint('⚠️ No reclamation found with ID: $id to delete');
      }
      
      return rowsDeleted;
    } catch (e) {
      debugPrint('❌ Error deleting reclamation: $e');
      rethrow;
    }
  }

  // Clear all reclamations from SQLite (for testing)
  Future<void> clearAllReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final db = await database;
      final count = await db.delete(tableReclamations);
      debugPrint('✅ Cleared $count reclamations from SQLite');
    } catch (e) {
      debugPrint('❌ Error clearing reclamations: $e');
      rethrow;
    }
  }

  // Print all reclamations (for debugging)
  Future<void> printAllReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final reclamations = await getReclamations();
      debugPrint('\n========== ALL RECLAMATIONS (${ reclamations.length}) ==========');
      for (final rec in reclamations) {
        debugPrint('---');
        debugPrint('ID: ${rec[columnId] ?? 'N/A'}');
        debugPrint('Name: ${rec[columnName] ?? 'N/A'}');
        debugPrint('Email: ${rec[columnEmail] ?? 'N/A'}');
        debugPrint('Subject: ${rec[columnSubject] ?? 'N/A'}');
        debugPrint('Status: ${rec[columnStatus] ?? 'N/A'}');
        debugPrint('Date: ${rec[columnDate] ?? 'N/A'}');
      }
      debugPrint('========================================\n');
    } catch (e) {
      debugPrint('❌ Error printing reclamations: $e');
      rethrow;
    }
  }
}
