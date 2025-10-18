import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel.dart';

class TravelService {
  static const String _travelsKey = 'travels';
  
  Future<List<Travel>> getTravels() async {
    final prefs = await SharedPreferences.getInstance();
    final String? travelsString = prefs.getString(_travelsKey);
    
    if (travelsString == null || travelsString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(travelsString);
      return jsonList.map((json) => Travel.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error parsing travels: $e');
      return [];
    }
  }
  
  Future<void> insertTravel(Travel travel) async {
    final travels = await getTravels();
    travel.id = DateTime.now().millisecondsSinceEpoch;
    travels.add(travel);
    await _saveTravels(travels);
  }
  
  Future<void> updateTravel(Travel travel) async {
    final travels = await getTravels();
    final index = travels.indexWhere((t) => t.id == travel.id);
    if (index != -1) {
      travels[index] = travel;
      await _saveTravels(travels);
    }
  }
  
  Future<void> deleteTravel(int id) async {
    final travels = await getTravels();
    travels.removeWhere((t) => t.id == id);
    await _saveTravels(travels);
  }
  
  Future<void> _saveTravels(List<Travel> travels) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = travels.map((travel) => travel.toMap()).toList();
    await prefs.setString(_travelsKey, jsonEncode(jsonList));
  }
}
