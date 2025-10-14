import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper_new.dart';

class ReclamationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reclamation;

  const ReclamationDetailScreen({
    super.key,
    required this.reclamation,
  });

  // Helper method to safely get string values
  String _getString(String key, {String defaultValue = ''}) {
    final value = reclamation[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ReclamationDetailScreen');
    debugPrint('Reclamation data: $reclamation');
    
    // Ensure we have valid data
    if (reclamation.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No reclamation data available'),
        ),
      );
    }
    // Safely extract data using our helper method
    final subject = _getString(DatabaseHelper.columnSubject, defaultValue: 'No Subject');
    final message = _getString(DatabaseHelper.columnMessage, defaultValue: 'No Message');
    final status = _getString(DatabaseHelper.columnStatus, defaultValue: 'No Status');
    final response = _getString('response', defaultValue: 'No response yet');
    final name = _getString(DatabaseHelper.columnName, defaultValue: 'Not provided');
    final email = _getString(DatabaseHelper.columnEmail, defaultValue: 'Not provided');
    
    final theme = Theme.of(context);
    final dateStr = _getString(DatabaseHelper.columnDate);
    final date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
    final formattedDate = date != null
        ? DateFormat('MMM d, y • HH:mm').format(date)
        : 'No date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclamation Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a rebuild by popping and pushing
              Navigator.pop(context);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
            Row(
              children: [
                _buildStatusChip(status),
                const SizedBox(width: 12),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Subject
            Text(
              'Subject',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subject,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Message
            Text(
              'Message',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
            ),
            
            // Attachment (if exists)
            if (reclamation[DatabaseHelper.columnAttachment] != null &&
                reclamation[DatabaseHelper.columnAttachment].toString().isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Pièce jointe',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(reclamation[DatabaseHelper.columnAttachment]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            
            // Response (if exists)
            if (response.isNotEmpty && response != 'No response yet' && response != '') ...[
              const SizedBox(height: 24),
              Text(
                'Response',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  response,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            
            // Contact Info
            const SizedBox(height: 32),
            Text(
              'Contact Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.person_outline,
              label: 'Name',
              value: name,
            ),
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'new':
        chipColor = Colors.blue;
        statusText = 'New';
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case 'resolved':
        chipColor = Colors.green;
        statusText = 'Resolved';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.lerp(chipColor, Colors.white, 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.lerp(chipColor, Colors.black, 0.3) ?? chipColor,
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
