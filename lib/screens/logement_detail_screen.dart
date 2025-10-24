import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/logement.dart';
import '../services/maps_service.dart';
import '../services/logement_service.dart';
import '../services/image_service.dart';
import '../widgets/app_drawer.dart';
import 'logement_form_screen.dart';

class LogementDetailScreen extends StatefulWidget {
  final Logement logement;

  const LogementDetailScreen({super.key, required this.logement});

  @override
  State<LogementDetailScreen> createState() => _LogementDetailScreenState();
}

class _LogementDetailScreenState extends State<LogementDetailScreen> {
  final MapsService _mapsService = MapsService();
  final LogementService _logementService = LogementService();
  final ImageService _imageService = ImageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[500]!, Colors.blue[200]!],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar moderne
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.logement.nom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8.0,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.logement.imageUrl != null
                        ? _buildHeaderImage(widget.logement.imageUrl!)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[400]!, Colors.blue[700]!],
                              ),
                            ),
                            child: const Icon(Icons.home, size: 100, color: Colors.white),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LogementFormScreen(logement: widget.logement),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showDeleteDialog(),
                ),
              ],
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type et note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(widget.logement.type),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getTypeLabel(widget.logement.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.logement.note != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 4),
                            Text(
                              widget.logement.note!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Prix
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prix par nuit',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.logement.prixParNuit.toStringAsFixed(0)} DT',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Caractéristiques
                  const Text(
                    'Caractéristiques',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.bed,
                          'Chambres',
                          widget.logement.nombreChambres.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.people,
                          'Capacité',
                          '${widget.logement.capacitePersonnes} pers.',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.logement.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Commodités
                  if (widget.logement.commodites.isNotEmpty) ...[
                    const Text(
                      'Commodités',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.logement.commodites.map((commodite) {
                        return Chip(
                          label: Text(commodite),
                          avatar: Icon(
                            _getCommoditeIcon(commodite),
                            size: 18,
                            color: Colors.teal,
                          ),
                          backgroundColor: Colors.teal[50],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Adresse
                  const Text(
                    'Adresse',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.logement.adresse,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Carte Interactive
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                widget.logement.latitude,
                                widget.logement.longitude,
                              ),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                userAgentPackageName: 'com.smarttravel.app',
                                additionalOptions: const {
                                  'attribution': '© OpenStreetMap contributors © CARTO',
                                },
                                maxNativeZoom: 20,
                                maxZoom: 20,
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: LatLng(
                                      widget.logement.latitude,
                                      widget.logement.longitude,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ElevatedButton.icon(
                              onPressed: () => _mapsService.openGoogleMaps(
                                widget.logement.latitude,
                                widget.logement.longitude,
                                widget.logement.nom,
                              ),
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Ouvrir dans Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.teal,
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact
                  if (widget.logement.telephone != null || widget.logement.email != null) ...[
                    const Text(
                      'Contact',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (widget.logement.telephone != null)
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.teal),
                        title: Text(widget.logement.telephone!),
                        trailing: const Icon(Icons.call),
                        onTap: () {
                          // Implémenter l'appel téléphonique
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (widget.logement.email != null)
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.teal),
                        title: Text(widget.logement.email!),
                        trailing: const Icon(Icons.send),
                        onTap: () {
                          // Implémenter l'envoi d'email
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité de réservation à venir')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réserver maintenant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String image) {
    if (_imageService.isBase64Image(image)) {
      final bytes = _imageService.getBase64ImageBytes(image);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.home, size: 100, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCommoditeIcon(String commodite) {
    final lower = commodite.toLowerCase();
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('piscine')) return Icons.pool;
    if (lower.contains('restaurant')) return Icons.restaurant;
    if (lower.contains('spa')) return Icons.spa;
    if (lower.contains('climatisation') || lower.contains('clim')) return Icons.ac_unit;
    if (lower.contains('cuisine')) return Icons.kitchen;
    if (lower.contains('jardin')) return Icons.grass;
    if (lower.contains('terrasse') || lower.contains('balcon')) return Icons.balcony;
    if (lower.contains('plage')) return Icons.beach_access;
    return Icons.check_circle;
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
        return type;
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

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le logement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce logement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logementService.deleteLogement(widget.logement.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logement supprimé')),
        );
      }
    }
  }
}
