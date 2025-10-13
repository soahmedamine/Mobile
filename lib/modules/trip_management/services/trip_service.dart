import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../../../models/expense_model.dart';
import '../../../database/database_helper.dart';

class TripService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Trip CRUD operations
  Future<int> createTrip(Trip trip) async {
    return await _dbHelper.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getAllTrip() async {
    final List<Map<String, dynamic>> tripsData = await _dbHelper.getAll('trips');
    return tripsData.map((data) => Trip.fromMap(data)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final Map<String, dynamic>? tripData = await _dbHelper.getById('trips', id);
    return tripData != null ? Trip.fromMap(tripData) : null;
  }

  Future<int> updateTrip(Trip trip) async {
    return await _dbHelper.update('trips', trip.toMap());
  }

  Future<int> deleteTrip(int id) async {
    return await _dbHelper.delete('trips', id);
  }

  // Place CRUD operations
  Future<int> addPlace(Place place) async {
    return await _dbHelper.insert('places', place.toMap());
  }

  Future<List<Place>> getTripPlaces(int tripId) async {
    final placesData = await _dbHelper.getTripPlaces(tripId);
    return placesData.map((data) => Place.fromMap(data)).toList();
  }

  Future<int> updatePlace(Place place) async {
    return await _dbHelper.update('places', place.toMap());
  }

  Future<int> deletePlace(int id) async {
    return await _dbHelper.delete('places', id);
  }

  // Expense CRUD operations
  Future<int> addExpense(Expense expense) async {
    return await _dbHelper.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getTripExpenses(int tripId) async {
    final expensesData = await _dbHelper.getTripExpenses(tripId);
    return expensesData.map((data) => Expense.fromMap(data)).toList();
  }

  Future<double> getTripTotalExpenses(int tripId) async {
    return await _dbHelper.getTotalExpenses(tripId);
  }

  Future<int> updateExpense(Expense expense) async {
    return await _dbHelper.update('expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    return await _dbHelper.delete('expenses', id);
  }
}