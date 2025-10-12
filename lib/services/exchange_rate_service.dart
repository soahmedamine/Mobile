import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  // Utilise exchangerate.host (pas de clé requise)
  static const String _baseUrl = 'https://api.exchangerate.host';

  Future<double?> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    final uri = Uri.parse('$_baseUrl/convert?from=$from&to=$to&amount=$amount');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['result'] as num?)?.toDouble();
  }
}
