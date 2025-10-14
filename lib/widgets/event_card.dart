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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (event.category != null && event.category!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                                  ),
                                  child: Text(
                                    event.category!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (showFavorite)
                        IconButton(
                          icon: Icon(
                            event.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: event.isFavorite ? Colors.red : Colors.white,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (event.startDate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateFormat.format(event.startDate!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (event.startDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                timeFormat.format(event.startDate!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (event.startDate != null)
                    const SizedBox(height: 12),
                  if (event.city != null && event.city!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.place, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.city! + (event.venue != null && event.venue!.isNotEmpty ? ' • ${event.venue}' : ''),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (event.city != null && event.city!.isNotEmpty)
                    const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF0F0F0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          event.price != null
                              ? priceFormat.format(event.price)
                              : 'Tarif non communiqué',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!event.isActive)
                    Row(
                      children: [
                        const Icon(Icons.pause_circle_filled, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Événement désactivé',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (event.imageUrl == null || event.imageUrl!.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[300]!, Colors.blue[600]!],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.event_available, size: 80, color: Colors.white),
      );
    }

    final imageService = ImageService();
    if (imageService.isBase64Image(event.imageUrl)) {
      final bytes = imageService.getBase64ImageBytes(event.imageUrl!);
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
      event.imageUrl!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[300]!, Colors.blue[600]!],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.event_available, size: 80, color: Colors.white),
        );
      },
    );
  }
}
