import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class AlertService {
  static const String _alertsKey = 'user_alerts';
  
  final StreamController<List<AlertModel>> _alertsController = 
      StreamController<List<AlertModel>>.broadcast();
  
  List<AlertModel> _alerts = [];
  
  AlertService() {
    _loadAlerts();
  }

  Stream<List<AlertModel>> get alertsStream => _alertsController.stream;
  
  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getStringList(_alertsKey) ?? [];
      
      _alerts = [];
      for (final json in alertsJson) {
        try {
          // Clean up the JSON string if it's in the old format
          String cleanJson = json.trim();
          if (cleanJson.startsWith('{') && cleanJson.endsWith('}')) {
            // This is already in JSON format
            final map = jsonDecode(cleanJson) as Map<String, dynamic>;
            _alerts.add(AlertModel.fromMap(map));
          } else {
            // Try to parse as a map string (old format)
            final map = <String, dynamic>{};
            final pairs = cleanJson.replaceAll('{', '').replaceAll('}', '').split(',');
            for (final pair in pairs) {
              final keyValue = pair.split(':');
              if (keyValue.length == 2) {
                final key = keyValue[0].trim();
                var value = keyValue[1].trim();
                // Remove any quotes from the value
                if (value.startsWith("'") && value.endsWith("'")) {
                  value = value.substring(1, value.length - 1);
                }
                map[key] = value;
              }
            }
            _alerts.add(AlertModel.fromMap(map));
          }
        } catch (e) {
          print('Error parsing alert: $e');
          print('Problematic alert data: $json');
        }
      }
      
      // Sort by timestamp, newest first
      _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _alertsController.add(_alerts);
    } catch (e) {
      print('Error loading alerts: $e');
      _alerts = [];
    }
  }
  
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts
          .map((alert) => jsonEncode({
                'id': alert.id,
                'title': alert.title,
                'message': alert.message,
                'type': alert.type,
                'itemId': alert.itemId,
                'action': alert.action,
                'timestamp': alert.timestamp.toIso8601String(),
              }))
          .toList();
      await prefs.setStringList(_alertsKey, alertsJson);
      _alertsController.add(_alerts);
    } catch (e) {
      print('Error saving alerts: $e');
    }
  }
  
  Future<void> addAlert({
    required String title,
    required String message,
    required String type,
    required String itemId,
    required String action,
  }) async {
    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      itemId: itemId,
      action: action,
    );
    
    _alerts.insert(0, alert);
    // Keep only the 100 most recent alerts
    if (_alerts.length > 100) {
      _alerts = _alerts.sublist(0, 100);
    }
    
    await _saveAlerts();
  }
  
  Future<void> markAsRead(String alertId) async {
    // In a real app, you might want to track read status
    // For now, we'll just remove the alert when clicked
    _alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts();
  }
  
  Future<void> clearAll() async {
    _alerts.clear();
    await _saveAlerts();
  }
  
  void dispose() {
    _alertsController.close();
  }
}
