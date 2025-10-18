import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  // If FastForex API key is provided, use FastForex; otherwise fallback to exchangerate.host
  final String? fastForexKey;
  ExchangeRateService({this.fastForexKey});

  static const String _hostBaseUrl = 'https://api.exchangerate.host';
  static const String _fastForexBase = 'https://api.fastforex.io';

  Future<double?> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    if (fastForexKey != null && fastForexKey!.isNotEmpty) {
      // Try FastForex convert endpoint first
      final uri = Uri.parse('$_fastForexBase/convert?from=$from&to=$to&amount=$amount&api_key=$fastForexKey');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        // FastForex convert may return result like { "result": { "EUR": 0.93 } } or { "rate": 0.93 }
        final result = data['result'];
        if (result is Map && result[to] != null) {
          return (result[to] as num).toDouble();
        }
        if (data['rate'] != null) {
          return (data['rate'] as num).toDouble();
        }
      }
      // Fallback to fetch-one
      final uriOne = Uri.parse('$_fastForexBase/fetch-one?from=$from&to=$to&api_key=$fastForexKey');
      final resOne = await http.get(uriOne);
      if (resOne.statusCode == 200) {
        final data = jsonDecode(resOne.body) as Map<String, dynamic>;
        final result = data['result'];
        if (result is Map && result[to] != null) {
          final rate = (result[to] as num).toDouble();
          return rate * amount;
        }
      }
      return null;
    } else {
      // Fallback: exchangerate.host (no key)
      final uri = Uri.parse('$_hostBaseUrl/convert?from=$from&to=$to&amount=$amount');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['result'] as num?)?.toDouble();
    }
  }
}
