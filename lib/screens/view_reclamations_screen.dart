import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper_new.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_form_screen.dart';
import '../widgets/app_drawer.dart';

class ViewReclamationsScreen extends StatefulWidget {
  const ViewReclamationsScreen({super.key});

  @override
  State<ViewReclamationsScreen> createState() => _ViewReclamationsScreenState();
}

class _ViewReclamationsScreenState extends State<ViewReclamationsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reclamations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the database is initialized
    Future.delayed(Duration.zero, _loadReclamations);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the screen is shown again
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    if (kDebugMode) {
      print('Loading reclamations...');
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Ensure database is initialized
      if (!_dbHelper.isInitialized) {
        await _dbHelper.init();
      }
      
      // Print all stored keys for debugging
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      print('All keys in SharedPreferences: $allKeys');
      
      // Get all reclamations
      final reclamations = await _dbHelper.getReclamations();
      
      if (kDebugMode) {
        print('Successfully loaded ${reclamations.length} reclamations');
        for (var r in reclamations) {
          print('Reclamation: ${r['id']} - ${r['subject']} - Status: ${r['status']}');
        }
      }
      
      if (mounted) {
        setState(() {
          _reclamations = reclamations;
        });
      }
    } catch (e, stackTrace) {
      final error = 'Failed to load reclamations: $e\n$stackTrace';
      print(error);
      if (mounted) {
        _showError('Failed to load reclamations. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    if (kDebugMode) {
      print('Error: $message');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${message.split('\n').first}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadReclamations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                size: 28,
                color: Colors.indigo,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Menu',
            ),
          ),
        ),
        title: const Text('All Reclamations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReclamations,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reclamations.isEmpty
              ? _buildEmptyState()
              : _buildReclamationsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReclamationFormScreen(),
            ),
          ).then((_) {
            // Refresh the list after returning from the form
            _loadReclamations();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('New Reclamation'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Reclamations Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadReclamations,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(height: 16),
          Text(
            'If you just added a reclamation, try refreshing the list.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReclamationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reclamations.length,
      itemBuilder: (context, index) {
        final reclamation = _reclamations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () async {
              debugPrint('Tapped reclamation: ${reclamation[DatabaseHelper.columnId]}');
              try {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReclamationDetailScreen(
                      reclamation: Map<String, dynamic>.from(reclamation),
                    ),
                  ),
                );
                debugPrint('Returned from detail screen');
                await _loadReclamations();
              } catch (e) {
                debugPrint('Navigation error: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error opening details')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reclamation[DatabaseHelper.columnSubject] ?? 'No Subject',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildStatusChip(reclamation[DatabaseHelper.columnStatus]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reclamation[DatabaseHelper.columnMessage] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reclamation[DatabaseHelper.columnDate] != null
                            ? DateFormat('MMM d, y').format(
                                DateTime.parse(reclamation[DatabaseHelper.columnDate]))
                            : 'No date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'View Details',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    switch (status) {
      case 'new':
        chipColor = Colors.blue;
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        break;
      case 'resolved':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.lerp(chipColor, Colors.white, 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.lerp(chipColor, Colors.black, 0.3) ?? chipColor),
      ),
      child: Text(
        status?.replaceAll('_', ' ') ?? 'unknown',
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
