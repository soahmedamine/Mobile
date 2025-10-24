import 'dart:math';
import 'package:latlong2/latlong.dart' as ll;
import '../../../models/place_model.dart';

class FreeMapService {
  static ll.LatLng getCenter(List<Place> places) {
    if (places.isEmpty) {
      // Default to a neutral coordinate (0,0) if none provided
      return const ll.LatLng(0.0, 0.0);
    }
    double lat = 0, lng = 0;
    for (final p in places) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return ll.LatLng(lat / places.length, lng / places.length);
  }

  static double calculateTotalDistance(List<Place> places) {
    if (places.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < places.length; i++) {
      total += _haversine(
        places[i - 1].latitude,
        places[i - 1].longitude,
        places[i].latitude,
        places[i].longitude,
      );
    }
    return total;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);
}