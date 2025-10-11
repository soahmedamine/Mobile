import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _apiKey;
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  
  ChatService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '' {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in .env file');
    }
  }

  Future<String> sendMessage(String message, {String? context}) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            if (context != null)
              {'role': 'system', 'content': context},
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  void dispose() {
    // No need to close anything with http client
  }
}
