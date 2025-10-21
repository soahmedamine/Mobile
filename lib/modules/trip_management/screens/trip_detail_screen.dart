import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
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
    _showAddPlaceSheet();
  }

  void _showAddPlaceSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'attraction');
    final priceCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    DateTime visitDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ajouter un Lieu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: 'Type (hotel, restaurant, attraction, ...)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latCtrl,
                          decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (v) => (double.tryParse(v ?? '') == null) ? 'Latitude invalide' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lngCtrl,
                          decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (v) => (double.tryParse(v ?? '') == null) ? 'Longitude invalide' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Prix (optionnel)', border: OutlineInputBorder(), prefixText: '\$'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: visitDate,
                        firstDate: widget.trip.startDate,
                        lastDate: widget.trip.endDate,
                      );
                      if (picked != null) {
                        setState(() {
                          visitDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de visite',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(visitDate)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer le Lieu'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final lat = double.tryParse(latCtrl.text);
                        final lon = double.tryParse(lngCtrl.text);
                        if (lat == null || lon == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir une latitude et une longitude valides.')),
                          );
                          return;
                        }

                        try {
                          final place = Place(
                            name: nameCtrl.text,
                            address: addressCtrl.text,
                            latitude: lat,
                            longitude: lon,
                            type: typeCtrl.text,
                            price: priceCtrl.text.isEmpty ? null : double.tryParse(priceCtrl.text),
                            tripId: widget.trip.id!,
                            visitDate: visitDate,
                            rating: null,
                            notes: null,
                          );

                          await _tripService.addPlace(place);
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          await _loadTripData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lieu ajouté')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      },
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

  @override
  Widget build(BuildContext context) {
    final daysDifference = widget.trip.endDate.difference(widget.trip.startDate).inDays;

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

          // Embedded Map: OpenStreetMap via flutter_map (markers + polyline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPlacesMap(),
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

  // Embedded OSM map with markers and polyline built from _places
  Widget _buildPlacesMap() {
    // Build points in visit order
    final sorted = [..._places]..sort((a, b) => a.visitDate.compareTo(b.visitDate));
    final points = sorted.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();

    // Compute center
    ll.LatLng center;
    if (points.isEmpty) {
      center = const ll.LatLng(36.8065, 10.1815); // Tunis default
    } else {
      final avgLat = points.map((e) => e.latitude).reduce((a, b) => a + b) / points.length;
      final avgLng = points.map((e) => e.longitude).reduce((a, b) => a + b) / points.length;
      center = ll.LatLng(avgLat, avgLng);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: points.length <= 1 ? 12 : 8,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'smart_travel_weather_app',
          maxZoom: 19,
        ),
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: points, color: Colors.blue, strokeWidth: 4),
            ],
          ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: sorted
                .map((p) => Marker(
                      point: ll.LatLng(p.latitude, p.longitude),
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.place, color: Colors.red),
                    ))
                .toList(),
          ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}