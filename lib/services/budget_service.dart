import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget.dart';

class BudgetService {
  static const String _tableName = 'budgets';
  static const String _dbName = 'travel_budget.db';
  static const int _dbVersion = 1;

  // Singleton pattern
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  Database? _database;
  
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    try {
      if (kIsWeb) {
        // Initialize for web
        databaseFactory = databaseFactoryFfiWeb;
        _database = await databaseFactory.openDatabase(
          _dbName,
          options: OpenDatabaseOptions(
            version: _dbVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onConfigure: _onConfigure,
          ),
        );
      } else {
        // Initialize for mobile/desktop
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, _dbName);
        
        // Ensure the directory exists
        await Directory(dbPath).create(recursive: true);
        
        _database = await openDatabase(
          path,
          version: _dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
        );
      }
      
      debugPrint('✅ Budget database initialized (WEB: $kIsWeb)');
      return _database;
    } catch (e) {
      debugPrint('❌ Error initializing budget database: $e');
      return null;
    }
  }
  
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Example of schema migration for future versions
      // await db.execute('ALTER TABLE $_tableName ADD COLUMN new_column TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        travelId TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    debugPrint('✅ Created budgets table');
  }

  // CRUD Operations
  Future<int> insertBudget(Budget budget) async {
    try {
      final db = await database;
      if (db == null) return 0;
      
      final id = await db.insert(
        _tableName,
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('✅ Inserted budget with ID: $id');
      return id;
    } catch (e) {
      debugPrint('❌ Error in insertBudget: $e');
      return 0;
    }
  }

  Future<List<Budget>> getBudgets(String travelId) async {
    try {
      final db = await database;
      if (db == null) return [];
      
      final budgets = await db.query(
        _tableName,
        where: 'travelId = ?',
        whereArgs: [travelId],
        orderBy: 'date DESC',
      );
      
      debugPrint('📋 Retrieved ${budgets.length} budgets for travel: $travelId');
      return budgets.map((json) => Budget.fromMap(json)).toList();
    } catch (e) {
      debugPrint('❌ Error in getBudgets: $e');
      return [];
    }
  }

  Future<int> updateBudget(Budget budget) async {
    try {
      final db = await database;
      if (db == null) return 0;
      
      final rowsAffected = await db.update(
        _tableName,
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [budget.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      debugPrint('✅ Updated budget with ID: ${budget.id}');
      return rowsAffected;
    } catch (e) {
      debugPrint('❌ Error in updateBudget: $e');
      return 0;
    }
  }

  Future<int> deleteBudget(int id) async {
    try {
      final db = await database;
      if (db == null) return 0;
      
      final rowsAffected = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('✅ Deleted budget with ID: $id');
      return rowsAffected;
    } catch (e) {
      debugPrint('❌ Error in deleteBudget: $e');
      return 0;
    }
  }

  // Analytics
  Future<Map<String, double>> getCategoryTotals(String travelId) async {
    try {
      if (travelId.isEmpty) {
        throw ArgumentError('travelId cannot be empty');
      }
      
      final budgets = await getBudgets(travelId);
      final Map<String, double> categoryTotals = {};
      
      for (var budget in budgets.where((b) => b.type == 'expense')) {
        if (budget.amount <= 0) continue; // Skip invalid amounts
        
        categoryTotals.update(
          budget.category,
          (value) => value + budget.amount,
          ifAbsent: () => budget.amount,
        );
      }
      
      return categoryTotals;
    } catch (e) {
      debugPrint('❌ Error in getCategoryTotals: $e');
      rethrow;
    }
  }

  Future<double> getTotalSpent(String travelId) async {
    try {
      final budgets = await getBudgets(travelId);
      return budgets
          .where((budget) => budget.type == 'expense')
          .fold<double>(0.0, (double sum, budget) => sum + budget.amount);
    } catch (e) {
      throw Exception('Failed to calculate total spent: $e');
    }
  }

  Future<double> getTotalBudget(String travelId) async {
    try {
      final budgets = await getBudgets(travelId);
      return budgets
          .where((budget) => budget.type == 'income')
          .fold<double>(0.0, (double sum, budget) => sum + budget.amount);
    } catch (e) {
      throw Exception('Failed to calculate total budget: $e');
    }
  }

  // Predict future expenses
  Future<Map<String, dynamic>> predictFutureExpenses(String travelId, int daysRemaining) async {
    try {
      if (travelId.isEmpty) {
        throw ArgumentError('travelId cannot be empty');
      }
      if (daysRemaining <= 0) {
        throw ArgumentError('daysRemaining must be greater than 0');
      }
      
      final budgets = await getBudgets(travelId);
      final expenses = budgets
          .where((b) => b.type == 'expense' && b.amount > 0)
          .toList();
      
      if (expenses.isEmpty) {
        return {
          'dailyAverage': 0.0,
          'predictedExpense': 0.0,
          'categoryBreakdown': <String, double>{},
        };
      }
      
      // Calculate daily average spending with validation
      final firstExpenseDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final daysPassed = DateTime.now().difference(firstExpenseDate).inDays + 1;
      
      if (daysPassed <= 0) {
        return {
          'dailyAverage': 0.0,
          'predictedExpense': 0.0,
          'categoryBreakdown': <String, double>{},
        };
      }
      
      final totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
      final dailyAverage = totalSpent / daysPassed;
      
      // Predict future expenses by category
      final categoryAverages = <String, double>{};
      final categories = expenses.map((e) => e.category).toSet();
      
      for (var category in categories) {
        final categoryExpenses = expenses.where((e) => e.category == category);
        final categoryTotal = categoryExpenses.fold(0.0, (sum, item) => sum + item.amount);
        categoryAverages[category] = (categoryTotal / daysPassed) * daysRemaining;
      }
      
      return {
        'dailyAverage': dailyAverage,
        'predictedExpense': dailyAverage * daysRemaining,
        'categoryBreakdown': categoryAverages,
      };
    } catch (e) {
      debugPrint('❌ Error in predictFutureExpenses: $e');
      rethrow;
    }
  }
}
