import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/logement.dart';

class LogementService {
  static final LogementService _instance = LogementService._internal();
  factory LogementService() => _instance;
  LogementService._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<void> _initializeDatabaseFactory() async {
    if (_initialized) return;

    if (kIsWeb) {
      // Web platform
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Pour Android/iOS, pas besoin d'initialisation supplémentaire

    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    await _initializeDatabaseFactory();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'logements.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        type TEXT NOT NULL,
        adresse TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT NOT NULL,
        prixParNuit REAL NOT NULL,
        nombreChambres INTEGER NOT NULL,
        capacitePersonnes INTEGER NOT NULL,
        imageUrl TEXT,
        commodites TEXT,
        note REAL,
        telephone TEXT,
        email TEXT,
        disponible INTEGER NOT NULL DEFAULT 1,
        dateAjout TEXT NOT NULL
      )
    ''');

    // Insérer des données de test
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final samples = [
      {
        'nom': 'Hôtel Le Palace',
        'type': 'hotel',
        'adresse': 'Avenue Habib Bourguiba, Tunis, Tunisie',
        'latitude': 36.8065,
        'longitude': 10.1815,
        'description': 'Hôtel de luxe 5 étoiles au cœur de Tunis avec vue sur la médina. Chambres spacieuses et élégantes.',
        'prixParNuit': 150.0,
        'nombreChambres': 50,
        'capacitePersonnes': 100,
        'imageUrl': 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
        'commodites': 'WiFi,Parking,Piscine,Restaurant,Spa,Climatisation',
        'note': 4.5,
        'telephone': '+216 71 123 456',
        'email': 'contact@lepalace.tn',
        'disponible': 1,
        'dateAjout': DateTime.now().toIso8601String(),
      },
      {
        'nom': 'Appartement Vue Mer',
        'type': 'airbnb',
        'adresse': 'La Marsa, Tunis, Tunisie',
        'latitude': 36.8783,
        'longitude': 10.3250,
        'description': 'Magnifique appartement moderne avec vue panoramique sur la mer Méditerranée.',
        'prixParNuit': 80.0,
        'nombreChambres': 2,
        'capacitePersonnes': 4,
        'imageUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
        'commodites': 'WiFi,Parking,Climatisation,Cuisine équipée,Balcon',
        'note': 4.8,
        'telephone': '+216 98 765 432',
        'email': 'contact@vuemer.tn',
        'disponible': 1,
        'dateAjout': DateTime.now().toIso8601String(),
      },
      {
        'nom': 'Maison Traditionnelle Sidi Bou Said',
        'type': 'maison',
        'adresse': 'Sidi Bou Said, Tunis, Tunisie',
        'latitude': 36.8687,
        'longitude': 10.3411,
        'description': 'Charmante maison traditionnelle bleue et blanche dans le village pittoresque de Sidi Bou Said.',
        'prixParNuit': 120.0,
        'nombreChambres': 3,
        'capacitePersonnes': 6,
        'imageUrl': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6',
        'commodites': 'WiFi,Jardin,Terrasse,Cuisine,Climatisation',
        'note': 4.9,
        'telephone': '+216 95 123 789',
        'email': 'maison@sidibousaid.tn',
        'disponible': 1,
        'dateAjout': DateTime.now().toIso8601String(),
      },
      {
        'nom': 'Résidence Les Jasmins',
        'type': 'hotel',
        'adresse': 'Hammamet, Tunisie',
        'latitude': 36.4000,
        'longitude': 10.6167,
        'description': 'Resort tout compris en bord de plage avec animations et activités pour toute la famille.',
        'prixParNuit': 90.0,
        'nombreChambres': 120,
        'capacitePersonnes': 240,
        'imageUrl': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d',
        'commodites': 'WiFi,Parking,Piscine,Restaurant,Bar,Animation,Plage privée',
        'note': 4.3,
        'telephone': '+216 72 456 789',
        'email': 'info@lesjasmins.tn',
        'disponible': 1,
        'dateAjout': DateTime.now().toIso8601String(),
      },
      {
        'nom': 'Studio Centre-Ville',
        'type': 'appartement',
        'adresse': 'Avenue de France, Tunis, Tunisie',
        'latitude': 36.8008,
        'longitude': 10.1865,
        'description': 'Studio moderne et fonctionnel idéal pour voyageurs d\'affaires, proche de toutes commodités.',
        'prixParNuit': 45.0,
        'nombreChambres': 1,
        'capacitePersonnes': 2,
        'imageUrl': 'https://images.unsplash.com/photo-1502672260066-6bc163421894',
        'commodites': 'WiFi,Climatisation,Cuisine équipée,Ascenseur',
        'note': 4.2,
        'telephone': '+216 91 234 567',
        'email': 'studio@centreville.tn',
        'disponible': 1,
        'dateAjout': DateTime.now().toIso8601String(),
      },
    ];

    for (var sample in samples) {
      await db.insert('logements', sample);
    }
  }

  // Récupérer tous les logements
  Future<List<Logement>> getAllLogements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('logements');
    return List.generate(maps.length, (i) => Logement.fromMap(maps[i]));
  }

  // Récupérer les logements disponibles
  Future<List<Logement>> getLogementsDisponibles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logements',
      where: 'disponible = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Logement.fromMap(maps[i]));
  }

  // Récupérer par type
  Future<List<Logement>> getLogementsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logements',
      where: 'type = ? AND disponible = ?',
      whereArgs: [type, 1],
    );
    return List.generate(maps.length, (i) => Logement.fromMap(maps[i]));
  }

  // Rechercher par critères
  Future<List<Logement>> searchLogements({
    String? nom,
    double? prixMax,
    int? minChambres,
    int? minCapacite,
  }) async {
    final db = await database;
    String where = 'disponible = ?';
    List<dynamic> whereArgs = [1];

    if (nom != null && nom.isNotEmpty) {
      where += ' AND (nom LIKE ? OR adresse LIKE ?)';
      whereArgs.add('%$nom%');
      whereArgs.add('%$nom%');
    }

    if (prixMax != null) {
      where += ' AND prixParNuit <= ?';
      whereArgs.add(prixMax);
    }

    if (minChambres != null) {
      where += ' AND nombreChambres >= ?';
      whereArgs.add(minChambres);
    }

    if (minCapacite != null) {
      where += ' AND capacitePersonnes >= ?';
      whereArgs.add(minCapacite);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'logements',
      where: where,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) => Logement.fromMap(maps[i]));
  }

  // Récupérer un logement par ID
  Future<Logement?> getLogementById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Logement.fromMap(maps.first);
  }

  // Insérer un logement
  Future<int> insertLogement(Logement logement) async {
    final db = await database;
    return await db.insert('logements', logement.toMap());
  }

  // Mettre à jour un logement
  Future<int> updateLogement(Logement logement) async {
    final db = await database;
    return await db.update(
      'logements',
      logement.toMap(),
      where: 'id = ?',
      whereArgs: [logement.id],
    );
  }

  // Supprimer un logement
  Future<int> deleteLogement(int id) async {
    final db = await database;
    return await db.delete(
      'logements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Changer la disponibilité
  Future<int> toggleDisponibilite(int id, bool disponible) async {
    final db = await database;
    return await db.update(
      'logements',
      {'disponible': disponible ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
