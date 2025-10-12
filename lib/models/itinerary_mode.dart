import 'package:flutter/material.dart';

class Itinerary {
  int? id;
  int tripId; // Référence au voyage parent
  DateTime date;
  List<ItineraryItem> items;
  String? notes;
  double estimatedCost;

  Itinerary({
    this.id,
    required this.tripId,
    required this.date,
    required this.items,
    this.notes,
    this.estimatedCost = 0.0,
  });

  // Calculer le coût total de l'itinéraire
  double get totalCost {
    return items.fold(estimatedCost, (sum, item) => sum + (item.estimatedCost ?? 0.0));
  }

  // Durée totale des activités
  Duration get totalDuration {
    return items.fold(Duration.zero, (total, item) => total + item.duration);
  }

  // Nombre d'activités par catégorie
  Map<String, int> get activitiesByCategory {
    final Map<String, int> categories = {};
    for (final item in items) {
      categories[item.category] = (categories[item.category] ?? 0) + 1;
    }
    return categories;
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'date': date.toIso8601String(),
      'notes': notes,
      'estimated_cost': estimatedCost,
    };
  }

  // Créer depuis Map SQLite
  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      id: map['id'],
      tripId: map['trip_id'],
      date: DateTime.parse(map['date']),
      items: [], // Les items seront chargés séparément
      notes: map['notes'],
      estimatedCost: map['estimated_cost'] ?? 0.0,
    );
  }
}

class ItineraryItem {
  int? id;
  int itineraryId; // Référence à l'itinéraire parent
  String placeName;
  String description;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String category; // visite, repas, transport, hébergement, etc.
  double? estimatedCost;
  String? notes;
  double? lat;
  double? lon;
  int? placeId; // Référence à un lieu de la base

  ItineraryItem({
    this.id,
    required this.itineraryId,
    required this.placeName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.estimatedCost,
    this.notes,
    this.lat,
    this.lon,
    this.placeId,
  });

  // Getter pour la durée de l'activité
  Duration get duration {
    final start = DateTime(2024, 1, 1, startTime.hour, startTime.minute);
    final end = DateTime(2024, 1, 1, endTime.hour, endTime.minute);
    return end.difference(start);
  }

  // Formater l'horaire
  String get timeRange {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Vérifier si l'activité est en conflit avec une autre
  bool hasTimeConflict(ItineraryItem other) {
    final thisStart = _timeToMinutes(startTime);
    final thisEnd = _timeToMinutes(endTime);
    final otherStart = _timeToMinutes(other.startTime);
    final otherEnd = _timeToMinutes(other.endTime);

    return (thisStart < otherEnd && thisEnd > otherStart);
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itinerary_id': itineraryId,
      'place_name': placeName,
      'description': description,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'category': category,
      'estimated_cost': estimatedCost,
      'notes': notes,
      'lat': lat,
      'lon': lon,
      'place_id': placeId,
    };
  }

  // Créer depuis Map SQLite
  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    final startTimeParts = (map['start_time'] as String).split(':');
    final endTimeParts = (map['end_time'] as String).split(':');

    return ItineraryItem(
      id: map['id'],
      itineraryId: map['itinerary_id'],
      placeName: map['place_name'],
      description: map['description'],
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      category: map['category'],
      estimatedCost: map['estimated_cost'],
      notes: map['notes'],
      lat: map['lat'],
      lon: map['lon'],
      placeId: map['place_id'],
    );
  }
}

// Enum pour les catégories d'activités
class ActivityCategories {
  static const String sightseeing = 'visite';
  static const String restaurant = 'repas';
  static const String accommodation = 'hébergement';
  static const String transport = 'transport';
  static const String shopping = 'shopping';
  static const String entertainment = 'divertissement';
  static const String other = 'autre';

  static const List<String> all = [
    sightseeing,
    restaurant,
    accommodation,
    transport,
    shopping,
    entertainment,
    other,
  ];

  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'visite':
        return Icons.landscape;
      case 'repas':
        return Icons.restaurant;
      case 'hébergement':
        return Icons.hotel;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_cart;
      case 'divertissement':
        return Icons.movie;
      default:
        return Icons.place;
    }
  }

  static Color getColorForCategory(String category) {
    switch (category) {
      case 'visite':
        return Colors.green;
      case 'repas':
        return Colors.orange;
      case 'hébergement':
        return Colors.blue;
      case 'transport':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'divertissement':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}