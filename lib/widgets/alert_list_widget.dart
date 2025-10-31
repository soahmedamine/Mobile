import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';

class AlertListWidget extends StatefulWidget {
  const AlertListWidget({Key? key}) : super(key: key);

  @override
  State<AlertListWidget> createState() => _AlertListWidgetState();
}

class _AlertListWidgetState extends State<AlertListWidget> {
  late final AlertProvider _alertProvider;

  @override
  void initState() {
    super.initState();
    _alertProvider = Provider.of<AlertProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertModel>>(
      stream: _alertProvider.alertsStream,
      initialData: const [],
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        
        if (alerts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No new alerts',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length > 3 ? 3 : alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertItem(context, alert);
          },
        );
      },
    );
  }
  
  Widget _buildAlertItem(BuildContext context, AlertModel alert) {
    final timeAgo = _formatTimeAgo(alert.timestamp);
    final iconData = _getIconForType(alert.type);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconData.color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData.icon, color: iconData.color, size: 20),
        ),
        title: Text(
          alert.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${alert.message} • $timeAgo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        onTap: () => _showAlertDetails(context, alert, _alertProvider),
      ),
    );
  }
  
  ({IconData icon, Color color}) _getIconForType(String type) {
    switch (type) {
      case 'event':
        return (icon: Icons.event, color: Colors.blue);
      case 'logement':
        return (icon: Icons.hotel, color: Colors.green);
      case 'note':
        return (icon: Icons.note, color: Colors.purple);
      case 'info':
        return (icon: Icons.info, color: Colors.blue);
      default:
        return (icon: Icons.notifications, color: Colors.grey);
    }
  }
  
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  void _showAlertDetails(BuildContext context, AlertModel alert, AlertProvider alertProvider) {
    final iconData = _getIconForType(alert.type);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconData.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData.icon,
                    color: iconData.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 8),
            Divider(height: 24, color: Colors.grey[300]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatFullDate(alert.timestamp)} • ${alert.type.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    alertProvider.markAsRead(alert.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Mark as read'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  String _formatFullDate(DateTime date) {
    return DateFormat('MMM d, y • hh:mm a').format(date);
  }
}
