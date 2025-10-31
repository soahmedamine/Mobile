import 'package:flutter/material.dart';
import 'weather_screen.dart';
import 'travel_screen.dart';
import 'event_list_screen.dart';
import 'logement_list_screen.dart';
import '../widgets/app_drawer.dart';
import '../modules/trip_management/screens/TripListScreen.dart';
import '../modules/trip_management/screens/create_trip_screen.dart';
import '../services/weather_service.dart';
import 'note_list_screen.dart';
import 'note_form_screen.dart';
import 'note_detail_screen.dart';
import '../database/database_helper_new.dart';
import '../widgets/alert_list_widget.dart';
import '../providers/alert_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NotesDialogContent extends StatelessWidget {
  const _NotesDialogContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final database = DatabaseHelper();
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.getNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notes_outlined, size: 60, color: Colors.white54),
                const SizedBox(height: 15),
                const Text(
                  'Aucune note trouvée',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Commencez par créer votre première note',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notes = snapshot.data!;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final title = note['title']?.toString().isNotEmpty == true 
                ? note['title'] 
                : note['content']?.toString().split('\n').first ?? 'Nouvelle note';
            final content = note['content']?.toString() ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: content.isNotEmpty
                    ? Text(
                        content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetailScreen(note: note),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _WeatherDialogContent extends StatelessWidget {
  const _WeatherDialogContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WeatherService weatherService = WeatherService();
    String city = "Tunis";
    
    return FutureBuilder<dynamic>(
      future: weatherService.getWeather(city),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final weatherData = snapshot.data;
        final temp = weatherData?['main']?['temp']?.round() ?? '--';
        final description = weatherData?['weather']?[0]?['description'] ?? 'Non disponible';
        final icon = weatherData?['weather']?[0]?['icon'] ?? '01d';
        final humidity = weatherData?['main']?['humidity']?.toString() ?? '--';
        final windSpeed = weatherData?['wind']?['speed']?.toStringAsFixed(1) ?? '--';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$temp°C',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Image.network(
              'https://openweathermap.org/img/wn/$icon@2x.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.cloud_off, color: Colors.white, size: 60),
            ),
            Text(
              description.toString().toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo('Humidité', '$humidity%', Icons.water_drop),
                _buildWeatherInfo('Vent', '${windSpeed}m/s', Icons.air),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _AlertsDialogContent extends StatelessWidget {
  const _AlertsDialogContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D47A1).withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alertes Récentes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const AlertListWidget(),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMenu = false;

  // List of menu items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.cloud_outlined,
      'label': 'Météo',
      'screen': const WeatherScreen(),
      'color': Colors.blue
    },
    {
      'icon': Icons.travel_explore,
      'label': 'Voyage',
      'screen': const TravelScreen(),
      'color': Colors.green
    },
    {
      'icon': Icons.note_outlined,
      'label': 'Notes',
      'screen': const NoteListScreen(),
      'color': Colors.purple
    },
    {
      'icon': Icons.event_outlined,
      'label': 'Événements',
      'screen': const EventListScreen(),
      'color': Colors.red
    },
    {
      'icon': Icons.home_outlined,
      'label': 'Logements',
      'screen': const LogementListScreen(),
      'color': Colors.teal
    },
    {
      'icon': Icons.route,
      'label': 'Trajectoires',
      'screen': const TripListScreen(),
      'color': Colors.blueGrey
    },
    {
      'icon': Icons.add_road,
      'label': 'Nouvelle Trajectoire',
      'screen': const CreateTripScreen(),
      'color': Colors.indigo
    },
  ];

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AlertsDialogContent(),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAlertsDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: Colors.orange, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alertes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Voir les dernières mises à jour',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add a test alert when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      alertProvider.addAlert(
        title: 'Bienvenue sur Smart Travel !',
        message: 'Découvrez les dernières mises à jour de votre voyage.',
        type: 'info',
        itemId: 'welcome',
        action: 'added',
      );
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Smart Travel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1), // Dark Blue
              Color(0xFF1976D2), // Blue
              Color(0xFF42A5F5), // Light Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildAlertsCard(context),
              // Top Cards Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    // Weather Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: const Color(0xFF0D47A1).withOpacity(0.95),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Météo Actuelle',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      const _WeatherDialogContent(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.cloud_outlined, color: Colors.white, size: 24),
                              Spacer(),
                              Text(
                                'Météo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Voir les prévisions',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Notes Card
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: DatabaseHelper().getNotes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final notes = snapshot.data ?? [];
                          final recentNotes = notes.take(2).toList(); // Get up to 2 most recent notes
                          
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    backgroundColor: const Color(0xFF0D47A1).withOpacity(0.95),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      height: MediaQuery.of(context).size.height * 0.7,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Mes Notes',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white),
                                                onPressed: () => Navigator.of(context).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(15),
                                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: const _NotesDialogContent(),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const NoteFormScreen(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF0D47A1),
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: const Text(
                                              'Nouvelle Note',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 100,
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.purple.withOpacity(0.5), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(Icons.notes, color: Colors.white, size: 18),
                                      Text(
                                        '${notes.length} ${notes.length == 1 ? 'Note' : 'Notes'}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (recentNotes.isNotEmpty) ...[
                                    ...recentNotes.sublist(0, recentNotes.length > 1 ? 1 : 1).map((note) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2.0),
                                      child: Text(
                                        '• ${note['content']?.toString().split('\n').first ?? 'New Note'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          height: 1.2,
                                        ),
                                      ),
                                    )).toList(),
                                    if (recentNotes.length > 1) 
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0),
                                        child: Text(
                                          '• ${recentNotes[1]['content']?.toString().split('\n').first ?? 'New Note'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    if (notes.length > 2) 
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          '+${notes.length - 2} more',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                  ] else
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Aucune note',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      children: [
                      const SizedBox(height: 20),
                      // Welcome Card - Clickable
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showMenu = !_showMenu;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(20), // Reduced padding
                          constraints: const BoxConstraints(
                            minWidth: double.infinity, // Take full width
                          ),
                          decoration: BoxDecoration(
                            color: _showMenu 
                                ? Colors.white.withOpacity(0.25) 
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Prevent extra space
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(15), // Reduced padding
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/smartravel.png',
                                  width: _showMenu ? 80 : 120, // Slightly smaller image
                                  height: _showMenu ? 80 : 120, // Slightly smaller image
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 15), // Reduced spacing
                              Text(
                                _showMenu ? 'Choisissez une option' : 'Bienvenue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22, // Slightly smaller font
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!_showMenu) ...[
                                const SizedBox(height: 6), // Reduced spacing
                                Text(
                                  'Appuyez pour afficher le menu',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14, // Slightly smaller font
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Menu Grid - Only show when _showMenu is true
                      if (_showMenu) AnimatedOpacity(
                        opacity: _showMenu ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            final item = _menuItems[index];
                            if (item['label'] == 'Notes') {
                              return _buildMenuItem(
                                context: context,
                                icon: item['icon'],
                                label: item['label'],
                                color: item['color'],
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: const Color(0xFF0D47A1).withOpacity(0.95),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          height: MediaQuery.of(context).size.height * 0.7,
                                          width: MediaQuery.of(context).size.width * 0.9,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Mes Notes',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              const Expanded(child: _NotesDialogContent()),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              return _buildMenuItem(
                                context: context,
                                icon: item['icon'],
                                label: item['label'],
                                color: item['color'],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => item['screen'] as Widget),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

