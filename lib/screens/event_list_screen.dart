import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/event_card.dart';
import '../widgets/event_filters.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';
import 'home_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  bool _showFilters = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
    });
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('user_role') == 'admin';
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<void> _onRefresh() {
    return context.read<EventProvider>().refresh();
  }

  Future<void> _onSync() {
    return context.read<EventProvider>().sync();
  }

  void _openFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Future<void> _openDetail(Event event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event, isAdmin: _isAdmin),
      ),
    );
    if (result == true) {
      await context.read<EventProvider>().refresh();
    }
  }

  Future<void> _openForm({Event? event}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: event),
      ),
    );
    if (result == true) {
      await context.read<EventProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        final events = provider.events;
        final isLoading = provider.isLoading && events.isEmpty;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              tooltip: 'Back to Home',
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Événements',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt, color: Colors.white),
                onPressed: provider.isLoading ? null : _openFilters,
              ),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.white),
                onPressed: provider.isLoading ? null : _onSync,
              ),
            ],
          ),
          drawer: const AppDrawer(),
          floatingActionButton: _isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[700],
                  elevation: 4,
                )
              : null,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[800]!, Colors.blue[500]!, Colors.blue[200]!],
              ),
            ),
            child: SafeArea(
              child: Column(
            children: [
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: EventFilters(
                    initialKeyword: provider.keyword,
                    initialCity: provider.city,
                    initialCategory: provider.category,
                    initialStartDate: provider.startDate,
                    initialEndDate: provider.endDate,
                    initialMinPrice: provider.minPrice,
                    initialMaxPrice: provider.maxPrice,
                    initialFavoritesOnly: provider.favoritesOnly,
                    onApply: ({
                      keyword,
                      city,
                      category,
                      startDate,
                      endDate,
                      minPrice,
                      maxPrice,
                      favoritesOnly,
                    }) {
                      provider.applyFilters(
                        keyword: keyword,
                        city: city,
                        category: category,
                        startDate: startDate,
                        endDate: endDate,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        favoritesOnly: favoritesOnly,
                      );
                    },
                    onClear: provider.clearFilters,
                    cityProvider: provider.getCities,
                    categoryProvider: provider.getCategories,
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: events.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  const Icon(Icons.event_busy, size: 72, color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.errorMessage ?? 'Aucun événement trouvé',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Utilisez les filtres ou synchronisez avec la source en ligne.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8)),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: events.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  return EventCard(
                                    event: event,
                                    onTap: () => _openDetail(event),
                                    onFavoriteToggle: () => provider.toggleFavorite(event),
                                  );
                                },
                              ),
                      ),
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }
}
