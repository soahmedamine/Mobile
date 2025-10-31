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
import '../screens/budget_screen.dart';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      
      // Navigate to the auth screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth', 
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error during logout')),
      );
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pop(context); // Fermer le drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.blue[700], size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
              Colors.blue[500]!,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // En-tête du drawer moderne
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue[700],
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _userRole == 'admin' ? 'Administrateur' : 'Utilisateur',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Menu items
            _buildMenuItem(
              icon: Icons.home_outlined,
              title: 'Accueil',
              onTap: () => _navigateTo(const HomeScreen()),
            ),

            _buildMenuItem(
              icon: Icons.cloud_outlined,
              title: 'Météo',
              onTap: () => _navigateTo(const WeatherScreen()),
            ),

            _buildMenuItem(
              icon: Icons.travel_explore,
              title: 'Voyages',
              onTap: () => _navigateTo(const TravelScreen()),
            ),

            _buildMenuItem(
              icon: Icons.hotel_outlined,
              title: 'Logements',
              onTap: () => _navigateTo(const LogementListScreen()),
            ),

            _buildMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget',
              onTap: () => _navigateTo(const BudgetScreen(travelId: 'default_travel')),
            ),

            _buildMenuItem(
              icon: Icons.chat_outlined,
              title: 'Chat AI',
              onTap: () => _navigateTo(const ChatScreen()),
            ),

            _buildMenuItem(
              icon: Icons.public_outlined,
              title: 'Culture & Infos Locales',
              onTap: () => _navigateTo(const CultureModuleScreen()),
            ),

            _buildMenuItem(
              icon: Icons.event_outlined,
              title: 'Événements',
              onTap: () => _navigateTo(const EventListScreen()),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Réclamations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildMenuItem(
              icon: Icons.add_comment_outlined,
              title: 'Nouvelle réclamation',
              onTap: () => _navigateTo(const ReclamationFormScreen()),
            ),

            _buildMenuItem(
              icon: Icons.list_alt_outlined,
              title: 'Mes réclamations',
              onTap: () => _navigateTo(const ViewReclamationsScreen()),
            ),

            // Section Admin
            if (_userRole == 'admin') ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Administration',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Gérer les réclamations',
                onTap: () => _navigateTo(const ReclamationListScreen()),
              ),
            ],

            const SizedBox(height: 20),

            // Déconnexion
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Déconnexion'),
                        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Déconnexion'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.logout, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Déconnexion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
