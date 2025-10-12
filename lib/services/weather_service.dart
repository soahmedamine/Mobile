import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "a5f3d806a7e72f0a4780e28c73299708"; // ✅ ta clé API

  Future<Map<String, dynamic>?> getWeather(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=fr",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Erreur API: ${response.statusCode}");
      return null;
    }
  }
}
