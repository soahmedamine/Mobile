import 'dart:convert';
import 'package:http/http.dart' as http;

class WorldTimeService {
  final String? timeZoneDbKey;
  WorldTimeService({this.timeZoneDbKey});

  static const String _baseUrl = 'https://worldtimeapi.org/api';
  static const String _tzdbBase = 'https://api.timezonedb.com/v2.1';

  Future<DateTime?> getTimeByTimezone(String timezone) async {
    if (timeZoneDbKey != null && timeZoneDbKey!.isNotEmpty) {
      // Use TimeZoneDB
      final uri = Uri.parse('$_tzdbBase/get-time-zone?key=$timeZoneDbKey&format=json&by=zone&zone=$timezone');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      // TimeZoneDB returns 'formatted' like '2025-10-12 14:23:45'
      final formatted = data['formatted'] as String?;
      if (formatted == null) return null;
      // Convert to ISO by replacing space with 'T'
      return DateTime.tryParse(formatted.replaceFirst(' ', 'T'));
    } else {
      // Fallback to WorldTimeAPI
      final uri = Uri.parse('$_baseUrl/timezone/$timezone');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final dt = data['datetime'] as String?;
      if (dt == null) return null;
      return DateTime.tryParse(dt);
    }
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
