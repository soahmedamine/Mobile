import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/trip_model.dart';
import '../../../models/place_model.dart';
import '../services/trip_service.dart';
import '../services/itinerary_service.dart';
import 'map_explorer_screen.dart';
import 'edit_trip_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);
//dont pull my commits 
  @override
  _TripDetailScreenState createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();
  final ItineraryService _itineraryService = ItineraryService();

  List<Place> _places = [];
  bool _isLoading = true;
  List<ll.LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      final places = await _tripService.getTripPlaces(widget.trip.id!);

      setState(() {
        _places = _itineraryService.optimizeItinerary(places);
        _isLoading = false;
      });

      // Fetch ORS route if we have at least a start and end and a configured key
      await _fetchRouteFromOpenRouteService();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur de chargement: $e');
    }
  }

  Future<ll.LatLng?> _geocodeDestination(String destinationName) async {
    final apiKey = dotenv.env['ORS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final uri = Uri.parse('https://api.openrouteservice.org/geocode/search?api_key=$apiKey&text=$destinationName&size=1');

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = json['features'] as List<dynamic>;
        if (features.isNotEmpty) {
          final coords = features[0]['geometry']['coordinates'] as List<dynamic>;
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          debugPrint('Geocoded "$destinationName" to: $lat, $lon');
          return ll.LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('Geocoding exception: $e');
    }
    return null;
  }

  Future<void> _fetchRouteFromOpenRouteService() async {

    final apiKey = dotenv.env['ORS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // No key configured; skip remote directions
      return;
    }

    // Geocode the destination name to get coordinates
    final destinationCoords = await _geocodeDestination(widget.trip.destination);
    if (destinationCoords == null) {
      debugPrint('Could not geocode destination. No route will be shown.');
      return;
    }

    // Route always starts from Tunis and ends at the trip's main destination.
    const tunisLongitude = 10.1815;
    const tunisLatitude = 36.8065;

    final start = '$tunisLongitude,$tunisLatitude';
    final end = '${destinationCoords.longitude},${destinationCoords.latitude}';
    debugPrint('--- Fetching ORS Route ---');
    debugPrint('Start: $start');
    debugPrint('End: $end');
    final uri = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$start&end=$end');

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = json['features'] as List<dynamic>;
        if (features.isNotEmpty) {
          final coords = (features[0]['geometry']['coordinates'] as List)
              .cast<List>();
          final pts = <ll.LatLng>[];
          for (final c in coords) {
            if (c.length >= 2) {
              final lon = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              pts.add(ll.LatLng(lat, lon));
            }
          }
          setState(() => _routePoints = pts);
          debugPrint('Successfully fetched ${_routePoints.length} route points.');
        }
      } else {
        debugPrint('ORS error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('ORS exception: $e');
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

  @override
  Widget build(BuildContext context) {
    final daysDifference = widget.trip.endDate.difference(widget.trip.startDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        iconTheme: IconThemeData(color: Colors.blue), // Back button
        actions: [
          IconButton(
            icon: const Icon(Icons.explore, color: Colors.blue),
            onPressed: _navigateToMapExplorer,
            tooltip: 'Explorer sur la carte',
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: _navigateToEditTrip,
            tooltip: 'Modifier le voyage',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Du ${_formatDate(widget.trip.startDate)} au ${_formatDate(widget.trip.endDate)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Durée: $daysDifference jours',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          if (widget.trip.description != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              widget.trip.description!,
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Map Section
                  Container(
                    height: 400,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPlacesMap(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Download PDF Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Télécharger le PDF du voyage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _downloadPdf() async {
    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération du PDF en cours...'), duration: Duration(seconds: 2)),
      );

      // Generate PDF
      final pdf = pw.Document();
      final placesSorted = [..._places]..sort((a, b) => a.visitDate.compareTo(b.visitDate));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              'Résumé du Voyage',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            pw.Text(
              widget.trip.title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Icon(pw.IconData(0xe0b7), size: 16),
                pw.SizedBox(width: 8),
                pw.Text('Destination: ${widget.trip.destination}', style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Icon(pw.IconData(0xe192), size: 16),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Période: ${_formatDate(widget.trip.startDate)} - ${_formatDate(widget.trip.endDate)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Icon(pw.IconData(0xe192), size: 16),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Durée: ${widget.trip.endDate.difference(widget.trip.startDate).inDays} jours',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (widget.trip.description != null) ...[
              pw.SizedBox(height: 12),
              pw.Text('Description:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 4),
              pw.Text(widget.trip.description!, style: const pw.TextStyle(fontSize: 12)),
            ],
            pw.SizedBox(height: 24),
            pw.Text(
              'Lieux visités (${placesSorted.length})',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
            ),
            pw.SizedBox(height: 12),
            if (placesSorted.isEmpty)
              pw.Text('Aucun lieu enregistré.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))
            else
              pw.Table.fromTextArray(
                headers: ['#', 'Nom', 'Type', 'Date de visite', 'Coordonnées'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                data: [
                  for (int i = 0; i < placesSorted.length; i++)
                    [
                      '${i + 1}',
                      placesSorted[i].name,
                      placesSorted[i].type,
                      _formatDate(placesSorted[i].visitDate),
                      '${placesSorted[i].latitude.toStringAsFixed(4)}, ${placesSorted[i].longitude.toStringAsFixed(4)}',
                    ],
                ],
              ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Généré le ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      );

      // Save PDF to app storage
      final directory = await getApplicationDocumentsDirectory();
      final pdfsDir = Directory('${directory.path}/PDFs');
      if (!await pdfsDir.exists()) {
        await pdfsDir.create(recursive: true);
      }

      final fileName = 'voyage_${widget.trip.title.replaceAll(' ', '_')}.pdf';
      final file = File('${pdfsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // ✅ SHARE THE PDF IMMEDIATELY
      if (!mounted) return;

      // Share the PDF file
      await _sharePdfFile(file);

    } catch (e) {
      _showError('Erreur lors de la génération du PDF: $e');
    }
  }

// ✅ ADD THIS NEW METHOD FOR SHARING
  Future<void> _sharePdfFile(File file) async {
    try {
      // Create a temporary file in a shareable location
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.uri.pathSegments.last}');
      await tempFile.writeAsBytes(await file.readAsBytes());

      // Use the share_plus package to share the file
      // First add this import: import 'package:share_plus/share_plus.dart';
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Résumé de mon voyage: ${widget.trip.title}',
        subject: 'Voyage ${widget.trip.title}',
      );

    } catch (e) {
      // If sharing fails, show success message without share
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF généré avec succès!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint('PDF saved to: ${file.path}');
    }
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
          userAgentPackageName: 'com.example.smart_travel_weather_app',
          maxZoom: 19,
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 4),
            ],
          )
        else if (points.length >= 2)
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
            TextSourceAttribution('Wikimedia | © OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}