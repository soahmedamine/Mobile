import 'package:latlong2/latlong2.dart';
import '../../../models/place_model.dart';

class FreeMapService {
  // Calculate map bounds from places
  static (double, double, double, double) calculateBounds(List<Place> places) {
    if (places.isEmpty) {
      return (36.8065, 10.1815, 36.8065, 10.1815); // Default to Tunisia coordinates
    }

    double minLat = places.first.latitude;
    double maxLat = places.first.latitude;
    double minLng = places.first.longitude;
    double maxLng = places.first.longitude;

    for (final place in places) {
      minLat = place.latitude < minLat ? place.latitude : minLat;
      maxLat = place.latitude > maxLat ? place.latitude : maxLat;
      minLng = place.longitude < minLng ? place.longitude : minLng;
      maxLng = place.longitude > maxLng ? place.longitude : maxLng;
    }

    return (minLat, minLng, maxLat, maxLng);
  }

  // Get center point of all places
  static LatLng getCenter(List<Place> places) {
    if (places.isEmpty) {
      return const LatLng(36.8065, 10.1815); // Tunisia center
    }

    final bounds = calculateBounds(places);
    final centerLat = (bounds.$1 + bounds.$3) / 2;
    final centerLng = (bounds.$2 + bounds.$4) / 2;

    return LatLng(centerLat, centerLng);
  }

  // Available tile layers (different map styles)
  static const List<Map<String, String>> tileLayers = [
    {
      'name': 'OpenStreetMap Standard',
      'urlTemplate': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'attribution': '© OpenStreetMap contributors',
    },
    {
      'name': 'OpenStreetMap Humanitarian',
      'urlTemplate': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      'attribution': '© OpenStreetMap contributors, Tiles style by Humanitarian OpenStreetMap Team',
    },
    {
      'name': 'CartoDB Voyager',
      'urlTemplate': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      'attribution': '© OpenStreetMap contributors, © CartoDB',
    },
    {
      'name': 'Wikimedia Maps',
      'urlTemplate': 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
      'attribution': '© Wikimedia Maps',
    },
  ];

  // Get marker color based on place type
  static Color getMarkerColor(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Colors.green;
      case 'hotel':
        return Colors.blue;
      case 'attraction':
        return Colors.orange;
      case 'museum':
        return Colors.purple;
      case 'beach':
        return Colors.cyan;
      default:
        return Colors.red;
    }
  }

  // Get marker icon based on place type
  static IconData getMarkerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'attraction':
        return Icons.attractions;
      case 'museum':
        return Icons.museum;
      case 'beach':
        return Icons.beach_access;
      case 'shop':
        return Icons.shopping_cart;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }
}