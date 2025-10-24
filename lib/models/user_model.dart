class User {
  int? id;
  String username;
  String email;
  String? profileImage;
  DateTime? birthDate;
  List<String> interests;
  UserPreferences preferences;
  List<UserTravelStats> travelStats;

  User({
    this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.birthDate,
    this.interests = const [],
    required this.preferences,
    this.travelStats = const [],
  });

  // Calculer l'âge
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year - birthDate!.year -
        (now.month > birthDate!.month ||
            (now.month == birthDate!.month && now.day >= birthDate!.day) ? 0 : 1);
  }

  // Statistiques de voyage résumées
  Map<String, dynamic> get summaryStats {
    final totalTrips = travelStats.length;
    final totalCountries = travelStats.map((e) => e.country).toSet().length;
    final totalSpent = travelStats.fold(0.0, (sum, stat) => sum + stat.totalSpent);

    return {
      'totalTrips': totalTrips,
      'totalCountries': totalCountries,
      'totalSpent': totalSpent,
    };
  }
}

class UserPreferences {
  double budgetRangeMin;
  double budgetRangeMax;
  List<String> preferredAccommodationTypes; // hotel, airbnb, hostel, etc.
  List<String> travelStyles; // aventurier, luxe, économique, etc.
  List<String> dislikedCategories;
  bool receiveNotifications;
  String language;
  String currency;

  UserPreferences({
    this.budgetRangeMin = 0.0,
    this.budgetRangeMax = 5000.0,
    this.preferredAccommodationTypes = const [],
    this.travelStyles = const [],
    this.dislikedCategories = const [],
    this.receiveNotifications = true,
    this.language = 'fr',
    this.currency = 'EUR',
  });
}

class UserTravelStats {
  String tripId;
  String destination;
  String country;
  DateTime tripDate;
  int durationDays;
  double totalSpent;
  List<String> visitedPlaces;
  double? satisfactionRating;

  UserTravelStats({
    required this.tripId,
    required this.destination,
    required this.country,
    required this.tripDate,
    required this.durationDays,
    required this.totalSpent,
    this.visitedPlaces = const [],
    this.satisfactionRating,
  });
}