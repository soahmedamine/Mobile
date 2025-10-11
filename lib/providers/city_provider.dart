import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../db/db_helper.dart';

class CityProvider with ChangeNotifier {
  List<City> _cities = [];

  List<City> get cities => _cities;

  Future<void> loadCities() async {
    _cities = await DBHelper().getCities();
    notifyListeners();
  }

  Future<void> addCity(City city) async {
    await DBHelper().insertCity(city);
    await loadCities();
  }

  Future<void> removeCity(int id) async {
    await DBHelper().deleteCity(id);
    await loadCities();
  }
}
