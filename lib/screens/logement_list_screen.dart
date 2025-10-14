import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/logement.dart';
import '../services/logement_service.dart';
import '../services/image_service.dart';
import '../widgets/app_drawer.dart';
import 'logement_detail_screen.dart';
import 'logement_form_screen.dart';

class LogementListScreen extends StatefulWidget {
  const LogementListScreen({super.key});

  @override
  State<LogementListScreen> createState() => _LogementListScreenState();
}

class _LogementListScreenState extends State<LogementListScreen> {
  final LogementService _logementService = LogementService();
  final ImageService _imageService = ImageService();
  List<Logement> _logements = [];
  List<Logement> _filteredLogements = [];
  bool _isLoading = true;
  String _selectedType = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['Tous', 'hotel', 'airbnb', 'appartement', 'maison'];

  @override
  void initState() {
    super.initState();
    _loadLogements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogements() async {
    setState(() => _isLoading = true);
    try {
      final logements = await _logementService.getLogementsDisponibles();
      setState(() {
        _logements = logements;
        _filteredLogements = logements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _filterLogements() {
    setState(() {
      _filteredLogements = _logements.where((logement) {
        final matchesType = _selectedType == 'Tous' || logement.type == _selectedType;
        final matchesSearch = _searchController.text.isEmpty ||
            logement.nom.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            logement.adresse.toLowerCase().contains(_searchController.text.toLowerCase());
        return matchesType && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logements Disponibles'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogements,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un logement...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => _filterLogements(),
            ),
          ),

          // Filtres par type
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                        _filterLogements();
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.teal[100],
                    checkmarkColor: Colors.teal,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Liste des logements
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogements.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLogements.length,
                        itemBuilder: (context, index) {
                          return _buildLogementCard(_filteredLogements[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LogementFormScreen(),
            ),
          );
          if (result == true) {
            _loadLogements();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildLogementCard(Logement logement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogementDetailScreen(logement: logement),
            ),
          );
          if (result == true) {
            _loadLogements();
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: logement.imageUrl != null
                  ? _buildImageWidget(logement.imageUrl!)
                  : Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 80, color: Colors.grey),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(logement.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTypeLabel(logement.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nom
                  Text(
                    logement.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Note
                  if (logement.note != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          logement.note!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Adresse
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          logement.adresse,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Caractéristiques
                  Row(
                    children: [
                      _buildFeature(Icons.bed, '${logement.nombreChambres} ch.'),
                      const SizedBox(width: 16),
                      _buildFeature(Icons.people, '${logement.capacitePersonnes} pers.'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${logement.prixParNuit.toStringAsFixed(0)} DT / nuit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String image) {
    if (_imageService.isBase64Image(image)) {
      final bytes = _imageService.getBase64ImageBytes(image);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.network(
      image,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 200,
        color: Colors.grey[300],
        child: const Icon(Icons.home, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun logement trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'hotel':
        return 'Hôtel';
      case 'airbnb':
        return 'Airbnb';
      case 'appartement':
        return 'Appartement';
      case 'maison':
        return 'Maison';
      default:
        return 'Tous';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'hotel':
        return Colors.blue;
      case 'airbnb':
        return Colors.pink;
      case 'appartement':
        return Colors.orange;
      case 'maison':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
