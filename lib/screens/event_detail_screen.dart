import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/event_card.dart';
import 'event_form_screen.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Détails de l\'événement'),
        actions: [
          IconButton(
            icon: Icon(_event.isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
          if (widget.isAdmin && _event.id != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editEvent,
            ),
          if (widget.isAdmin && _event.id != null)
            IconButton(
              icon: Icon(_event.isActive ? Icons.pause : Icons.play_arrow),
              onPressed: _toggleActive,
            ),
          if (widget.isAdmin && _event.id != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EventCard(
            event: _event,
            showFavorite: false,
          ),
          if (_event.description != null && _event.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _event.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (_event.startDate != null)
            _InfoRow(
              icon: Icons.event,
              label: 'Date',
              value: '${dateFormat.format(_event.startDate!)} • ${timeFormat.format(_event.startDate!)}',
            ),
          if (_event.endDate != null)
            _InfoRow(
              icon: Icons.event_available,
              label: 'Fin',
              value: '${dateFormat.format(_event.endDate!)} • ${timeFormat.format(_event.endDate!)}',
            ),
          if (_event.city != null || _event.venue != null)
            _InfoRow(
              icon: Icons.place,
              label: 'Lieu',
              value: [
                if (_event.venue != null && _event.venue!.isNotEmpty) _event.venue,
                if (_event.city != null && _event.city!.isNotEmpty) _event.city,
              ].whereType<String>().join(' • '),
            ),
          if (_event.category != null && _event.category!.isNotEmpty)
            _InfoRow(
              icon: Icons.category,
              label: 'Catégorie',
              value: _event.category!,
            ),
          if (_event.price != null)
            _InfoRow(
              icon: Icons.attach_money,
              label: 'Prix',
              value: priceFormat.format(_event.price),
            ),
          const SizedBox(height: 20),
          if (_event.externalUrl != null && _event.externalUrl!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _launchExternalUrl,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Voir l\'événement en ligne'),
            ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
