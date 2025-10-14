import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper_new.dart';
import 'chat_screen_new.dart';
import '../widgets/app_drawer.dart';
import 'admin_response_screen.dart';

class ReclamationListScreen extends StatefulWidget {
  const ReclamationListScreen({super.key});

  @override
  State<ReclamationListScreen> createState() => _ReclamationListScreenState();
}

class _ReclamationListScreenState extends State<ReclamationListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _reclamations = [];
  bool _isLoading = true;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    setState(() => _isLoading = true);
    try {
      final reclamations = await _dbHelper.getReclamations();
      if (mounted) setState(() => _reclamations = reclamations);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
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
          title: const Text('Liste des Réclamations'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
              tooltip: 'Assistance',
            ),
            IconButton(
              icon: const Icon(Icons.travel_explore),
              tooltip: 'Culture & Infos Locales',
              onPressed: () => Navigator.pushNamed(context, '/culture'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: _logout,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reclamations.isEmpty
            ? const Center(child: Text('Aucune réclamation enregistrée'))
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _reclamations.length,
          itemBuilder: (context, index) {
            final rec = _reclamations[index];
            final status = rec[DatabaseHelper.columnStatus] ?? 'new';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: _buildStatusIcon(status),
                title: Text(
                  rec[DatabaseHelper.columnSubject] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      rec[DatabaseHelper.columnMessage] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          rec[DatabaseHelper.columnName] ?? 'Unknown',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(status),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(
                        DateTime.parse(rec[DatabaseHelper.columnDate]),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminResponseScreen(reclamation: rec),
                    ),
                  );
                  if (result == true) {
                    _loadReclamations(); // Reload after response saved
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'new':
        icon = Icons.fiber_new;
        color = Colors.blue;
        break;
      case 'in_progress':
        icon = Icons.pending;
        color = Colors.orange;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'new':
        color = Colors.blue;
        label = 'Nouveau';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'En cours';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Résolu';
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
