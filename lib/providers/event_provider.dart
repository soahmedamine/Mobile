import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  EventProvider({EventService? eventService}) : _eventService = eventService ?? EventService();

  final EventService _eventService;

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _favoritesOnly = false;
  String? _keyword;
  String? _city;
  String? _category;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minPrice;
  double? _maxPrice;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get favoritesOnly => _favoritesOnly;
  String? get keyword => _keyword;
  String? get city => _city;
  String? get category => _category;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  Future<void> loadEvents({bool forceRemote = false}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (forceRemote) {
        await _eventService.syncWithRemote(
          keyword: _keyword,
          city: _city,
          category: _category,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
      _events = await _eventService.getEvents(
        keyword: _keyword,
        city: _city,
        category: _category,
        startDate: _startDate,
        endDate: _endDate,
        favoritesOnly: _favoritesOnly,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    await loadEvents(forceRemote: false);
  }

  Future<void> sync() async {
    await loadEvents(forceRemote: true);
  }

  Future<void> toggleFavorite(Event event) async {
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      return;
    }
    final updated = event.copyWith(isFavorite: !event.isFavorite);
    _events[index] = updated;
    notifyListeners();
    if (event.id != null) {
      await _eventService.setFavorite(event.id!, updated.isFavorite);
    } else if (event.remoteId != null) {
      await _eventService.setFavoriteByRemoteId(event.remoteId!, updated.isFavorite);
    }
  }

  Future<int> saveEvent(Event event) async {
    final id = await _eventService.saveEvent(event);
    await refresh();
    return id;
  }

  Future<void> deleteEvent(Event event) async {
    if (event.id == null) {
      return;
    }
    await _eventService.deleteEvent(event.id!);
    _events.removeWhere((item) => item.id == event.id);
    notifyListeners();
  }

  Future<void> setActive(Event event, bool isActive) async {
    if (event.id == null) {
      return;
    }
    await _eventService.setActive(event.id!, isActive);
    await refresh();
  }

  void applyFilters({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    bool? favoritesOnly,
  }) {
    _keyword = keyword;
    _city = city;
    _category = category;
    _startDate = startDate;
    _endDate = endDate;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _favoritesOnly = favoritesOnly ?? _favoritesOnly;
    notifyListeners();
    loadEvents();
  }

  void clearFilters() {
    _keyword = null;
    _city = null;
    _category = null;
    _startDate = null;
    _endDate = null;
    _minPrice = null;
    _maxPrice = null;
    _favoritesOnly = false;
    notifyListeners();
    loadEvents();
  }

  Future<List<String>> getCities() {
    return _eventService.getCities();
  }

  Future<List<String>> getCategories() {
    return _eventService.getCategories();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
