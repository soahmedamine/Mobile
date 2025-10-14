import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../services/trip_service.dart';
import '../services/itinerary_service.dart';
import '../widgets/place_card.dart';
import '../widgets/budget_tracker.dart';
import 'map_explorer_screen.dart';
import 'edit_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  get endDate => null;

  get startDate => null;

  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();
  final ItineraryService _itineraryService = ItineraryService();

  List<Place> _places = [];
  List<Place> _expenses = [];
  double _totalExpenses = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      final places = await _tripService.getTripPlaces(widget.trip.id!);
      final expenses = await _tripService.getTripTotalExpenses(widget.trip.id!);

      setState(() {
        _places = _itineraryService.optimizeItinerary(places);
        _totalExpenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur de chargement: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToMapExplorer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapExplorerScreen(
          trip: widget.trip,
          places: _places,
        ),
      ),
    ).then((_) => _loadTripData());
  }

  void _navigateToEditTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(trip: widget.trip),
      ),
    );

    if (result == true) {
      _loadTripData();
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le Lieu'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${place.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tripService.deletePlace(place.id!);
        _loadTripData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lieu supprimé avec succès')),
        );
      } catch (e) {
        _showError('Erreur de suppression: $e');
      }
    }
  }

  void _addNewPlace() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un Lieu'),
        content: const Text('Fonctionnalité à implémenter: formulaire d\'ajout de lieu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysDifference = widget.endDate.difference(widget.startDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            onPressed: _navigateToMapExplorer,
            tooltip: 'Explorer sur la carte',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditTrip,
            tooltip: 'Modifier le voyage',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header Info
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.destination,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Du ${_formatDate(widget.trip.startDate)} au ${_formatDate(widget.trip.endDate)}'),
                  Text('Durée: $daysDifference jours'),
                  if (widget.trip.description != null)
                    Text('Description: ${widget.trip.description}'),
                ],
              ),
            ),
          ),

          // Budget Tracker
          BudgetTracker(
            totalBudget: widget.trip.budget,
            totalExpenses: _totalExpenses,
            onAddExpense: () {
              // Implement add expense functionality
            }, expenses: [],
          ),

          // Places Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lieux Visités',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewPlace,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),

          // Places List
          Expanded(
            child: _places.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun lieu ajouté!\nAppuyez sur "Ajouter" pour commencer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return PlaceCard(
                  place: place,
                  onTap: () {
                    _showPlaceDetails(place);
                  },
                  onDelete: () => _deletePlace(place),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceDetails(Place place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${place.type}'),
              Text('Adresse: ${place.address}'),
              Text('Coordonnées: ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}'),
              if (place.price != null) Text('Prix: \$${place.price!.toStringAsFixed(2)}'),
              Text('Date de visite: ${_formatDate(place.visitDate)}'),
              if (place.rating != null) Text('Note: ${place.rating}/5'),
              if (place.notes != null) Text('Notes: ${place.notes}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}