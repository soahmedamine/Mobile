import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldTimeService {
  static const String _baseUrl = 'https://worldtimeapi.org/api';

  Future<DateTime?> getTimeByTimezone(String timezone) async {
    final uri = Uri.parse('$_baseUrl/timezone/$timezone');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final dt = data['datetime'] as String?;
    if (dt == null) return null;
    return DateTime.tryParse(dt);
  }

  Future<String?> findTimezoneForCountry(String countryQuery) async {
    final uri = Uri.parse('$_baseUrl/timezone');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final list = (jsonDecode(res.body) as List).cast<String>();
    // Heuristic: pick first timezone containing the country name (case-insensitive)
    final lc = countryQuery.toLowerCase();
    for (final tz in list) {
      if (tz.toLowerCase().contains(lc)) return tz;
    }
    return null;
  }

  Future<DateTime?> getLocalTimeByCountryGuess(String country) async {
    final tz = await findTimezoneForCountry(country);
    if (tz == null) return null;
    return getTimeByTimezone(tz);
  }
}
