import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/image_service.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onFavoriteToggle,
    this.trailing,
    this.showFavorite = true,
  });

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final Widget? trailing;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMEEEEd('fr');
    final timeFormat = DateFormat.Hm('fr');
    final priceFormat = NumberFormat.simpleCurrency(
      locale: 'fr_FR',
      name: event.currency ?? 'EUR',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (event.category != null && event.category!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Chip(
                                  label: Text(event.category!),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (showFavorite)
                        IconButton(
                          icon: Icon(
                            event.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: event.isFavorite ? Colors.red : theme.iconTheme.color,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (event.startDate != null)
                    Row(
                      children: [
                        const Icon(Icons.event, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateFormat.format(event.startDate!),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (event.startDate != null)
                          Text(
                            timeFormat.format(event.startDate!),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  if (event.startDate != null)
                    const SizedBox(height: 8),
                  if (event.city != null && event.city!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.place, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.city! + (event.venue != null && event.venue!.isNotEmpty ? ' • ${event.venue}' : ''),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  if (event.city != null && event.city!.isNotEmpty)
                    const SizedBox(height: 8),
                  if (event.price != null)
                    Text(
                      priceFormat.format(event.price),
                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.teal, fontWeight: FontWeight.w700),
                    ),
                  if (event.price == null)
                    Text(
                      'Tarif non communiqué',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  if (!event.isActive)
                    Row(
                      children: [
                        const Icon(Icons.pause_circle_filled, size: 18, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'Événement désactivé',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                        ),
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

  Widget _buildImage() {
    if (event.imageUrl == null || event.imageUrl!.isEmpty) {
      return Container(
        height: 180,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.event_available, size: 72, color: Colors.grey),
      );
    }

    final imageService = ImageService();
    if (imageService.isBase64Image(event.imageUrl)) {
      final bytes = imageService.getBase64ImageBytes(event.imageUrl!);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.network(
      event.imageUrl!,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.event_available, size: 72, color: Colors.grey),
        );
      },
    );
  }
}
