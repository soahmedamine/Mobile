import 'package:flutter/foundation.dart';

/// Service to filter bad words from text
class BadWordFilter {
  // Singleton pattern
  static final BadWordFilter _instance = BadWordFilter._internal();
  factory BadWordFilter() => _instance;
  BadWordFilter._internal();

  // List of bad words to filter (you can expand this list)
  final List<String> _badWords = [
    // English bad words
    'fuck',
    'shit',
    'damn',
    'bitch',
    'asshole',
    'bastard',
    'crap',
    'piss',
    'dick',
    'cock',
    'pussy',
    'hell',
    'ass',
    'bullshit',
    'motherfucker',
    'whore',
    'slut',
    'fag',
    'retard',
    'stupid',
    'idiot',
    'dumb',
    
    // French bad words
    'merde',
    'putain',
    'connard',
    'salaud',
    'enculé',
    'con',
    'salope',
    'pute',
    'bordel',
    'chier',
    'foutre',
    'cul',
    'bite',
    'couille',
    'pd',
    'fils de pute',
    'ta gueule',
    'ferme ta gueule',
    
    // Arabic bad words (transliterated)
    'klab',
    'kalb',
    'kahba',
    'charmota',
    'zebbi',
    'kess',
    'omek',
    'ayr',
    'naalek',
    'ya klab',
    'ya kalb',
    'ibn el kahba',
  ];

  /// Filter text and replace bad words with asterisks
  String filterText(String text) {
    if (text.isEmpty) return text;

    String filteredText = text;
    
    for (String badWord in _badWords) {
      // Create a case-insensitive regex pattern
      // Match the bad word with word boundaries
      final pattern = RegExp(
        r'\b' + RegExp.escape(badWord) + r'\b',
        caseSensitive: false,
      );
      
      // Replace with asterisks of the same length
      filteredText = filteredText.replaceAllMapped(pattern, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    
    debugPrint('🔍 Filtered text: ${filteredText != text ? "Bad words detected and filtered" : "No bad words found"}');
    return filteredText;
  }

  /// Check if text contains bad words
  bool containsBadWords(String text) {
    if (text.isEmpty) return false;

    for (String badWord in _badWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(badWord) + r'\b',
        caseSensitive: false,
      );
      
      if (pattern.hasMatch(text)) {
        debugPrint('⚠️ Bad word detected: $badWord');
        return true;
      }
    }
    
    return false;
  }

  /// Get list of detected bad words (for admin/logging purposes)
  List<String> getDetectedBadWords(String text) {
    if (text.isEmpty) return [];

    final List<String> detected = [];

    for (String badWord in _badWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(badWord) + r'\b',
        caseSensitive: false,
      );
      
      if (pattern.hasMatch(text)) {
        detected.add(badWord);
      }
    }
    
    return detected;
  }

  /// Add custom bad words to the filter
  void addBadWord(String word) {
    if (!_badWords.contains(word.toLowerCase())) {
      _badWords.add(word.toLowerCase());
      debugPrint('➕ Added bad word to filter: $word');
    }
  }

  /// Remove a word from the filter
  void removeBadWord(String word) {
    _badWords.remove(word.toLowerCase());
    debugPrint('➖ Removed word from filter: $word');
  }

  /// Get the total count of bad words in the filter
  int get badWordsCount => _badWords.length;
}
