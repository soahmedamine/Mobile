import 'package:flutter/material.dart';
import '../../../models/trip_model.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
import '../widgets/trip_card.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _tripService.getAllTrips();
      setState(() {
        _trips = trips;
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

  void _createNewTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
    ).then((_) => _loadTrips());
  }

  void _viewTripDetails(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailScreen(trip: trip),
      ),
    ).then((_) => _loadTrips());
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le voyage'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${trip.title}"?'),
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
        await _tripService.deleteTrip(trip.id!);
        _loadTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voyage supprimé avec succès')),
        );
      } catch (e) {
        _showError('Erreur de suppression: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Voyages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTrip,
            tooltip: 'Créer un nouveau voyage',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? _buildEmptyState()
          : _buildTripsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTrip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'Aucun voyage créé',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Commencez par créer votre premier voyage !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createNewTrip,
            icon: const Icon(Icons.add),
            label: const Text('Créer mon premier voyage'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return TripCard(
          trip: trip,
          onTap: () => _viewTripDetails(trip),
          onDelete: () => _deleteTrip(trip),
        );
      },
    );
  }
}