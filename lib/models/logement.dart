class Logement {
  final int? id;
  final String nom;
  final String type; // hotel, airbnb, appartement, maison
  final String adresse;
  final double latitude;
  final double longitude;
  final String description;
  final double prixParNuit;
  final int nombreChambres;
  final int capacitePersonnes;
  final String? imageUrl;
  final List<String> commodites; // WiFi, Parking, Piscine, etc.
  final double? note; // 0-5 étoiles
  final String? telephone;
  final String? email;
  final bool disponible;
  final DateTime dateAjout;

  Logement({
    this.id,
    required this.nom,
    required this.type,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.prixParNuit,
    required this.nombreChambres,
    required this.capacitePersonnes,
    this.imageUrl,
    this.commodites = const [],
    this.note,
    this.telephone,
    this.email,
    this.disponible = true,
    DateTime? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now();

  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'prixParNuit': prixParNuit,
      'nombreChambres': nombreChambres,
      'capacitePersonnes': capacitePersonnes,
      'imageUrl': imageUrl,
      'commodites': commodites.join(','),
      'note': note,
      'telephone': telephone,
      'email': email,
      'disponible': disponible ? 1 : 0,
      'dateAjout': dateAjout.toIso8601String(),
    };
  }

  // Créer depuis Map (base de données)
  factory Logement.fromMap(Map<String, dynamic> map) {
    return Logement(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      type: map['type'] as String,
      adresse: map['adresse'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      description: map['description'] as String,
      prixParNuit: map['prixParNuit'] as double,
      nombreChambres: map['nombreChambres'] as int,
      capacitePersonnes: map['capacitePersonnes'] as int,
      imageUrl: map['imageUrl'] as String?,
      commodites: map['commodites'] != null
          ? (map['commodites'] as String).split(',').where((e) => e.isNotEmpty).toList()
          : [],
      note: map['note'] as double?,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      disponible: map['disponible'] == 1,
      dateAjout: DateTime.parse(map['dateAjout'] as String),
    );
  }

  // Copier avec modifications
  Logement copyWith({
    int? id,
    String? nom,
    String? type,
    String? adresse,
    double? latitude,
    double? longitude,
    String? description,
    double? prixParNuit,
    int? nombreChambres,
    int? capacitePersonnes,
    String? imageUrl,
    List<String>? commodites,
    double? note,
    String? telephone,
    String? email,
    bool? disponible,
    DateTime? dateAjout,
  }) {
    return Logement(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      prixParNuit: prixParNuit ?? this.prixParNuit,
      nombreChambres: nombreChambres ?? this.nombreChambres,
      capacitePersonnes: capacitePersonnes ?? this.capacitePersonnes,
      imageUrl: imageUrl ?? this.imageUrl,
      commodites: commodites ?? this.commodites,
      note: note ?? this.note,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      disponible: disponible ?? this.disponible,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }
}
