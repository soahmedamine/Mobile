import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/logement.dart';

class LogementService {
  static final LogementService _instance = LogementService._internal();
  factory LogementService() => _instance;
  LogementService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Pour le web : utiliser une base de données en mémoire
      return await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _onCreate,
      );
    } else {
      // Pour mobile : utilisation normale avec fichier
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'logements.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }
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
      // ... gardez le reste de vos données d'exemple
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

  Future<void> deleteLogement(int i) async {}

  Future<void> insertLogement(Logement logement) async {}

  Future getLogementsDisponibles() async {}

  Future<void> updateLogement(Logement logement) async {}

// ... gardez toutes vos autres méthodes existantes
// (getLogementsDisponibles, getLogementsByType, searchLogements, etc.)
}