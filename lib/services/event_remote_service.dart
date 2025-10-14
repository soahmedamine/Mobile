import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/event.dart';

class EventRemoteService {
  EventRemoteService({http.Client? client, String? apiToken})
      : _client = client ?? http.Client(),
        _apiToken = apiToken ?? dotenv.env['EVENTBRITE_TOKEN'];

  final http.Client _client;
  final String? _apiToken;

  Future<List<Event>> fetchEvents({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (_apiToken == null || _apiToken!.isEmpty) {
      throw Exception('EVENTBRITE_TOKEN is not configured');
    }

    final queryParameters = <String, String>{
      'sort_by': 'date',
      'expand': 'venue,category',
      'page_size': limit.toString(),
    };

    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParameters['q'] = keyword.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParameters['location.address'] = city.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      queryParameters['categories'] = category.trim();
    }
    if (startDate != null) {
      queryParameters['start_date.range_start'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      queryParameters['start_date.range_end'] = endDate.toUtc().toIso8601String();
    }

    final uri = Uri.https('www.eventbriteapi.com', '/v3/events/search/', queryParameters);
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $_apiToken'});

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch events (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final eventsJson = data['events'] as List<dynamic>? ?? <dynamic>[];

    return eventsJson
        .whereType<Map<String, dynamic>>()
        .map(Event.fromApiJson)
        .where((event) => event.title.isNotEmpty)
        .toList();
  }
}
