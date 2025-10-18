import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import '../models/travel.dart';
import '../services/pdf_service.dart';
import 'home_screen.dart';
import '../widgets/app_drawer.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({Key? key}) : super(key: key);

  @override
  _TravelScreenState createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final TravelService travelService = TravelService();
  bool _isLoading = false;
  List<Travel> travels = [];

  final TextEditingController destController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController prixController = TextEditingController();
  final TextEditingController placesController = TextEditingController();
  final TextEditingController transportController = TextEditingController();
  final TextEditingController hebergementController = TextEditingController();

  DateTime? dateDepart;
  DateTime? dateRetour;

  @override
  void initState() {
    super.initState();
    loadTravels();
  }

  Future<void> loadTravels() async {
    setState(() => _isLoading = true);
    try {
      final data = await travelService.getTravels();
      setState(() {
        travels = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading travels: $e')),
      );
    }
  }

  void clearControllers() {
    destController.clear();
    descController.clear();
    prixController.clear();
    placesController.clear();
    transportController.clear();
    hebergementController.clear();
    dateDepart = null;
    dateRetour = null;
  }

  Future<void> _editTravel(Travel travel) async {
    // Create local controllers for the dialog
    final destController = TextEditingController(text: travel.destination);
    final descController = TextEditingController(text: travel.description);
    final prixController = TextEditingController(text: travel.prix.toString());
    final placesController = TextEditingController(text: travel.placesDisponibles.toString());
    final transportController = TextEditingController(text: travel.transport);
    final hebergementController = TextEditingController(text: travel.hebergement);
    DateTime? editDateDepart = travel.dateDepart;
    DateTime? editDateRetour = travel.dateRetour;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Edit Travel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: destController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: editDateDepart ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setState(() => editDateDepart = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date de départ',
                                prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                editDateDepart != null
                                    ? "${editDateDepart!.day}/${editDateDepart!.month}/${editDateDepart!.year}"
                                    : 'Select Date',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: editDateRetour ?? DateTime.now(),
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setState(() => editDateRetour = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date de retour',
                                prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                editDateRetour != null
                                    ? "${editDateRetour!.day}/${editDateRetour!.month}/${editDateRetour!.year}"
                                    : 'Select Date',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: prixController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prix (DT)',
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Places disponibles',
                        prefixIcon: const Icon(Icons.event_seat, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: transportController,
                      decoration: InputDecoration(
                        labelText: 'Transport',
                        prefixIcon: const Icon(Icons.directions_bus, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hebergementController,
                      decoration: InputDecoration(
                        labelText: 'Hébergement',
                        prefixIcon: const Icon(Icons.hotel, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (destController.text.isEmpty ||
                        descController.text.isEmpty ||
                        editDateDepart == null ||
                        editDateRetour == null ||
                        prixController.text.isEmpty ||
                        placesController.text.isEmpty ||
                        transportController.text.isEmpty ||
                        hebergementController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    final updatedTravel = Travel(
                      id: travel.id,
                      destination: destController.text,
                      description: descController.text,
                      dateDepart: editDateDepart!,
                      dateRetour: editDateRetour!,
                      prix: double.parse(prixController.text),
                      placesDisponibles: int.parse(placesController.text),
                      transport: transportController.text,
                      hebergement: hebergementController.text,
                    );

                    await travelService.updateTravel(updatedTravel);
                    loadTravels();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> pickDate(BuildContext context, bool isDepart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDepart) {
          dateDepart = picked;
        } else {
          dateRetour = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[500]!, Colors.blue[200]!],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
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
          'Smart Travel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[800]!, Colors.blue[500]!, Colors.blue[200]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Formulaire
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: destController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Destination',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.location_on, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.description, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => pickDate(context, true),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date de départ',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                      ),
                                    ),
                                    child: Text(
                                      dateDepart != null
                                          ? "${dateDepart!.day}/${dateDepart!.month}/${dateDepart!.year}"
                                          : 'Choisir une date',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => pickDate(context, false),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Date de retour',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                                      ),
                                    ),
                                    child: Text(
                                      dateRetour != null
                                          ? "${dateRetour!.day}/${dateRetour!.month}/${dateRetour!.year}"
                                          : 'Choisir une date',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: prixController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Prix',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.attach_money, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: placesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Places disponibles',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.event_seat, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: transportController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Transport',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.directions_bus, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: hebergementController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Hébergement',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                              prefixIcon: const Icon(Icons.hotel, color: Colors.white),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF0F0F0)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                if (destController.text.isEmpty ||
                                    descController.text.isEmpty ||
                                    dateDepart == null ||
                                    dateRetour == null ||
                                    prixController.text.isEmpty ||
                                    placesController.text.isEmpty ||
                                    transportController.text.isEmpty ||
                                    hebergementController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez remplir tous les champs')),
                                  );
                                  return;
                                }

                                final travel = Travel(
                                  id: null,
                                  destination: destController.text,
                                  description: descController.text,
                                  dateDepart: dateDepart!,
                                  dateRetour: dateRetour!,
                                  prix: double.parse(prixController.text),
                                  placesDisponibles: int.parse(placesController.text),
                                  transport: transportController.text,
                                  hebergement: hebergementController.text,
                                );

                                await travelService.insertTravel(travel);
                                clearControllers();
                                loadTravels();
                              },
                              icon: Icon(Icons.add, color: Colors.blue[700]),
                              label: Text('Ajouter un voyage', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              // Liste des voyages
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: travels.length,
                itemBuilder: (context, index) {
                  final t = travels[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.blue[50],
                    child: ListTile(
                      title: Text(t.destination,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      subtitle: Text(
                        '${t.description}\n'
                            '${t.dateDepart.day}/${t.dateDepart.month}/${t.dateDepart.year} - '
                            '${t.dateRetour.day}/${t.dateRetour.month}/${t.dateRetour.year}\n'
                            'Prix: ${t.prix} | Places: ${t.placesDisponibles}\n'
                            'Transport: ${t.transport} | Hébergement: ${t.hebergement}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              _editTravel(t);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await travelService.deleteTravel(t.id!);
                              loadTravels();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                            onPressed: () {
                              PdfService().generateTravelPdf(t);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
