import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper_new.dart';
import 'reclamation_detail_screen.dart';
import 'reclamation_form_screen.dart';
import 'home_screen.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          tooltip: 'Back to Home',
        ),
        title: const Text(
          'Mes Réclamations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReclamations,
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _reclamations.isEmpty
                  ? _buildEmptyState()
                  : _buildReclamationsList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReclamationFormScreen(),
            ),
          ).then((_) {
            _loadReclamations();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 6,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune Réclamation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vos réclamations apparaîtront ici',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loadReclamations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: Icon(Icons.refresh, color: Colors.blue[700]),
                label: Text(
                  'Actualiser',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReclamationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reclamations.length,
      itemBuilder: (context, index) {
        final reclamation = _reclamations[index];
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
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildStatusChip(reclamation[DatabaseHelper.columnStatus]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reclamation[DatabaseHelper.columnMessage] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reclamation[DatabaseHelper.columnDate] != null
                              ? DateFormat('MMM d, y').format(
                                  DateTime.parse(reclamation[DatabaseHelper.columnDate]))
                              : 'No date',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    String statusText;
    switch (status) {
      case 'new':
        chipColor = Colors.blue;
        statusText = 'Nouveau';
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        statusText = 'En cours';
        break;
      case 'resolved':
        chipColor = Colors.green;
        statusText = 'Résolu';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
