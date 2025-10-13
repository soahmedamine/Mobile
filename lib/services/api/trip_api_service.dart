import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/place_model.dart';

class TripApiService {
  static const String _apiKey = '5ae2e3f221c38a28845f05b6e1e72f6e';
  static const String _baseUrl = 'https://api.opentripmap.com/0.1/en/places';

  static Future<List<Place>> getPopularPlaces(String destination) async {
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/geoname?name=$destination&apikey=$_apiKey')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['lat'] != null && data['lon'] != null) {
          final double lat = data['lat'].toDouble();
          final double lon = data['lon'].toDouble();

          return await _getPlacesByCoordinates(lat, lon);
        }
      }
      return [];
    } catch (e) {
      print('Erreur API: $e');
      return [];
    }
  }

  static Future<List<Place>> _getPlacesByCoordinates(double lat, double lon) async {
    final response = await http.get(
        Uri.parse('$_baseUrl/radius?radius=10000&lat=$lat&lon=$lon&format=json&limit=15&apikey=$_apiKey')
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return _parsePlaces(data);
    }
    return [];
  }

  static List<Place> _parsePlaces(List<dynamic> placesData) {
    final List<Place> places = [];

    for (var placeData in placesData) {
      try {
        final place = Place(
          id: placeData['xid'] ?? '',
          name: placeData['name'] ?? 'Lieu inconnu',
          description: placeData['wikipedia_extracts'] != null
              ? placeData['wikipedia_extracts']['text'] ?? 'Aucune description'
              : 'Aucune description disponible',
          lat: placeData['point']['lat']?.toDouble() ?? 0.0,
          lon: placeData['point']['lon']?.toDouble() ?? 0.0,
          category: _getCategory(placeData['kinds'] ?? ''),
        );
        places.add(place);
      } catch (e) {
        print('Erreur parsing lieu: $e');
      }
    }

    return places;
  }

  static String _getCategory(String kinds) {
    if (kinds.contains('historic')) return 'Historique';
    if (kinds.contains('museums')) return 'Musée';
    if (kinds.contains('religion')) return 'Religion';
    if (kinds.contains('natural')) return 'Nature';
    if (kinds.contains('foods')) return 'Restaurant';
    if (kinds.contains('accomodations')) return 'Hébergement';
    return 'Autre';
  }
}