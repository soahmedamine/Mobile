import 'dart:convert';
import 'package:http/http.dart' as http;

class AirQualityService {
  final String apiKey;
  AirQualityService(this.apiKey);

  Future<Map<String, dynamic>?> _geocode(String city, {String? country}) async {
    final q = country == null || country.isEmpty ? city : '$city,$country';
    final uri = Uri.parse('https://api.openweathermap.org/geo/1.0/direct?q=$q&limit=1&appid=$apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) return null;
    return (list.first as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> getAirQualityByCity(String city, {String? country}) async {
    final geo = await _geocode(city, country: country);
    if (geo == null) return null;
    final lat = geo['lat'];
    final lon = geo['lon'];
    if (lat == null || lon == null) return null;
    final uri = Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data;
  }

  // Helper to extract AQI integer 1..5 and components
  Map<String, dynamic>? parseAqi(Map<String, dynamic> data) {
    try {
      final list = data['list'] as List<dynamic>;
      if (list.isEmpty) return null;
      final main = (list.first as Map<String, dynamic>)['main'] as Map<String, dynamic>;
      final components = (list.first as Map<String, dynamic>)['components'] as Map<String, dynamic>;
      return {
        'aqi': main['aqi'],
        'components': components,
      };
    } catch (_) {
      return null;
    }
  }
}
