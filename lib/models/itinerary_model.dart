class Itinerary {
  String? id;
  String tripId;
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

  // Convertir en Map pour SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'date': date.toIso8601String(),
      'notes': notes,
      'estimated_cost': estimatedCost,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  // Créer depuis Map SharedPreferences
  factory Itinerary.fromMap(Map<String, dynamic> map) {
    final itemsData = List<Map<String, dynamic>>.from(map['items'] ?? []);
    return Itinerary(
      id: map['id'],
      tripId: map['trip_id'],
      date: DateTime.parse(map['date']),
      items: itemsData.map((itemData) => ItineraryItem.fromMap(itemData)).toList(),
      notes: map['notes'],
      estimatedCost: map['estimated_cost']?.toDouble() ?? 0.0,
    );
  }

  double get totalCost {
    return items.fold(estimatedCost, (sum, item) => sum + (item.estimatedCost ?? 0.0));
  }
}

class ItineraryItem {
  String? id;
  String placeName;
  String description;
  String startTime; // Stocké comme "HH:mm"
  String endTime;   // Stocké comme "HH:mm"
  String category;
  double? estimatedCost;
  String? notes;
  double? lat;
  double? lon;

  ItineraryItem({
    this.id,
    required this.placeName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.estimatedCost,
    this.notes,
    this.lat,
    this.lon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'place_name': placeName,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'category': category,
      'estimated_cost': estimatedCost,
      'notes': notes,
      'lat': lat,
      'lon': lon,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'],
      placeName: map['place_name'],
      description: map['description'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      category: map['category'],
      estimatedCost: map['estimated_cost']?.toDouble(),
      notes: map['notes'],
      lat: map['lat']?.toDouble(),
      lon: map['lon']?.toDouble(),
    );
  }

  String get timeRange {
    return '$startTime - $endTime';
  }
}