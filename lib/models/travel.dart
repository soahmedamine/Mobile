import 'dart:convert';

class Travel {
  int? id;
  String destination;
  String description;
  DateTime dateDepart;
  DateTime dateRetour;
  double prix;
  int placesDisponibles;
  String transport; // ou enum Transport si tu veux
  String hebergement; // ou enum Accommodation

  Travel({
    this.id,
    required this.destination,
    required this.description,
    required this.dateDepart,
    required this.dateRetour,
    required this.prix,
    required this.placesDisponibles,
    required this.transport,
    required this.hebergement,
  });

  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'description': description,
      'dateDepart': dateDepart.toIso8601String(),
      'dateRetour': dateRetour.toIso8601String(),
      'prix': prix,
      'placesDisponibles': placesDisponibles,
      'transport': transport,
      'hebergement': hebergement,
    };
  }

  factory Travel.fromMap(Map<String, dynamic> map) {
    return Travel(
      id: map['id'],
      destination: map['destination'],
      description: map['description'],
      dateDepart: DateTime.parse(map['dateDepart']),
      dateRetour: DateTime.parse(map['dateRetour']),
      prix: map['prix'],
      placesDisponibles: map['placesDisponibles'],
      transport: map['transport'],
      hebergement: map['hebergement'],
    );
  }
}
