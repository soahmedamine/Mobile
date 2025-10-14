import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/travel_screen.dart';
import '../screens/reclamation_form_screen.dart';
import '../screens/reclamation_list_screen.dart';
import '../screens/view_reclamations_screen.dart';
import '../screens/chat_screen_new.dart';
import '../screens/logement_list_screen.dart';
import '../screens/culture_module_screen.dart';
import '../screens/event_list_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userRole = 'user';
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'user';
      _userName = prefs.getString('user_name') ?? 'Utilisateur';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context); // Fermer le drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du drawer
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userRole == 'admin' ? 'Administrateur' : 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text('Accueil'),
              onTap: () => _navigateTo(const HomeScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.lightBlue),
              title: const Text('Météo'),
              onTap: () => _navigateTo(const WeatherScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.travel_explore, color: Colors.orange),
              title: const Text('Voyages'),
              onTap: () => _navigateTo(const TravelScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.hotel, color: Colors.deepOrange),
              title: const Text('Logements'),
              onTap: () => _navigateTo(const LogementListScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('Chat AI'),
              onTap: () => _navigateTo(const ChatScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.travel_explore, color: Colors.black),
              title: const Text('Culture & Infos Locales'),
              onTap: () => _navigateTo(const CultureModuleScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.event, color: Colors.deepPurple),
              title: const Text('Événements'),
              onTap: () => _navigateTo(const EventListScreen()),
            ),
            const Divider(height: 1),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Réclamations',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 5),

            ListTile(
              leading: const Icon(Icons.add_comment, color: Colors.purple),
              title: const Text('Nouvelle réclamation'),
              onTap: () => _navigateTo(const ReclamationFormScreen()),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.indigo),
              title: const Text('Mes réclamations'),
              onTap: () => _navigateTo(const ViewReclamationsScreen()),
            ),
            const Divider(height: 1),

            // Section Admin (visible uniquement pour les admins)
            if (_userRole == 'admin') ...[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Administration',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Gérer les réclamations'),
                onTap: () => _navigateTo(const ReclamationListScreen()),
              ),
              const Divider(height: 1),
            ],

            const SizedBox(height: 20),

            // Déconnexion
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
