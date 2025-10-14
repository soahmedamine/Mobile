import '../../../models/place_model.dart';

class ItineraryService {
  List<Place> optimizeItinerary(List<Place> places) {
    // Simple optimization: sort by visit date
    places.sort((a, b) => a.visitDate.compareTo(b.visitDate));
    return places;
  }

  List<Place> filterPlacesByType(List<Place> places, String type) {
    return places.where((place) => place.type == type).toList();
  }

  List<Place> filterPlacesByDate(List<Place> places, DateTime date) {
    return places.where((place) =>
    place.visitDate.year == date.year &&
        place.visitDate.month == date.month &&
        place.visitDate.day == date.day
    ).toList();
  }

  // Calculate total cost of places
  double calculateTotalCost(List<Place> places) {
    return places.fold(0.0, (sum, place) => sum + (place.price ?? 0.0));
  }

  // Group places by date
  Map<DateTime, List<Place>> groupPlacesByDate(List<Place> places) {
    final Map<DateTime, List<Place>> grouped = {};

    for (final place in places) {
      final date = DateTime(place.visitDate.year, place.visitDate.month, place.visitDate.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(place);
    }

    return grouped;
  }
}