import 'package:flutter/material.dart';
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
          itemCount: _reclamations.length,
          itemBuilder: (context, index) {
            final rec = _reclamations[index];
            return ListTile(
              title: Text(rec[DatabaseHelper.columnSubject] ?? ''),
              subtitle: Text(rec[DatabaseHelper.columnMessage] ?? ''),
              trailing: Text(
                DateFormat('dd/MM/yyyy').format(
                  DateTime.parse(rec[DatabaseHelper.columnDate]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
