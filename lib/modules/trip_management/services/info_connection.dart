import 'package:http/http.dart' as http;
import 'dart:convert';

class InfoConnection {
  static const String baseUrl = 'https://api.example.com'; // Replace with your API

  // Simulated API calls for travel information
  Future<Map<String, dynamic>> getPlaceInfo(String placeName) async {
    // Simulation d'appel API
    await Future.delayed(const Duration(seconds: 1));

    return {
      'name': placeName,
      'description': 'Information sur $placeName',
      'rating': 4.5,
      'reviews': 120,
      'priceLevel': 2,
      'category': 'Attraction',
    };
  }

  Future<List<dynamic>> searchPlaces(String query) async {
    // Simulation de recherche
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'name': '$query Restaurant',
        'type': 'restaurant',
        'address': '123 ${query} Street',
        'rating': 4.2,
      },
      {
        'name': '$query Hotel',
        'type': 'hotel',
        'address': '456 ${query} Avenue',
        'rating': 4.5,
      },
      {
        'name': '$query Attraction',
        'type': 'attraction',
        'address': '789 ${query} Road',
        'rating': 4.7,
      },
    ];
  }

  Future<Map<String, dynamic>> getWeatherInfo(String location) async {
    // Simulation de données météo
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'location': location,
      'temperature': 22,
      'condition': 'Ensoleillé',
      'humidity': 65,
      'windSpeed': 15,
    };
  }

  Future<Map<String, dynamic>> getExchangeRates() async {
    try {
      // Simulation de taux de change
      await Future.delayed(const Duration(seconds: 1));

      return {
        'USD': 1.0,
        'EUR': 0.85,
        'GBP': 0.73,
        'JPY': 110.0,
        'TND': 2.8, // Dinar tunisien
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to fetch exchange rates: $e');
    }
  }
}