class Trip {
  String? id;
  String title;
  String destination;
  DateTime startDate;
  DateTime endDate;
  double budget;
  String? imageUrl;
  List<String> interests;

  Trip({
    this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.imageUrl,
    this.interests = const [],
  });

  // Convertir en Map pour SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget': budget,
      'image_url': imageUrl,
      'interests': interests,
    };
  }

  // Créer depuis Map SharedPreferences
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      title: map['title'],
      destination: map['destination'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      budget: map['budget']?.toDouble() ?? 0.0,
      imageUrl: map['image_url'],
      interests: List<String>.from(map['interests'] ?? []),
    );
  }

  // Getters pour l'affichage
  String get duration {
    final days = endDate.difference(startDate).inDays;
    return '$days jour${days > 1 ? 's' : ''}';
  }

  String get dateRange {
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}