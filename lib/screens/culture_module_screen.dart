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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Culture & Infos Locales'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.flag), text: 'Profil culturel'),
            Tab(icon: Icon(Icons.translate), text: 'Expressions'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Sécurité & Santé'),
            Tab(icon: Icon(Icons.insights), text: 'Infos en direct'),
            Tab(icon: Icon(Icons.recommend), text: 'Recommandations'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _onAdd,
              child: const Icon(Icons.add),
            )
          : null,
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
    }
  }

  // Profil culturel
  Widget _buildProfilTab() {
    if (_profils.isEmpty) {
      return _buildEmpty('Aucun profil culturel');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _profils.length,
      itemBuilder: (context, i) {
        final p = _profils[i];
        return Card(
          child: ListTile(
            title: Text(p.pays),
            subtitle: Text(p.traditions, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: _isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
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

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nouveau profil' : 'Modifier profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Pays'), controller: paysCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Traditions'), controller: traditionsCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Gastronomie'), controller: gastronomieCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Comportements à adopter'), controller: adopterCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Comportements à éviter'), controller: eviterCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final item = ProfilCulturel(
                id: existing?.id,
                pays: paysCtrl.text.trim(),
                traditions: traditionsCtrl.text.trim(),
                gastronomie: gastronomieCtrl.text.trim(),
                comportementsAAdopter: adopterCtrl.text.trim(),
                comportementsAEviter: eviterCtrl.text.trim(),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Expressions locales
  Widget _buildExpressionTab() {
    if (_expressions.isEmpty) {
      return _buildEmpty('Aucune expression');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _expressions.length,
      itemBuilder: (context, i) {
        final e = _expressions[i];
        return Card(
          child: ListTile(
            title: Text('${e.langue} • ${e.expression}'),
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

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle expression' : 'Modifier expression'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Langue'), controller: langueCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Expression'), controller: expressionCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Traduction'), controller: traductionCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Catégorie'), controller: categorieCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final item = ExpressionLocale(
                id: existing?.id,
                langue: langueCtrl.text.trim(),
                expression: expressionCtrl.text.trim(),
                traduction: traductionCtrl.text.trim(),
                categorie: categorieCtrl.text.trim(),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Sécurité & Santé
  Widget _buildSecuriteTab() {
    if (_securites.isEmpty) {
      return _buildEmpty('Aucune fiche sécurité/santé');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _securites.length,
      itemBuilder: (context, i) {
        final s = _securites[i];
        return Card(
          child: ListTile(
            title: Text(s.pays),
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

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle fiche' : 'Modifier fiche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Pays'), controller: paysCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Vaccins recommandés'), controller: vaccinsCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Précautions générales'), controller: precautCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Zones à risque'), controller: zonesCtrl),
              TextField(decoration: const InputDecoration(labelText: 'Contact d\'urgence'), controller: urgenceCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final item = SecuriteSante(
                id: existing?.id,
                pays: paysCtrl.text.trim(),
                vaccinsRecommandes: vaccinsCtrl.text.trim(),
                precautionsGenerales: precautCtrl.text.trim(),
                zonesARisque: zonesCtrl.text.trim(),
                urgenceContact: urgenceCtrl.text.trim(),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  // Live tab
  Widget _buildLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
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
          Text('Taux de change', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromCtrl,
                  decoration: const InputDecoration(labelText: 'De (ex: USD)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _toCtrl,
                  decoration: const InputDecoration(labelText: 'Vers (ex: EUR)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Montant'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _convLoading ? null : _doConvert,
            child: _convLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Convertir'),
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

  // ————————————————————————————————————————————————
  // Recommandations (onglet 5)
  // ————————————————————————————————————————————————
  Widget _buildRecommendationsTab() {
    final interestPool = const [
      'gastronomie', 'traditions', 'musée', 'art', 'histoire', 'festival', 'marché', 'artisanat', 'sucré', 'fromage'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profil voyageur (simplifié)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _recCountryCtrl,
            decoration: const InputDecoration(
              labelText: 'Pays cible',
              hintText: 'Ex: France, Tunisia, UK, Türkiye...',
              prefixIcon: Icon(Icons.flag),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _recCountry = v,
          ),
          const SizedBox(height: 8),
          const Text('Intérêts:'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: interestPool.map((t) {
              final selected = _recInterests.contains(t);
              return FilterChip(
                label: Text(t),
                selected: selected,
                onSelected: (s) {
                  setState(() {
                    if (s) {
                      _recInterests.add(t);
                    } else {
                      _recInterests.remove(t);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _generateRecommendations,
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('Générer les recommandations'),
          ),

          const Divider(height: 24),

          if (_outActivities.isNotEmpty) ...[
            Text('Activités/Événements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._outActivities.map((a) => Card(
                  child: ListTile(
                    title: Text(a['title'] ?? ''),
                    subtitle: Text(
                        '${a['city'] ?? ''} • ${a['generic'] == true ? 'Général' : (a['country'] ?? '')} • ${(a['tags'] as List?)?.join(', ') ?? ''}'),
                    trailing: a['price'] != null ? Text('${a['price']} ${a['currency'] ?? ''}') : null,
                  ),
                )),
          ],

          if (_outDishes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Plats à essayer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._outDishes.map((d) => Card(
                  child: ListTile(
                    title: Text(d['name'] ?? ''),
                    subtitle: Text('${d['generic'] == true ? 'Général' : (d['country'] ?? '')} • ${(d['tags'] as List?)?.join(', ') ?? ''}'),
                  ),
                )),
          ],

          if (_outBehaviors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Comportements utiles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._outBehaviors.map((b) => Card(
                  child: ListTile(
                    leading: Icon(b['type'] == 'adopter' ? Icons.thumb_up : Icons.block,
                        color: b['type'] == 'adopter' ? Colors.green : Colors.red),
                    title: Text(b['text'] ?? ''),
                    subtitle: Text('${b['generic'] == true ? 'Général' : (b['country'] ?? '')} • ${(b['tags'] as List?)?.join(', ') ?? ''}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _generateRecommendations() {
    String norm(String input) {
      final s = (input.trim()).toLowerCase();
      if (s.isEmpty) return '';
      // France
      if (['france', 'fr', 'french'].contains(s)) return 'France';
      // Tunisia / Tunisie
      if (['tunisia', 'tunisie', 'tn'].contains(s)) return 'Tunisia';
      // England / UK
      if (['england', 'uk', 'united kingdom', 'gb', 'great britain', 'britain'].contains(s)) return 'England';
      // Turkey / Türkiye / Turkia
      if (['turkey', 'türkiye', 'turkiye', 'turkia', 'tr'].contains(s)) return 'Turkey';
      // Canada
      if (['canada', 'ca'].contains(s)) return 'Canada';
      // Default: Title case first letter
      return input[0].toUpperCase() + input.substring(1);
    }

    // Simple scoring: country must match, score = number of matching tags with interests
    int scoreItem(List tags) {
      if (tags.isEmpty) return 0;
      int s = 0;
      for (final t in tags) {
        if (_recInterests.contains(t)) s++;
      }
      return s;
    }

    List<Map<String, dynamic>> selectTop(List<Map<String, dynamic>> src, String country, {int top = 5}) {
      List<Map<String, dynamic>> filtered = src.where((e) => (e['country'] as String).toLowerCase() == country.toLowerCase()).toList();
      bool generic = false;
      if (filtered.isEmpty) {
        filtered = List<Map<String, dynamic>>.from(src);
        generic = true;
      }
      filtered.sort((a, b) {
        final at = (a['tags'] as List?) ?? const [];
        final bt = (b['tags'] as List?) ?? const [];
        final sa = scoreItem(at);
        final sb = scoreItem(bt);
        return sb.compareTo(sa);
      });
      final out = filtered.take(top).map((e) => Map<String, dynamic>.from(e)).toList();
      if (generic) {
        for (final e in out) {
          e['generic'] = true;
        }
      }
      return out;
    }

    setState(() {
      final country = norm(_recCountryCtrl.text.isEmpty ? _recCountry : _recCountryCtrl.text);
      _recCountry = country;
      _outActivities = selectTop(_recActivities, country, top: 5);
      _outDishes = selectTop(_recDishes, country, top: 5);
      _outBehaviors = selectTop(_recBehaviors, country, top: 6);
    });
  }
}
