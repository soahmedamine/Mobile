class Place {
  final int? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type;
  final double? price;
  final int tripId;
  final DateTime visitDate;
  final int? rating;
  final String? notes;

  Place({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.price,
    required this.tripId,
    required this.visitDate,
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'price': price,
      'tripId': tripId,
      'visitDate': visitDate.millisecondsSinceEpoch,
      'rating': rating,
      'notes': notes,
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      type: map['type'],
      price: map['price']?.toDouble(),
      tripId: map['tripId'],
      visitDate: DateTime.fromMillisecondsSinceEpoch(map['visitDate']),
      rating: map['rating'],
      notes: map['notes'],
    );
  }
}