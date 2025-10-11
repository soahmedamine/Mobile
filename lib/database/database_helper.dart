import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // SharedPreferences instance
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Constants for column names (make them public for external use)
  static const String tableReclamations = 'reclamations';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnSubject = 'subject';
  static const String columnMessage = 'message';
  static const String columnDate = 'date';
  static const String columnStatus = 'status';
  static const String columnResponse = 'response';

  // Check if database is initialized
  bool get isInitialized => _isInitialized;

  // Initialize the database
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('Database already initialized');
      return;
    }
    
    try {
      debugPrint('Initializing database...');
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('Database initialized successfully');
      
      // Log some debug info
      final keys = _prefs.getKeys();
      debugPrint('Total keys in SharedPreferences: ${keys.length}');
      debugPrint('Reclamation keys: ${keys.where((key) => key.startsWith(tableReclamations))}');
      
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  // Insert a new reclamation
  Future<int> insertReclamation(Map<String, dynamic> reclamation) async {
    if (!_isInitialized) await init();
    
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
    if (!_isInitialized) {
      debugPrint('Initializing database in getReclamations...');
      await init();
    }
    
    try {
      debugPrint('Getting all reclamations...');
      final allKeys = _prefs.getKeys();
      debugPrint('Total keys in SharedPreferences: ${allKeys.length}');
      
      final keys = allKeys
          .where((key) => key.startsWith('$tableReclamations-'))
          .toList();
      
      debugPrint('Found ${keys.length} reclamation keys');
      
      final reclamations = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            debugPrint('Parsing reclamation from key: $key');
            final reclamation = Map<String, dynamic>.from(jsonDecode(jsonString));
            reclamations.add(reclamation);
            debugPrint('Added reclamation: ${reclamation[columnId]} - ${reclamation[columnSubject]}');
          } catch (e) {
            debugPrint('Error parsing reclamation $key: $e');
          }
        } else {
          debugPrint('No data found for key: $key');
        }
      }
      
      debugPrint('Total reclamations parsed: ${reclamations.length}');
      
      // Sort by date in descending order (newest first)
      if (reclamations.isNotEmpty) {
        reclamations.sort((a, b) => 
            (b[columnDate] as String).compareTo((a[columnDate] as String)));
      } else {
        debugPrint('No reclamations to sort');
      }
      
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

  // Print all reclamations (for debugging)
  Future<void> printAllReclamations() async {
    if (!_isInitialized) await init();
    
    try {
      final reclamations = await getReclamations();
      for (final rec in reclamations) {
        debugPrint('ID: ${rec[columnId] ?? 'N/A'}');
        debugPrint('Subject: ${rec[columnSubject] ?? 'N/A'}');
        debugPrint('Status: ${rec[columnStatus] ?? 'N/A'}');
        debugPrint('Date: ${rec[columnDate] ?? 'N/A'}');
        debugPrint('---');
      }
    } catch (e) {
      debugPrint('Error printing reclamations: $e');
      rethrow;
    }
  }
}