import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsService {
  final String? _apiKey = dotenv.env['MAPBOX_API_KEY'];

  // Ouvrir Google Maps avec des coordonnées
  Future<void> openGoogleMaps(double latitude, double longitude, String label) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d\'ouvrir Google Maps';
    }
  }

  // Obtenir l'URL de la carte statique Google Maps
  String getStaticMapUrl(double latitude, double longitude, {int zoom = 15, int width = 400, int height = 300}) {
    // Extraire la clé API de l'URL
    final apiKey = _extractApiKey();

    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=color:red%7C$latitude,$longitude'
        '&key=$apiKey';
  }

  // Extraire la clé API de l'URL complète
  String _extractApiKey() {
    if (_apiKey == null) return '';

    // L'URL est au format: https://maps.googleapis.com/maps/api/js?key=API_KEY&...
    final uri = Uri.parse(_apiKey!);
    return uri.queryParameters['key'] ?? '';
  }

  // Obtenir l'URL pour les directions
  Future<void> openDirections(double fromLat, double fromLng, double toLat, double toLng) async {
    final urls = [
      // URL pour l'application Google Maps (Android/iOS)
      Uri.parse('google.navigation:q=$toLat,$toLng'),
      // URL universelle pour directions
      Uri.parse('https://maps.google.com/maps?saddr=$fromLat,$fromLng&daddr=$toLat,$toLng'),
      // URL alternative
      Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLng&destination=$toLat,$toLng'),
    ];

    for (final url in urls) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        continue;
      }
    }

    throw 'Impossible d\'ouvrir Google Maps';
  }

  // Calculer la distance approximative entre deux points (formule de Haversine)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  // Obtenir l'URL de l'iframe Google Maps
  String getMapEmbedUrl(double latitude, double longitude) {
    final apiKey = _extractApiKey();
    return 'https://www.google.com/maps/embed/v1/place?key=$apiKey&q=$latitude,$longitude';
  }
}
