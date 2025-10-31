import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';

class AlertProvider with ChangeNotifier {
  final AlertService _alertService;
  
  AlertProvider(this._alertService);
  
  List<AlertModel> get alerts => _alertService.alerts;
  
  Stream<List<AlertModel>> get alertsStream => _alertService.alertsStream;
  
  Future<void> addAlert({
    required String title,
    required String message,
    required String type,
    required String itemId,
    required String action,
  }) async {
    await _alertService.addAlert(
      title: title,
      message: message,
      type: type,
      itemId: itemId,
      action: action,
    );
    notifyListeners();
  }
  
  Future<void> markAsRead(String alertId) async {
    await _alertService.markAsRead(alertId);
    notifyListeners();
  }
  
  Future<void> clearAll() async {
    await _alertService.clearAll();
    notifyListeners();
  }
}
