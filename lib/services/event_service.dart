import '../models/event.dart';
import 'event_local_service.dart';
import 'event_remote_service.dart';

class EventService {
  EventService({EventLocalService? localService, EventRemoteService? remoteService})
      : _localService = localService ?? EventLocalService(),
        _remoteService = remoteService ?? EventRemoteService();

  final EventLocalService _localService;
  final EventRemoteService _remoteService;

  Future<List<Event>> getEvents({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool favoritesOnly = false,
    bool includeInactive = false,
    double? minPrice,
    double? maxPrice,
  }) {
    return _localService.getEvents(
      keyword: keyword,
      city: city,
      category: category,
      startDate: startDate,
      endDate: endDate,
      favoritesOnly: favoritesOnly,
      includeInactive: includeInactive,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Future<List<Event>> getFavorites() {
    return _localService.getFavorites();
  }

  Future<void> syncWithRemote({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final remoteEvents = await _remoteService.fetchEvents(
      keyword: keyword,
      city: city,
      category: category,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    await _localService.upsertEvents(remoteEvents);
  }

  Future<Event?> getEventById(int id) {
    return _localService.getEventById(id);
  }

  Future<Event?> getEventByRemoteId(String remoteId) {
    return _localService.getEventByRemoteId(remoteId);
  }

  Future<int> saveEvent(Event event) async {
    final now = DateTime.now();
    if (event.id == null) {
      final newEvent = event.copyWith(createdAt: now, updatedAt: now);
      return _localService.insertEvent(newEvent);
    }
    return _localService.updateEvent(event.copyWith(updatedAt: now));
  }

  Future<int> deleteEvent(int id) {
    return _localService.deleteEvent(id);
  }

  Future<void> setFavorite(int id, bool isFavorite) {
    return _localService.setFavorite(id, isFavorite);
  }

  Future<void> setFavoriteByRemoteId(String remoteId, bool isFavorite) {
    return _localService.setFavoriteByRemoteId(remoteId, isFavorite);
  }

  Future<void> setActive(int id, bool isActive) {
    return _localService.setActive(id, isActive);
  }

  Future<List<String>> getCities() {
    return _localService.getDistinctCities();
  }

  Future<List<String>> getCategories() {
    return _localService.getDistinctCategories();
  }
}
