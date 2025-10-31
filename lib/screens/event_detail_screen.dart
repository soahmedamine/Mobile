import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/event_card.dart';
import 'event_form_screen.dart';
import 'home_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.event, this.isAdmin = false});

  final Event event;
  final bool isAdmin;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _toggleFavorite() async {
    final newFavorite = !_event.isFavorite;
    setState(() {
      _event = _event.copyWith(isFavorite: newFavorite);
    });
    if (_event.id != null) {
      await _eventService.setFavorite(_event.id!, newFavorite);
    } else if (_event.remoteId != null) {
      await _eventService.setFavoriteByRemoteId(_event.remoteId!, newFavorite);
    }
  }

  Future<void> _toggleActive() async {
    if (_event.id == null) {
      return;
    }
    final newActive = !_event.isActive;
    await _eventService.setActive(_event.id!, newActive);
    setState(() {
      _event = _event.copyWith(isActive: newActive);
    });
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: _event),
      ),
    );
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEvent() async {
    if (_event.id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      await _eventService.deleteEvent(_event.id!);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    }
  }

  Future<void> _launchExternalUrl() async {
    if (_event.externalUrl == null || _event.externalUrl!.isEmpty) {
      return;
    }
    final uri = Uri.parse(_event.externalUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMEEEEd('fr');
    final timeFormat = DateFormat.Hm('fr');
    final priceFormat = NumberFormat.simpleCurrency(
      locale: 'fr_FR',
      name: _event.currency ?? 'EUR',
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Détails de l\'événement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _event.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') _editEvent();
              if (value == 'delete') _deleteEvent();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[800]!,
              Colors.blue[500]!,
              Colors.blue[200]!,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EventCard(
                event: _event,
                showFavorite: false,
              ),
              const SizedBox(height: 20),
              if (_event.description != null && _event.description!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _event.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_event.description != null && _event.description!.isNotEmpty)
                const SizedBox(height: 16),
              if (_event.startDate != null)
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Date',
                  value: '${dateFormat.format(_event.startDate!)} • ${timeFormat.format(_event.startDate!)}',
                ),
              if (_event.endDate != null)
                _InfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Fin',
                  value: '${dateFormat.format(_event.endDate!)} • ${timeFormat.format(_event.endDate!)}',
                ),
              if (_event.city != null || _event.venue != null)
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Lieu',
                  value: [
                    if (_event.venue != null && _event.venue!.isNotEmpty) _event.venue,
                    if (_event.city != null && _event.city!.isNotEmpty) _event.city,
                  ].whereType<String>().join(' • '),
                ),
              if (_event.category != null && _event.category!.isNotEmpty)
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: 'Catégorie',
                  value: _event.category!,
                ),
              if (_event.price != null)
                _InfoRow(
                  icon: Icons.local_offer_outlined,
                  label: 'Prix',
                  value: priceFormat.format(_event.price),
                ),
              const SizedBox(height: 20),
              if (_event.externalUrl != null && _event.externalUrl!.isNotEmpty)
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _launchExternalUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Icon(Icons.open_in_new, color: Colors.blue[700]),
                    label: Text(
                      'Voir l\'événement en ligne',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
