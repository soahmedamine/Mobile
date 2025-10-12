import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import '../models/travel.dart';
import '../services/pdf_service.dart';
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
              title: const Text('Edit Travel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: destController,
                      decoration: const InputDecoration(labelText: 'Destination'),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
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
                              decoration: const InputDecoration(
                                labelText: 'Date de départ',
                              ),
                              child: Text(
                                editDateDepart != null
                                    ? "${editDateDepart!.day}/${editDateDepart!.month}/${editDateDepart!.year}"
                                    : 'Select Date',
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
                              decoration: const InputDecoration(
                                labelText: 'Date de retour',
                              ),
                              child: Text(
                                editDateRetour != null
                                    ? "${editDateRetour!.day}/${editDateRetour!.month}/${editDateRetour!.year}"
                                    : 'Select Date',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: prixController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prix'),
                    ),
                    TextField(
                      controller: placesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Places disponibles'),
                    ),
                    TextField(
                      controller: transportController,
                      decoration: const InputDecoration(labelText: 'Transport'),
                    ),
                    TextField(
                      controller: hebergementController,
                      decoration: const InputDecoration(labelText: 'Hébergement'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Save'),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Travel'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Formulaire
              Card(
                color: Colors.blue[50],
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: destController,
                        decoration: const InputDecoration(
                          labelText: 'Destination',
                          prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => pickDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date de départ',
                                  prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                                ),
                                child: Text(
                                  dateDepart != null
                                      ? "${dateDepart!.day}/${dateDepart!.month}/${dateDepart!.year}"
                                      : 'Choisir une date',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => pickDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date de retour',
                                  prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                                ),
                                child: Text(
                                  dateRetour != null
                                      ? "${dateRetour!.day}/${dateRetour!.month}/${dateRetour!.year}"
                                      : 'Choisir une date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: prixController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prix',
                          prefixIcon: Icon(Icons.attach_money, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: placesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Places disponibles',
                          prefixIcon: Icon(Icons.event_seat, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: transportController,
                        decoration: const InputDecoration(
                          labelText: 'Transport',
                          prefixIcon: Icon(Icons.directions_bus, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: hebergementController,
                        decoration: const InputDecoration(
                          labelText: 'Hébergement',
                          prefixIcon: Icon(Icons.hotel, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
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
                            id: null, // Will be set by the database
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
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un voyage'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
    );
  }
}
