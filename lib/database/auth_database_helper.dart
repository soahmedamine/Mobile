import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class AuthDatabaseHelper {
  static final AuthDatabaseHelper _instance = AuthDatabaseHelper._internal();
  static Database? _database;

  // Table and column names
  final String tableUser = 'users';
  final String columnId = 'id';
  final String columnUsername = 'username';
  final String columnEmail = 'email';
  final String columnPassword = 'password';
  final String columnRole = 'role';
  final String columnAuthProvider = 'auth_provider'; // 'email', 'google', 'facebook'
  final String columnAuthId = 'auth_id'; // Social provider's user ID

  factory AuthDatabaseHelper() => _instance;

  AuthDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'smart_travel_auth.db');
      debugPrint('Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: 2, // Incremented version to trigger onUpgrade
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      debugPrint('Creating database tables...');
      await _createUserTable(db);
      await _createDefaultAdminUser(db);
      debugPrint('Database tables created successfully');
    } catch (e) {
      debugPrint('Error creating database tables: $e');
      rethrow;
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Migrate to version 2 - add social login support
      try {
        await _createUserTable(db);
        debugPrint('Database upgraded to version 2 successfully');
      } catch (e) {
        debugPrint('Error upgrading database to version 2: $e');
        rethrow;
      }
    }
  }
  
  Future<void> _createUserTable(Database db) async {
    // Drop existing table if it exists
    await db.execute('DROP TABLE IF EXISTS $tableUser');
    
    // Create new table with social login support
    await db.execute('''
      CREATE TABLE $tableUser (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername TEXT NOT NULL,
        $columnEmail TEXT NOT NULL,
        $columnPassword TEXT,
        $columnRole TEXT NOT NULL DEFAULT 'user',
        $columnAuthProvider TEXT NOT NULL DEFAULT 'email',
        $columnAuthId TEXT,
        UNIQUE($columnEmail, $columnAuthProvider) ON CONFLICT REPLACE
      )
    ''');
  }
  
  Future<void> _createDefaultAdminUser(Database db) async {
    try {
      // Check if admin user already exists
      final adminUser = await db.query(
        tableUser,
        where: '$columnEmail = ? AND $columnAuthProvider = ?',
        whereArgs: ['admin@smarttravel.com', 'email'],
      );
      
      if (adminUser.isEmpty) {
        debugPrint('Creating default admin user');
        await db.insert(tableUser, {
          columnUsername: 'Admin',
          columnEmail: 'admin@smarttravel.com',
          columnPassword: 'admin123', // In production, this should be hashed
          columnRole: 'admin',
          columnAuthProvider: 'email',
          columnAuthId: 'admin',
        });
        debugPrint('Default admin user created');
      }
    } catch (e) {
      debugPrint('Error creating default admin user: $e');
    }
  }

  // Insert a new user
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      final db = await database;
      debugPrint('Inserting user: $user');
      
      final id = await db.insert(
        tableUser, 
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('User inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting user: $e');
      rethrow;
    }
  }

  // Get user by email and password
  Future<Map<String, dynamic>?> getUserByCredentials(String email, String password) async {
    try {
      debugPrint('🔑 [AUTH] Starting authentication for: $email');
      
      // Get database instance
      final db = await database;
      if (db == null) {
        debugPrint('❌ [AUTH] Database connection is null');
        return null;
      }
      
      debugPrint('🔍 [AUTH] Searching for user with email: $email');
      
      // First, get the user by email (case-insensitive)
      final users = await db.query(
        tableUser,
        where: 'LOWER($columnEmail) = LOWER(?)',
        whereArgs: [email],
      );
      
      debugPrint('🔎 [AUTH] Found ${users.length} users with email: $email');
      
      if (users.isEmpty) {
        debugPrint('❌ [AUTH] No user found with email: $email');
        return null;
      }
      
      final user = users.first;
      final storedPassword = user[columnPassword] as String?;
      
      if (storedPassword == null) {
        debugPrint('❌ [AUTH] Stored password is null for user: $email');
        return null;
      }
      
      debugPrint('🔑 [AUTH] Comparing passwords...');
      debugPrint('  - Input password length: ${password.length}');
      debugPrint('  - Stored password length: ${storedPassword.length}');
      
      // Compare the provided password with the stored password
      final passwordsMatch = storedPassword == password;
      
      if (passwordsMatch) {
        debugPrint('✅ [AUTH] Authentication successful for user: $email');
        return user;
      } else {
        debugPrint('❌ [AUTH] Password mismatch for user: $email');
        debugPrint('  - Input password: $password');
        debugPrint('  - Stored password: $storedPassword');
        return null;
      }
    } catch (e) {
      debugPrint('Error authenticating user: $e');
      return null;
    }
  }

  // Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final db = await database;
      debugPrint('Checking if email exists: $email');
      
      final result = await db.query(
        tableUser,
        columns: [columnId],
        where: 'LOWER($columnEmail) = LOWER(?)',
        whereArgs: [email],
      );
      
      final exists = result.isNotEmpty;
      debugPrint('Email $email ${exists ? 'exists' : 'does not exist'}');
      return exists;
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableUser,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  // Get user by auth provider and ID
  Future<Map<String, dynamic>?> getUserByAuthProvider(String provider, String authId) async {
    try {
      final db = await database;
      final result = await db.query(
        tableUser,
        where: '$columnAuthProvider = ? AND $columnAuthId = ?',
        whereArgs: [provider, authId],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting user by auth provider: $e');
      return null;
    }
  }
  
  // Create or update social login user
  Future<int> createOrUpdateSocialUser({
    required String username,
    required String email,
    required String provider,
    required String authId,
    String role = 'user',
  }) async {
    try {
      final db = await database;
      
      // Check if user already exists with this provider
      final existingUser = await getUserByAuthProvider(provider, authId);
      
      final userData = {
        columnUsername: username,
        columnEmail: email,
        columnRole: role,
        columnAuthProvider: provider,
        columnAuthId: authId,
      };
      
      if (existingUser != null) {
        // Update existing user
        return await db.update(
          tableUser,
          userData,
          where: '$columnId = ?',
          whereArgs: [existingUser[columnId]],
        );
      } else {
        // Insert new user
        return await db.insert(
          tableUser,
          userData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Error creating/updating social user: $e');
      rethrow;
    }
  }

  // Update user
  Future<int> updateUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update(
      tableUser,
      user,
      where: '$columnId = ?',
      whereArgs: [user[columnId]],
    );
  }

  // Delete user
  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      tableUser,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future<void> close() async {
    Database db = await database;
    await db.close();
  }
}
