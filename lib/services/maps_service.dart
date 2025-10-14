import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapsService {
  // Votre clé API OpenRouteService
  final String _openRouteServiceApiKey = dotenv.env['OPENROUTESERVICE_API_KEY'] ?? '';

  // Obtenir les directions entre deux points
  Future<Map<String, dynamic>> getDirections(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String profile
      ) async {
    final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/$profile/json'
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': _openRouteServiceApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': [
            [startLng, startLat], // IMPORTANT: [longitude, latitude]
            [endLng, endLat]
          ]
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw 'Erreur API: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      throw 'Erreur de connexion: $e';
    }
  }

  // Ouvrir dans OpenStreetMap (version simplifiée)
  Future<void> openInOpenStreetMap(double latitude, double longitude) async {
    final url = 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=15/$latitude/$longitude';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Impossible d\'ouvrir OpenStreetMap';
    }
  }

  // Extraire les informations utiles de la réponse
  Future<Map<String, dynamic>> getRouteInfo(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String profile
      ) async {
    final directions = await getDirections(startLat, startLng, endLat, endLng, profile);

    if (directions['features'] != null && directions['features'].isNotEmpty) {
      final feature = directions['features'][0];
      final properties = feature['properties'];
      final summary = properties['summary'];

      return {
        'distance': summary['distance'], // en mètres
        'duration': summary['duration'], // en secondes
        'geometry': feature['geometry'],
        'coordinates': feature['geometry']['coordinates']
      };
    }

    throw 'Aucun itinéraire trouvé';
  }

  // Calculer la distance entre deux points (formule de Haversine) - VERSION CORRIGÉE
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Rayon de la Terre en mètres

    // Conversion des degrés en radians
    final double lat1Rad = lat1 * math.pi / 180;
    final double lat2Rad = lat2 * math.pi / 180;
    final double deltaLatRad = (lat2 - lat1) * math.pi / 180;
    final double deltaLonRad = (lon2 - lon1) * math.pi / 180;

    // Formule de Haversine
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c; // Distance en mètres
  }

  // Version alternative plus simple (approximation)
  double calculateSimpleDistance(double lat1, double lon1, double lat2, double lon2) {
    // Approximation rapide (moins précise mais plus simple)
    const double kmPerDegree = 111.0; // Environ 111km par degré de latitude

    final double deltaLat = (lat2 - lat1).abs();
    final double deltaLon = (lon2 - lon1).abs() * math.cos((lat1 + lat2) * math.pi / 360);

    return kmPerDegree * math.sqrt(deltaLat * deltaLat + deltaLon * deltaLon) * 1000; // en mètres
  }

  // Obtenir les étapes détaillées de l'itinéraire
  Future<List<Map<String, dynamic>>> getRouteSteps(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String profile
      ) async {
    final directions = await getDirections(startLat, startLng, endLat, endLng, profile);
    final List<Map<String, dynamic>> steps = [];

    if (directions['features'] != null && directions['features'].isNotEmpty) {
      final segments = directions['features'][0]['properties']['segments'];

      for (var segment in segments) {
        for (var step in segment['steps']) {
          steps.add({
            'instruction': step['instruction'],
            'distance': step['distance'],
            'duration': step['duration'],
            'type': step['type']
          });
        }
      }
    }

    return steps;
  }

  // Méthode utilitaire pour formater la distance
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Méthode utilitaire pour formater la durée
  String formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '$hours h $remainingMinutes min' : '$hours h';
    }
  }

  void openGoogleMaps(double latitude, double longitude, String nom) {}

  Type getStaticMapUrl(double latitude, double longitude, {required int zoom, required int width, required int height}) {
  return Null;
  }
}