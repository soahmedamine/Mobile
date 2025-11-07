import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/profil_culturel.dart';
import '../models/expression_locale.dart';
import '../models/securite_sante.dart';
import '../services/profil_culturel_service.dart';
import '../services/expression_locale_service.dart';
import '../services/securite_sante_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/world_time_service.dart';
import '../services/air_quality_service.dart';
import '../services/image_service.dart';
import 'home_screen.dart';

class CultureModuleScreen extends StatefulWidget {
  const CultureModuleScreen({super.key});

  @override
  State<CultureModuleScreen> createState() => _CultureModuleScreenState();
}

class _CultureModuleScreenState extends State<CultureModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _profilService = ProfilCulturelService();
  final _exprService = ExpressionLocaleService();
  final _secService = SecuriteSanteService();

  List<ProfilCulturel> _profils = [];
  List<ExpressionLocale> _expressions = [];
  List<SecuriteSante> _securites = [];

  bool _loading = true;
  bool _isAdmin = false;

  // Live info services and state
  late final ExchangeRateService _exchangeService;
  late final WorldTimeService _timeService;
  AirQualityService? _airService;

  final _fromCtrl = TextEditingController(text: 'USD');
  final _toCtrl = TextEditingController(text: 'EUR');
  final _amountCtrl = TextEditingController(text: '1');
  double? _conversionResult;
  bool _convLoading = false;
  String? _convError;

  final _countryTimeCtrl = TextEditingController(text: 'France');
  DateTime? _localTime;
  bool _timeLoading = false;
  String? _timeError;
  final _tzCtrl = TextEditingController();

  final _aqCityCtrl = TextEditingController(text: 'Paris');
  final _aqCountryCtrl = TextEditingController(text: 'FR');
  int? _aqi;
  Map<String, dynamic>? _aqComponents;
  bool _aqLoading = false;

  // Recommendations state
  String _recCountry = 'France';
  final _recCountryCtrl = TextEditingController(text: 'France');
  final Set<String> _recInterests = {'gastronomie', 'traditions'};
  final List<Map<String, dynamic>> _recActivities = [
    {'country': 'France', 'city': 'Lille', 'title': 'Palais des Beaux-Arts', 'tags': ['musée','art','traditions']},
    {'country': 'France', 'city': 'Paris', 'title': 'Atelier dégustation de fromages', 'tags': ['gastronomie','fromage','atelier'], 'price': 35, 'currency': 'EUR'},
    {'country': 'Tunisia', 'city': 'Tunis', 'title': 'Médina de Tunis', 'tags': ['patrimoine','traditions','architecture']},
    {'country': 'Tunisia', 'city': 'Tunis', 'title': 'Musée du Bardo', 'tags': ['musée','histoire','mosaïques']},
    {'country': 'England', 'city': 'London', 'title': 'British Museum', 'tags': ['musée','histoire']},
    {'country': 'England', 'city': 'London', 'title': 'West End Theatre', 'tags': ['spectacle','arts']},
    {'country': 'Turkey', 'city': 'Istanbul', 'title': 'Sainte-Sophie & Sultanahmet', 'tags': ['patrimoine','architecture']},
    {'country': 'Turkey', 'city': 'Istanbul', 'title': 'Grand Bazar', 'tags': ['marché','artisanat','négociation']},
    {'country': 'Canada', 'city': 'Montréal', 'title': 'Musée des Beaux-Arts de Montréal', 'tags': ['musée','art']},
    {'country': 'Canada', 'city': 'Québec', 'title': 'Vieux-Québec', 'tags': ['patrimoine','balade']},
    // France extra
    {'country': 'France', 'city': 'Paris', 'title': 'Festival du Fromage et du Vin', 'tags': ['festival','gastronomie','fromage','traditions']},
    {'country': 'France', 'city': 'Lyon', 'title': 'Halles de Lyon Paul Bocuse', 'tags': ['marché','gastronomie']},
    {'country': 'France', 'city': 'Paris', 'title': 'Musée d’Orsay', 'tags': ['musée','art','histoire']},
    {'country': 'France', 'city': 'Strasbourg', 'title': 'Marché de Noël', 'tags': ['marché','festival','traditions','sucré']},
    {'country': 'France', 'city': 'Bayonne', 'title': 'Atelier chocolat', 'tags': ['atelier','sucré','gastronomie']},
    // Tunisia extra
    {'country': 'Tunisia', 'city': 'Sidi Bou Saïd', 'title': 'Balade artisanat & cafés', 'tags': ['artisanat','traditions','sucré']},
    {'country': 'Tunisia', 'city': 'Nabeul', 'title': 'Souk de la poterie', 'tags': ['marché','artisanat']},
    {'country': 'Tunisia', 'city': 'Kairouan', 'title': 'Visite médersa & tissage', 'tags': ['histoire','artisanat','traditions']},
    {'country': 'Tunisia', 'city': 'Sousse', 'title': 'Musée archéologique', 'tags': ['musée','histoire']},
    // England extra
    {'country': 'England', 'city': 'London', 'title': 'National Gallery', 'tags': ['musée','art']},
    {'country': 'England', 'city': 'London', 'title': 'Borough Market food tour', 'tags': ['marché','gastronomie']},
    {'country': 'England', 'city': 'Edinburgh', 'title': 'Festival Fringe (été)', 'tags': ['festival','arts']},
    {'country': 'England', 'city': 'Bath', 'title': 'Roman Baths & histoire', 'tags': ['histoire','patrimoine']},
    // Turkey extra
    {'country': 'Turkey', 'city': 'Gaziantep', 'title': 'Parcours baklava & pistache', 'tags': ['gastronomie','sucré','artisanat']},
    {'country': 'Turkey', 'city': 'Cappadocia', 'title': 'Atelier poterie à Avanos', 'tags': ['artisanat','traditions']},
    {'country': 'Turkey', 'city': 'Istanbul', 'title': 'Marché aux épices', 'tags': ['marché','gastronomie','traditions']},
    {'country': 'Turkey', 'city': 'Istanbul', 'title': 'Musée d’Art Moderne', 'tags': ['musée','art']},
    // Canada extra
    {'country': 'Canada', 'city': 'Montréal', 'title': 'Marché Jean-Talon', 'tags': ['marché','gastronomie']},
    {'country': 'Canada', 'city': 'Montréal', 'title': 'Musée Pointe-à-Callière', 'tags': ['musée','histoire']},
    {'country': 'Canada', 'city': 'Québec', 'title': 'Festival d’été de Québec', 'tags': ['festival','arts']},
    {'country': 'Canada', 'city': 'Ottawa', 'title': 'Musée des beaux-arts du Canada', 'tags': ['musée','art']},
  ];
  final List<Map<String, dynamic>> _recDishes = [
    {'country': 'France', 'name': 'Fromages AOP', 'tags': ['fromage','gastronomie']},
    {'country': 'France', 'name': 'Pâtisseries (éclairs, macarons)', 'tags': ['pâtisserie','sucré']},
    {'country': 'Tunisia', 'name': 'Couscous tunisien', 'tags': ['gastronomie']},
    {'country': 'Tunisia', 'name': "Brik à l'œuf", 'tags': ['street-food']},
    {'country': 'England', 'name': 'Fish & chips', 'tags': ['comfort-food']},
    {'country': 'England', 'name': 'Afternoon tea', 'tags': ['traditions','sucré']},
    {'country': 'Turkey', 'name': 'Kebab, Meze, Baklava', 'tags': ['gastronomie','sucré']},
    {'country': 'Turkey', 'name': 'Menemen', 'tags': ['petit-déjeuner']},
    {'country': 'Canada', 'name': 'Poutine', 'tags': ['gastronomie locale']},
    {'country': 'Canada', 'name': 'Tourtière', 'tags': ['spécialité']},
    // France extra
    {'country': 'France', 'name': 'Raclette/Fondue', 'tags': ['fromage','gastronomie']},
    {'country': 'France', 'name': 'Crêpes', 'tags': ['sucré','pâtisserie']},
    {'country': 'France', 'name': 'Baguette tradition', 'tags': ['artisanat','traditions']},
    // Tunisia extra
    {'country': 'Tunisia', 'name': 'Lablabi', 'tags': ['gastronomie']},
    {'country': 'Tunisia', 'name': 'Makroud', 'tags': ['sucré','artisanat']},
    {'country': 'Tunisia', 'name': 'Harissa artisanale', 'tags': ['marché','artisanat']},
    // England extra
    {'country': 'England', 'name': 'Cheddar/ Stilton', 'tags': ['fromage','traditions']},
    {'country': 'England', 'name': 'Cornish pasty', 'tags': ['artisanat','comfort-food']},
    {'country': 'England', 'name': 'Scones & clotted cream', 'tags': ['sucré','traditions']},
    // Turkey extra
    {'country': 'Turkey', 'name': 'Simit', 'tags': ['artisanat','marché']},
    {'country': 'Turkey', 'name': 'Lokum (Turkish delight)', 'tags': ['sucré','traditions']},
    {'country': 'Turkey', 'name': 'Manti', 'tags': ['gastronomie']},
    // Canada extra
    {'country': 'Canada', 'name': 'Sirop d’érable (dégustation)', 'tags': ['sucré','traditions']},
    {'country': 'Canada', 'name': 'Bagel de Montréal', 'tags': ['artisanat','marché']},
    {'country': 'Canada', 'name': 'Smoked meat', 'tags': ['gastronomie']},
  ];
  final List<Map<String, dynamic>> _recBehaviors = [
    {'country': 'France', 'type': 'adopter', 'text': 'Dire Bonjour/Merci; ton formel au premier contact', 'tags': ['politesse','traditions']},
    {'country': 'France', 'type': 'eviter', 'text': 'Éviter de tutoyer d’emblée', 'tags': ['politesse']},
    {'country': 'Tunisia', 'type': 'adopter', 'text': 'Tenue décente selon lieux; saluer avant le sujet', 'tags': ['traditions']},
    {'country': 'Tunisia', 'type': 'eviter', 'text': 'Éviter critiques frontales des traditions', 'tags': ['traditions']},
    {'country': 'England', 'type': 'adopter', 'text': 'Files d’attente, please/thank you', 'tags': ['politesse']},
    {'country': 'England', 'type': 'eviter', 'text': 'Éviter la familiarité trop rapide', 'tags': ['politesse']},
    {'country': 'Turkey', 'type': 'adopter', 'text': 'Modestie vestimentaire dans lieux religieux', 'tags': ['traditions']},
    {'country': 'Turkey', 'type': 'eviter', 'text': 'Ne pas manquer de respect aux rites de prière', 'tags': ['traditions']},
    {'country': 'Canada', 'type': 'adopter', 'text': 'Politesse, respect de la diversité', 'tags': ['civisme']},
    {'country': 'Canada', 'type': 'eviter', 'text': 'Éviter propos clivants', 'tags': ['civisme']},
    // France extra
    {'country': 'France', 'type': 'adopter', 'text': 'Respecter l’étiquette de table (pain, fromage, vin)', 'tags': ['traditions','fromage','gastronomie']},
    {'country': 'France', 'type': 'eviter', 'text': 'Couper le fromage n’importe comment (attention aux pointes)', 'tags': ['fromage','traditions']},
    // Tunisia extra
    {'country': 'Tunisia', 'type': 'adopter', 'text': 'Négociation courtoise au marché; proposer salutations', 'tags': ['marché','traditions']},
    {'country': 'Tunisia', 'type': 'eviter', 'text': 'Manquer de respect aux coutumes locales', 'tags': ['traditions']},
    // England extra
    {'country': 'England', 'type': 'adopter', 'text': 'Humour léger, auto-dérision bienvenue', 'tags': ['traditions']},
    {'country': 'England', 'type': 'eviter', 'text': 'Couper les files/queues et parler trop fort', 'tags': ['politesse']},
    // Turkey extra
    {'country': 'Turkey', 'type': 'adopter', 'text': 'Accepter le thé par politesse; respect des aînés', 'tags': ['traditions','gastronomie']},
    {'country': 'Turkey', 'type': 'eviter', 'text': 'Photographier des personnes sans consentement', 'tags': ['traditions']},
    // Canada extra
    {'country': 'Canada', 'type': 'adopter', 'text': 'Tenir la porte; parler calmement; diversité respectée', 'tags': ['civisme']},
    {'country': 'Canada', 'type': 'eviter', 'text': 'Ignorer les règles de civisme (déchets, bruit nocturne)', 'tags': ['civisme']},
  ];
  List<Map<String, dynamic>> _outActivities = [];
  List<Map<String, dynamic>> _outDishes = [];
  List<Map<String, dynamic>> _outBehaviors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _filterRecommendations();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    _isAdmin = role == 'admin';
    final key = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (key.isNotEmpty) {
      _airService = AirQualityService(key);
    } else {
      _airService = null;
    }
    final fastKey = dotenv.env['FASTFOREX_API_KEY'] ?? '';
    _exchangeService = ExchangeRateService(fastForexKey: fastKey);
    final tzdbKey = dotenv.env['TIMEZONEDB_API_KEY'] ?? '';
    _timeService = WorldTimeService(timeZoneDbKey: tzdbKey);
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final profils = await _profilService.getAll();
    final exprs = await _exprService.getAll();
    final secs = await _secService.getAll();
    if (!mounted) return;
    setState(() {
      _profils = profils;
      _expressions = exprs;
      _securites = secs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _countryTimeCtrl.dispose();
    _tzCtrl.dispose();
    _aqCityCtrl.dispose();
    _aqCountryCtrl.dispose();
    _recCountryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            tooltip: 'Retour à l\'accueil',
          ),
          title: const Text('Culture & Infos Locales', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[800],
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.flag), text: 'Profil culturel'),
              Tab(icon: Icon(Icons.translate), text: 'Expressions'),
              Tab(icon: Icon(Icons.health_and_safety), text: 'Sécurité & Santé'),
              Tab(icon: Icon(Icons.insights), text: 'Infos en direct'),
              Tab(icon: Icon(Icons.recommend), text: 'Recommandations'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
            ),
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfilTab(),
                    _buildExpressionTab(),
                    _buildSecuriteTab(),
                    _buildLiveTab(),
                    _buildRecommendationsTab(),
                  ],
                ),
        ),
        floatingActionButton: _tabController.index < 3
            ? FloatingActionButton(
                onPressed: _onAdd,
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: Colors.blue),
              )
            : null,
      ),
    );
  }

  void _onAdd() {
    switch (_tabController.index) {
      case 0:
        _showProfilForm();
        break;
      case 1:
        _showExpressionForm();
        break;
      case 2:
        _showSecuriteForm();
        break;
      case 3:
      case 4:
        // No add action for these tabs
        break;
    }
  }

  // Profil culturel
  Widget _buildProfilTab() {
    if (_profils.isEmpty) {
      return _buildEmpty('Aucun profil culturel');
    }
    final imageService = ImageService();
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _profils.length,
      itemBuilder: (context, i) {
        final p = _profils[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.imageUrl != null)
                  imageService.isBase64Image(p.imageUrl)
                      ? Image.memory(
                          imageService.getBase64ImageBytes(p.imageUrl!)!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          p.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.error)),
                              ),
                        ),
                ListTile(
                  title: Text(p.pays, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(p.traditions, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: _isAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showProfilForm(existing: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProfil(p),
                            ),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteProfil(ProfilCulturel p) async {
    if (p.id == null) return;
    await _profilService.delete(p.id!);
    await _loadAll();
  }

  Future<void> _showProfilForm({ProfilCulturel? existing}) async {
    final paysCtrl = TextEditingController(text: existing?.pays ?? '');
    final traditionsCtrl = TextEditingController(text: existing?.traditions ?? '');
    final gastronomieCtrl = TextEditingController(text: existing?.gastronomie ?? '');
    final adopterCtrl = TextEditingController(text: existing?.comportementsAAdopter ?? '');
    final eviterCtrl = TextEditingController(text: existing?.comportementsAEviter ?? '');
    String? selectedImage = existing?.imageUrl;
    final imageService = ImageService();

    await showDialog(
      context: context,
      builder: (ctx) => _buildThemedDialog(
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  existing == null ? 'Nouveau profil' : 'Modifier profil',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Pays'),
                        controller: paysCtrl,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Traditions'),
                        controller: traditionsCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Gastronomie'),
                        controller: gastronomieCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Comportements à adopter'),
                        controller: adopterCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Comportements à éviter'),
                        controller: eviterCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Image picker section
                      if (selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageService.isBase64Image(selectedImage!)
                              ? Image.memory(
                                  imageService.getBase64ImageBytes(selectedImage!)!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  selectedImage!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        style: _buildButtonStyle().copyWith(
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          textStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white)),
                        ),
                        onPressed: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choisir depuis la galerie'),
                                    onTap: () => Navigator.pop(context, 'gallery'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Prendre une photo'),
                                    onTap: () => Navigator.pop(context, 'camera'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.link),
                                    title: const Text('Entrer une URL'),
                                    onTap: () => Navigator.pop(context, 'url'),
                                  ),
                                  if (selectedImage != null)
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Supprimer l\'image', style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(context, 'delete'),
                                    ),
                                ],
                              ),
                            ),
                          );

                          if (result == 'gallery') {
                            final image = await imageService.pickImageFromGallery();
                            if (image != null) {
                              setState(() => selectedImage = image);
                            }
                          } else if (result == 'camera') {
                            final image = await imageService.takePhoto();
                            if (image != null) {
                              setState(() => selectedImage = image);
                            }
                          } else if (result == 'url') {
                            final urlCtrl = TextEditingController(text: selectedImage ?? '');
                            final url = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('URL de l\'image'),
                                content: TextField(
                                  controller: urlCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'https://...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, urlCtrl.text),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (url != null && url.isNotEmpty) {
                              setState(() => selectedImage = url);
                            }
                          } else if (result == 'delete') {
                            setState(() => selectedImage = null);
                          }
                        },
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: Text(
                          selectedImage == null ? 'Ajouter une image' : 'Modifier l\'image',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              // Boutons d'action
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('ANNULER'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: _buildButtonStyle(),
                      onPressed: () async {
                        final item = ProfilCulturel(
                          id: existing?.id,
                          pays: paysCtrl.text.trim(),
                          traditions: traditionsCtrl.text.trim(),
                          gastronomie: gastronomieCtrl.text.trim(),
                          comportementsAAdopter: adopterCtrl.text.trim(),
                          comportementsAEviter: eviterCtrl.text.trim(),
                          imageUrl: selectedImage,
                        );
                        if (existing == null) {
                          await _profilService.create(item);
                        } else {
                          await _profilService.update(item);
                        }
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadAll();
                      },
                      child: const Text('ENREGISTRER', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Expressions locales
  Widget _buildExpressionTab() {
    if (_expressions.isEmpty) {
      return _buildEmpty('Aucune expression');
    }
    final imageService = ImageService();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _expressions.length,
      itemBuilder: (context, i) {
        final e = _expressions[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.imageUrl != null)
                imageService.isBase64Image(e.imageUrl)
                    ? Image.memory(
                        imageService.getBase64ImageBytes(e.imageUrl!)!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        e.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.error)),
                            ),
                      ),
              ListTile(
                title: Text('${e.langue} • ${e.expression}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(e.traduction),
                trailing: _isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showExpressionForm(existing: e),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteExpression(e),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteExpression(ExpressionLocale e) async {
    if (e.id == null) return;
    await _exprService.delete(e.id!);
    await _loadAll();
  }

  Future<void> _showExpressionForm({ExpressionLocale? existing}) async {
    final langueCtrl = TextEditingController(text: existing?.langue ?? '');
    final expressionCtrl = TextEditingController(text: existing?.expression ?? '');
    final traductionCtrl = TextEditingController(text: existing?.traduction ?? '');
    final categorieCtrl = TextEditingController(text: existing?.categorie ?? '');
    String? selectedImage = existing?.imageUrl;
    final imageService = ImageService();

    await showDialog(
      context: context,
      builder: (ctx) => _buildThemedDialog(
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  existing == null ? 'Nouvelle expression' : 'Modifier expression',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              
              // Contenu du formulaire
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Champ Langue
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Langue'),
                        controller: langueCtrl,
                      ),
                      const SizedBox(height: 12),
                      
                      // Champ Expression
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Expression'),
                        controller: expressionCtrl,
                      ),
                      const SizedBox(height: 12),
                      
                      // Champ Traduction
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Traduction'),
                        controller: traductionCtrl,
                      ),
                      const SizedBox(height: 12),
                      
                      // Champ Catégorie
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Catégorie'),
                        controller: categorieCtrl,
                      ),
                      const SizedBox(height: 16),
                      
                      // Section image
                      if (selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageService.isBase64Image(selectedImage!)
                              ? Image.memory(
                                  imageService.getBase64ImageBytes(selectedImage!)!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  selectedImage!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Bouton d'ajout d'image
                      ElevatedButton.icon(
                        style: _buildButtonStyle().copyWith(
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          textStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white)),
                        ),
                        onPressed: () async {
                          final result = await showModalBottomSheet<String>(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Choisir depuis la galerie'),
                                    onTap: () => Navigator.pop(context, 'gallery'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Prendre une photo'),
                                    onTap: () => Navigator.pop(context, 'camera'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.link),
                                    title: const Text('Entrer une URL'),
                                    onTap: () => Navigator.pop(context, 'url'),
                                  ),
                                  if (selectedImage != null)
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Supprimer l\'image', style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(context, 'delete'),
                                    ),
                                ],
                              ),
                            ),
                          );

                          if (result == 'gallery') {
                            final image = await imageService.pickImageFromGallery();
                            if (image != null) {
                              setState(() => selectedImage = image);
                            }
                          } else if (result == 'camera') {
                            final image = await imageService.takePhoto();
                            if (image != null) {
                              setState(() => selectedImage = image);
                            }
                          } else if (result == 'url') {
                            final urlCtrl = TextEditingController(text: selectedImage ?? '');
                            final url = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('URL de l\'image'),
                                content: TextField(
                                  controller: urlCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'https://...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, urlCtrl.text),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (url != null && url.isNotEmpty) {
                              setState(() => selectedImage = url);
                            }
                          } else if (result == 'delete') {
                            setState(() => selectedImage = null);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(selectedImage == null ? 'Ajouter une image' : 'Modifier l\'image'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Pied de page avec boutons
              const Divider(height: 1, color: Colors.white24),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton Annuler
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('ANNULER'),
                    ),
                    const SizedBox(width: 8),
                    
                    // Bouton Enregistrer
                    ElevatedButton(
                      style: _buildButtonStyle(),
                      onPressed: () async {
                        final item = ExpressionLocale(
                          id: existing?.id,
                          langue: langueCtrl.text.trim(),
                          expression: expressionCtrl.text.trim(),
                          traduction: traductionCtrl.text.trim(),
                          categorie: categorieCtrl.text.trim(),
                          imageUrl: selectedImage,
                        );
                        
                        if (existing == null) {
                          await _exprService.create(item);
                        } else {
                          await _exprService.update(item);
                        }
                        
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadAll();
                      },
                      child: const Text('ENREGISTRER', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sécurité & Santé
  Widget _buildSecuriteTab() {
    if (_securites.isEmpty) {
      return _buildEmpty('Aucune fiche sécurité/santé');
    }
    final imageService = ImageService();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _securites.length,
      itemBuilder: (context, i) {
        final s = _securites[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.imageUrl != null)
                imageService.isBase64Image(s.imageUrl)
                    ? Image.memory(
                        imageService.getBase64ImageBytes(s.imageUrl!)!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        s.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.error)),
                            ),
                      ),
              ListTile(
                title: Text(s.pays, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.precautionsGenerales, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: _isAdmin
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showSecuriteForm(existing: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSecurite(s),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSecurite(SecuriteSante s) async {
    if (s.id == null) return;
    await _secService.delete(s.id!);
    await _loadAll();
  }

  Future<void> _showSecuriteForm({SecuriteSante? existing}) async {
    final paysCtrl = TextEditingController(text: existing?.pays ?? '');
    final vaccinsCtrl = TextEditingController(text: existing?.vaccinsRecommandes ?? '');
    final precautCtrl = TextEditingController(text: existing?.precautionsGenerales ?? '');
    final zonesCtrl = TextEditingController(text: existing?.zonesARisque ?? '');
    final urgenceCtrl = TextEditingController(text: existing?.urgenceContact ?? '');
    String? selectedImage = existing?.imageUrl;
    final imageService = ImageService();

    await showDialog(
      context: context,
      builder: (ctx) => _buildThemedDialog(
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  existing == null ? 'Nouvelle fiche sécurité/santé' : 'Modifier fiche sécurité/santé',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Pays'),
                        controller: paysCtrl,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Vaccins recommandés'),
                        controller: vaccinsCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Précautions générales'),
                        controller: precautCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Zones à risque'),
                        controller: zonesCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Contact d\'urgence'),
                        controller: urgenceCtrl,
                      ),
                      const SizedBox(height: 16),
                      
                      // Section image
                      if (selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageService.isBase64Image(selectedImage!)
                              ? Image.memory(
                                  imageService.getBase64ImageBytes(selectedImage!)!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  selectedImage!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error, color: Colors.white),
                                      ),
                                ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Boutons d'action pour l'image
                      const Text(
                        'Sélectionner une image',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: ElevatedButton.icon(
                                style: _buildButtonStyle(),
                                icon: const Icon(Icons.photo_library, size: 18, color: Colors.white),
                                label: const Text('Galerie', style: TextStyle(fontSize: 13, color: Colors.white)),
                                onPressed: () async {
                                  final image = await imageService.pickImageFromGallery();
                                  if (image != null) {
                                    setState(() => selectedImage = image);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ElevatedButton.icon(
                                style: _buildButtonStyle(),
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                label: const Text('Appareil', style: TextStyle(fontSize: 13, color: Colors.white)),
                                onPressed: () async {
                                  final image = await imageService.takePhoto();
                                  if (image != null) {
                                    setState(() => selectedImage = image);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: ElevatedButton.icon(
                                style: _buildButtonStyle(),
                                icon: const Icon(Icons.link, size: 18, color: Colors.white),
                                label: const Text('URL', style: TextStyle(fontSize: 13, color: Colors.white)),
                                onPressed: () async {
                                  final url = await showDialog<String>(
                                    context: context,
                                    builder: (context) => _buildThemedDialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'URL de l\'image',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: TextField(
                                              style: const TextStyle(color: Colors.white),
                                              controller: TextEditingController(text: selectedImage ?? ''),
                                              decoration: _buildInputDecoration('Entrez l\'URL de l\'image'),
                                              onSubmitted: (value) {
                                                Navigator.pop(context, value);
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('ANNULER', style: TextStyle(color: Colors.white70)),
                                                ),
                                                const SizedBox(width: 16),
                                                ElevatedButton(
                                                  style: _buildButtonStyle(),
                                                  onPressed: () {
                                                    Navigator.pop(context, selectedImage);
                                                  },
                                                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (url != null && url.isNotEmpty) {
                                    setState(() => selectedImage = url);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            label: const Text('Supprimer l\'image', style: TextStyle(color: Colors.red, fontSize: 13)),
                            onPressed: () => setState(() => selectedImage = null),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              // Boutons d'action
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('ANNULER'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: _buildButtonStyle(),
                      onPressed: () async {
                        final item = SecuriteSante(
                          id: existing?.id,
                          pays: paysCtrl.text.trim(),
                          vaccinsRecommandes: vaccinsCtrl.text.trim(),
                          precautionsGenerales: precautCtrl.text.trim(),
                          zonesARisque: zonesCtrl.text.trim(),
                          urgenceContact: urgenceCtrl.text.trim(),
                          imageUrl: selectedImage,
                        );
                        if (existing == null) {
                          await _secService.create(item);
                        } else {
                          await _secService.update(item);
                        }
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadAll();
                      },
                      child: const Text('ENREGISTRER', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Style pour les champs de formulaire
  InputDecoration _buildInputDecoration(String label) {
    const double radius = 8.0;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(radius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(radius),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Style pour les boutons
  ButtonStyle _buildButtonStyle({Color? backgroundColor}) {
    const double radius = 8.0;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.blue[700],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // Style pour les boîtes de dialogue
  Widget _buildThemedDialog({required Widget child}) {
    const double radius = 8.0;
    return Theme(
      data: Theme.of(context).copyWith(
        dialogBackgroundColor: const Color(0xFF0D47A1),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Colors.white),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Dialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Utilisation d'un littéral double
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Live tab
  Widget _buildLiveTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.yellow[100], borderRadius: BorderRadius.circular(6)),
              child: const Text(
                'Note: Sur Flutter Web, certaines APIs peuvent échouer à cause de CORS. Testez sur mobile/desktop pour éviter ce problème.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Text(
            'Taux de change',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'De (ex: USD)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.swap_horiz, size: 32, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _toCtrl,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Vers (ex: EUR)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Montant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _convLoading ? null : _doConvert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _convLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Convertir',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_convError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(_convError!, style: TextStyle(color: Colors.red[700], fontSize: 12)),
            ),
          if (_conversionResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Résultat: $_conversionResult'),
            ),

          const Divider(height: 24),

          Text('Heure locale', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _countryTimeCtrl,
            decoration: const InputDecoration(labelText: 'Pays (ex: France)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tzCtrl,
            decoration: const InputDecoration(labelText: 'Fuseau horaire (optionnel, ex: Europe/Paris)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _timeLoading ? null : _doLocalTime,
            child: _timeLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Afficher l\'heure locale'),
          ),
          if (_timeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(_timeError!, style: TextStyle(color: Colors.red[700], fontSize: 12)),
            ),
          if (_localTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Heure locale: ${_localTime!.toLocal()}'),
            ),

          const Divider(height: 24),

          Text('Qualité de l\'air (AQI)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aqCityCtrl,
                  decoration: const InputDecoration(labelText: 'Ville (ex: Paris)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _aqCountryCtrl,
                  decoration: const InputDecoration(labelText: 'Pays/Code (ex: FR)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _aqLoading ? null : _doAirQuality,
            child: _aqLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Obtenir AQI'),
          ),
          if (_aqi != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('AQI: $_aqi'),
            ),
          if (_aqComponents != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Polluants: ${_aqComponents}'),
            ),
          if (_airService == null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Clé OpenWeather manquante (.env: OPENWEATHER_API_KEY)',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _doConvert() async {
    setState(() => _convLoading = true);
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final amt = double.tryParse(amountStr);
    if (amt == null) {
      setState(() {
        _conversionResult = null;
        _convError = 'Montant invalide';
        _convLoading = false;
      });
      return;
    }
    final res = await _exchangeService.convert(from: from, to: to, amount: amt);
    if (!mounted) return;
    setState(() {
      _conversionResult = res;
      _convError = res == null ? 'Conversion indisponible pour $from→$to' : null;
      _convLoading = false;
    });
  }

  Future<void> _doLocalTime() async {
    setState(() => _timeLoading = true);
    _timeError = null;
    DateTime? dt;
    final tz = _tzCtrl.text.trim();
    if (tz.isNotEmpty) {
      dt = await _timeService.getTimeByTimezone(tz);
      if (dt == null) {
        _timeError = 'Fuseau horaire invalide: $tz';
      }
    }
    if (dt == null) {
      final country = _countryTimeCtrl.text.trim();
      // Essais rapides pour quelques pays courants
      final overrides = <String, String>{
        'france': 'Europe/Paris',
        'maroc': 'Africa/Casablanca',
        'morocco': 'Africa/Casablanca',
        'tunisie': 'Africa/Tunis',
        'tunisia': 'Africa/Tunis',
        'algérie': 'Africa/Algiers',
        'algeria': 'Africa/Algiers',
      };
      final key = country.toLowerCase();
      final ov = overrides[key];
      if (ov != null) {
        dt = await _timeService.getTimeByTimezone(ov);
      }
      dt ??= await _timeService.getLocalTimeByCountryGuess(country);
      if (dt == null && _timeError == null) {
        _timeError = 'Impossible de déterminer l\'heure locale pour "$country"';
      }
    }
    if (!mounted) return;
    setState(() {
      _localTime = dt;
      _timeLoading = false;
    });
  }

  Future<void> _doAirQuality() async {
    setState(() => _aqLoading = true);
    final service = _airService;
    Map<String, dynamic>? parsed;
    if (service != null) {
      final raw = await service.getAirQualityByCity(
        _aqCityCtrl.text.trim(),
        country: _aqCountryCtrl.text.trim(),
      );
      if (raw != null) {
        parsed = service.parseAqi(raw);
      }
    }
    if (!mounted) return;
    setState(() {
      _aqi = parsed == null ? null : (parsed['aqi'] as int?);
      _aqComponents = parsed == null ? null : (parsed['components'] as Map<String, dynamic>?);
      _aqLoading = false;
    });
  }

  // Recommendations tab
  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pays', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _recCountryCtrl,
            decoration: const InputDecoration(
              labelText: 'Pays (ex: France, Tunisia, Turkey)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _recCountry = val.trim();
                _filterRecommendations();
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Centres d\'intérêt', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildInterestChip('gastronomie'),
              _buildInterestChip('fromage'),
              _buildInterestChip('sucré'),
              _buildInterestChip('traditions'),
              _buildInterestChip('musée'),
              _buildInterestChip('art'),
              _buildInterestChip('marché'),
              _buildInterestChip('artisanat'),
            ],
          ),
          const Divider(height: 32),
          Text('Activités recommandées', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_outActivities.isEmpty)
            const Text('Aucune activité correspondante', style: TextStyle(color: Colors.grey)),
          ..._outActivities.map((a) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.place),
              title: Text(a['title'] ?? ''),
              subtitle: Text('${a['city'] ?? ''} • ${(a['tags'] as List?)?.join(', ') ?? ''}'),
              trailing: a['price'] != null
                  ? Text('${a['price']} ${a['currency'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
          )),
          const Divider(height: 24),
          Text('Plats à découvrir', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_outDishes.isEmpty)
            const Text('Aucun plat correspondant', style: TextStyle(color: Colors.grey)),
          ..._outDishes.map((d) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(d['name'] ?? ''),
              subtitle: Text((d['tags'] as List?)?.join(', ') ?? ''),
            ),
          )),
          const Divider(height: 24),
          Text('Comportements culturels', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_outBehaviors.isEmpty)
            const Text('Aucun comportement correspondant', style: TextStyle(color: Colors.grey)),
          ..._outBehaviors.map((b) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: b['type'] == 'adopter' ? Colors.green[50] : Colors.orange[50],
            child: ListTile(
              leading: Icon(
                b['type'] == 'adopter' ? Icons.check_circle : Icons.warning,
                color: b['type'] == 'adopter' ? Colors.green : Colors.orange,
              ),
              title: Text(b['type'] == 'adopter' ? 'À adopter' : 'À éviter'),
              subtitle: Text(b['text'] ?? ''),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    final selected = _recInterests.contains(interest);
    return FilterChip(
      label: Text(interest),
      selected: selected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _recInterests.add(interest);
          } else {
            _recInterests.remove(interest);
          }
          _filterRecommendations();
        });
      },
    );
  }

  void _filterRecommendations() {
    final country = _recCountry.toLowerCase();
    final interests = _recInterests;

    _outActivities = _recActivities.where((a) {
      final actCountry = (a['country'] as String?)?.toLowerCase() ?? '';
      if (!actCountry.contains(country) && country.isNotEmpty) return false;
      if (interests.isEmpty) return true;
      final tags = (a['tags'] as List?)?.cast<String>() ?? [];
      return tags.any((t) => interests.contains(t));
    }).toList();

    _outDishes = _recDishes.where((d) {
      final dishCountry = (d['country'] as String?)?.toLowerCase() ?? '';
      if (!dishCountry.contains(country) && country.isNotEmpty) return false;
      if (interests.isEmpty) return true;
      final tags = (d['tags'] as List?)?.cast<String>() ?? [];
      return tags.any((t) => interests.contains(t));
    }).toList();

    _outBehaviors = _recBehaviors.where((b) {
      final behCountry = (b['country'] as String?)?.toLowerCase() ?? '';
      if (!behCountry.contains(country) && country.isNotEmpty) return false;
      if (interests.isEmpty) return true;
      final tags = (b['tags'] as List?)?.cast<String>() ?? [];
      return tags.any((t) => interests.contains(t));
    }).toList();
  }
}
