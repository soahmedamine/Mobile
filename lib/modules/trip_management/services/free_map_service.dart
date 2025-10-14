import '../../../models/place_model.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../services/trip_service.dart';
import '../services/free_map_service.dart';
import '../services/itinerary_service.dart';

class MapExplorerScreen extends StatefulWidget {
  final Trip trip;
  final List<Place> places;

  const MapExplorerScreen({
    Key? key,
    required this.trip,
    required this.places,
  }) : super(key: key);

  @override
  _MapExplorerScreenState createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final TripService _tripService = TripService();
  final ItineraryService _itineraryService = ItineraryService();
  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    _places = widget.places;
  }

  @override
  Widget build(BuildContext context) {
    final groupedPlaces = _itineraryService.groupPlacesByDate(_places);
    final totalCost = _itineraryService.calculateTotalCost(_places);

    return Scaffold(
      appBar: AppBar(
        title: Text('Explorer - ${widget.trip.destination}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _places.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun lieu à explorer\nAjoutez des lieux pour les visualiser',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Statistics Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.place, '${_places.length}', 'Lieux'),
                  _buildStatItem(Icons.calendar_today, '${groupedPlaces.length}', 'Jours'),
                  _buildStatItem(Icons.attach_money, '\$${totalCost.toStringAsFixed(0)}', 'Coût total'),
                ],
              ),
            ),
          ),

          // Places by Date
          Expanded(
            child: ListView(
              children: [
                ...groupedPlaces.entries.map((entry) {
                  final date = entry.key;
                  final places = entry.value;
                  final dayCost = _itineraryService.calculateTotalCost(places);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ExpansionTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text('${_formatDate(date)} (${places.length} lieux)'),
                      subtitle: Text('Coût: \$${dayCost.toStringAsFixed(2)}'),
                      children: [
                        ...places.map((place) => ListTile(
                          leading: Icon(
                            _getPlaceIcon(place.type),
                            color: _getPlaceColor(place.type),
                          ),
                          title: Text(place.name),
                          subtitle: Text('${place.type} • \$${place.price?.toStringAsFixed(2) ?? '0.00'}'),
                          trailing: Text('${place.visitDate.hour}:${place.visitDate.minute.toString().padLeft(2, '0')}'),
                        )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addSamplePlaces,
            tooltip: 'Ajouter des Lieux Exemple',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          if (_places.isNotEmpty)
            FloatingActionButton(
              onPressed: _clearAllPlaces,
              tooltip: 'Effacer Tous les Lieux',
              backgroundColor: Colors.red,
              child: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  Color _getPlaceColor(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Colors.green;
      case 'hotel':
        return Colors.blue;
      case 'attraction':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _addSamplePlaces() {
    final newPlaces = [
      Place(
        name: 'Restaurant Le Délicieux',
        address: '123 Rue de la Gastronomie',
        latitude: 36.8065,
        longitude: 10.1815,
        type: 'restaurant',
        price: 45.0,
        tripId: widget.trip.id!,
        visitDate: DateTime.now().add(const Duration(days: 1)),
        rating: 4,
        notes: 'Excellente cuisine locale',
      ),
      Place(
        name: 'Hôtel de Luxe',
        address: '456 Avenue des Palmiers',
        latitude: 36.8080,
        longitude: 10.1830,
        type: 'hotel',
        price: 120.0,
        tripId: widget.trip.id!,
        visitDate: DateTime.now().add(const Duration(days: 1)),
        rating: 5,
        notes: 'Piscine et spa inclus',
      ),
      Place(
        name: 'Musée National',
        address: '789 Boulevard de la Culture',
        latitude: 36.8050,
        longitude: 10.1790,
        type: 'museum',
        price: 15.0,
        tripId: widget.trip.id!,
        visitDate: DateTime.now().add(const Duration(days: 2)),
        rating: 4,
        notes: 'Collection impressionnante',
      ),
    ];

    setState(() {
      _places.addAll(newPlaces);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lieux exemple ajoutés!')),
    );
  }

  void _clearAllPlaces() {
    setState(() {
      _places.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tous les lieux ont été effacés!')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}