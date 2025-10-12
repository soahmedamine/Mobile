import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'view_reclamations_screen.dart';
import 'chat_screen_new.dart';
import '../widgets/app_drawer.dart';

class ReclamationListScreen extends StatefulWidget {
  const ReclamationListScreen({super.key});

  @override
  State<ReclamationListScreen> createState() => _ReclamationListScreenState();
}

class _ReclamationListScreenState extends State<ReclamationListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reclamations = [];
  bool _isLoading = true;
  static const List<String> _statusOptions = ['new', 'in_progress', 'resolved'];

  // Méthode pour gérer la déconnexion
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    if (kDebugMode) {
      print('⏳ Loading reclamations...');
      print('Current state: ${_reclamations.isEmpty ? 'No reclamations' : 'Has reclamations'}');
    }
    
    setState(() {
      _isLoading = true;
      if (kDebugMode) {
        print('🔄 Set _isLoading to true');
      }
    });
    
    try {
      if (kDebugMode) {
        print('📞 Calling _dbHelper.getReclamations()...');
      }
      
      final reclamations = await _dbHelper.getReclamations();
      
      if (!mounted) {
        if (kDebugMode) {
          print('🚫 Widget not mounted, returning early');
        }
        return;
      }
      
      if (kDebugMode) {
        print('✅ Successfully retrieved ${reclamations.length} reclamations');
        if (reclamations.isNotEmpty) {
          print('📋 First reclamation: ${reclamations.first[DatabaseHelper.columnSubject]}');
        }
      }
      
      setState(() {
        _reclamations = reclamations;
        if (kDebugMode) {
          print('🔄 Updated _reclamations with ${_reclamations.length} items');
          print('🔍 Current state: ${_reclamations.isEmpty ? 'No reclamations' : 'Has reclamations'}');
        }
      });
    } catch (e, stackTrace) {
      final errorMessage = 'Failed to load reclamations: $e';
      if (kDebugMode) {
        print(errorMessage);
        print('Stack trace: $stackTrace');
      }
      
      if (!mounted) return;
      
      // Show error in the UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  _loadReclamations();
                }
              },
            ),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (kDebugMode) {
            print('Loading complete. _isLoading set to false');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Réclamations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            tooltip: 'Assistance',
          ),
          // Bouton pour voir toutes les réclamations
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewReclamationsScreen(),
                ),
              ).then((_) {
                if (mounted) {
                  _loadReclamations();
                }
              });
            },
            tooltip: 'Voir toutes les réclamations',
          ),
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reclamations.isEmpty
              ? _buildEmptyState()
              : _buildReclamationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Reclamations Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new reclamation',
            style: TextStyle(color: Colors.grey[500]),
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
        return _buildReclamationCard(reclamation);
      },
    );
  }

  Widget _buildReclamationCard(Map<String, dynamic> reclamation) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReclamationDetails(reclamation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reclamation[DatabaseHelper.columnSubject] ?? 'No Subject',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(reclamation[DatabaseHelper.columnStatus]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reclamation[DatabaseHelper.columnMessage] ?? '',
                style: const TextStyle(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((reclamation[DatabaseHelper.columnResponse] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reclamation[DatabaseHelper.columnResponse] ?? '',
                        style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            reclamation[DatabaseHelper.columnName] ?? 'Anonymous',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _formatDate(reclamation[DatabaseHelper.columnDate]),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color chipColor;
    String statusText;

    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          chipColor.red,
          chipColor.green,
          chipColor.blue,
          0.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showReclamationDetails(Map<String, dynamic> reclamation) {
    if (!mounted) return;
    
    final parentContext = context;
    final responseController = TextEditingController(
      text: reclamation[DatabaseHelper.columnResponse]?.toString() ?? '',
    );
    String selectedStatus = reclamation[DatabaseHelper.columnStatus]?.toString() ?? 'new';

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(innerContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            reclamation[DatabaseHelper.columnSubject] ?? 'No Subject',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusChip(selectedStatus),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reclamation[DatabaseHelper.columnMessage] ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Response',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        // La mise à jour du contrôleur est gérée automatiquement
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.person_outline,
                      reclamation[DatabaseHelper.columnName] ?? 'Anonymous',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.email_outlined,
                      reclamation[DatabaseHelper.columnEmail] ?? 'No email',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      _formatDate(reclamation[DatabaseHelper.columnDate]),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Récupérer d'abord la réclamation existante
                              final existingReclamation = await _dbHelper.getReclamation(reclamation[DatabaseHelper.columnId]);
                              if (existingReclamation == null) return;
                              
                              // Mettre à jour les champs nécessaires
                              existingReclamation[DatabaseHelper.columnStatus] = selectedStatus;
                              existingReclamation[DatabaseHelper.columnResponse] = responseController.text.trim();
                              
                              // Mettre à jour la réclamation
                              final result = await _dbHelper.updateReclamation(existingReclamation);
                              if (!mounted) return;
                              if (result > 0) {
                                Navigator.pop(sheetContext);
                                _loadReclamations();
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reclamation updated'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update reclamation'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteDialog(
                            reclamation[DatabaseHelper.columnId],
                            parentContext,
                            sheetContext,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: Colors.red[50],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(
    String id,
    BuildContext parentContext,
    BuildContext sheetContext,
  ) async {
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reclamation'),
        content: const Text('Are you sure you want to delete this reclamation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _dbHelper.deleteReclamation(id);
      if (!mounted) return;
      
      if (result > 0) {
        Navigator.pop(sheetContext);
        _loadReclamations();
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Reclamation deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete reclamation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'No date';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, y • hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}
