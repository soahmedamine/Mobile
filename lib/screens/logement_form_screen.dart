import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/logement.dart';
import '../services/logement_service.dart';
import '../services/image_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/location_picker_widget.dart';

class LogementFormScreen extends StatefulWidget {
  final Logement? logement;

  const LogementFormScreen({super.key, this.logement});

  @override
  State<LogementFormScreen> createState() => _LogementFormScreenState();
}

class _LogementFormScreenState extends State<LogementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LogementService _logementService = LogementService();
  final ImageService _imageService = ImageService();

  late TextEditingController _nomController;
  late TextEditingController _adresseController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;
  late TextEditingController _chambresController;
  late TextEditingController _capaciteController;
  late TextEditingController _imageUrlController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _noteController;

  String _selectedType = 'hotel';
  bool _disponible = true;
  List<String> _selectedCommodites = [];
  String? _selectedImage;

  // Pour stocker les coordonnées de la carte
  double? _latitude;
  double? _longitude;

  final List<String> _types = ['hotel', 'airbnb', 'appartement', 'maison'];
  final List<String> _commoditesOptions = [
    'WiFi',
    'Parking',
    'Piscine',
    'Restaurant',
    'Spa',
    'Climatisation',
    'Cuisine équipée',
    'Jardin',
    'Terrasse',
    'Balcon',
    'Plage privée',
    'Bar',
    'Animation',
    'Ascenseur',
  ];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.logement?.nom ?? '');
    _adresseController = TextEditingController(text: widget.logement?.adresse ?? '');
    _descriptionController = TextEditingController(text: widget.logement?.description ?? '');
    _prixController = TextEditingController(
      text: widget.logement?.prixParNuit.toString() ?? '',
    );
    _chambresController = TextEditingController(
      text: widget.logement?.nombreChambres.toString() ?? '',
    );
    _capaciteController = TextEditingController(
      text: widget.logement?.capacitePersonnes.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: widget.logement?.imageUrl ?? '');
    _telephoneController = TextEditingController(text: widget.logement?.telephone ?? '');
    _emailController = TextEditingController(text: widget.logement?.email ?? '');
    _noteController = TextEditingController(text: widget.logement?.note?.toString() ?? '');

    if (widget.logement != null) {
      _selectedType = widget.logement!.type;
      _disponible = widget.logement!.disponible;
      _selectedCommodites = List.from(widget.logement!.commodites);
      _selectedImage = widget.logement!.imageUrl;
      _latitude = widget.logement!.latitude;
      _longitude = widget.logement!.longitude;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _chambresController.dispose();
    _capaciteController.dispose();
    _imageUrlController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imageService.pickImageFromGallery();
                if (image != null) {
                  setState(() => _selectedImage = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _imageService.takePhoto();
                if (image != null) {
                  setState(() => _selectedImage = image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Entrer une URL'),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer l\'image', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final controller = TextEditingController(text: _imageUrlController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL de l\'image'),
        content: TextField(
          controller: controller,
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
            onPressed: () {
              setState(() {
                _selectedImage = controller.text;
                _imageUrlController.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLogement() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que les coordonnées sont définies
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un emplacement sur la carte')),
      );
      return;
    }

    try {
      final logement = Logement(
        id: widget.logement?.id,
        nom: _nomController.text,
        type: _selectedType,
        adresse: _adresseController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        description: _descriptionController.text,
        prixParNuit: double.parse(_prixController.text),
        nombreChambres: int.parse(_chambresController.text),
        capacitePersonnes: int.parse(_capaciteController.text),
        imageUrl: _selectedImage,
        commodites: _selectedCommodites,
        note: _noteController.text.isEmpty ? null : double.parse(_noteController.text),
        telephone: _telephoneController.text.isEmpty ? null : _telephoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        disponible: _disponible,
        dateAjout: widget.logement?.dateAjout,
      );

      if (widget.logement == null) {
        await _logementService.insertLogement(logement);
      } else {
        await _logementService.updateLogement(logement);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.logement == null
                  ? 'Logement ajouté avec succès'
                  : 'Logement modifié avec succès',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.logement == null ? 'Ajouter un logement' : 'Modifier le logement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveLogement,
          ),
        ],
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            // Type
            const Text(
              'Type de logement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),

            const SizedBox(height: 16),

            // Nom
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du logement *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une adresse';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Carte interactive pour sélectionner l'emplacement (REMPLACE les champs latitude/longitude)
            LocationPickerWidget(
              initialLatitude: _latitude,
              initialLongitude: _longitude,
              onLocationSelected: (lat, lng) {
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                });
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Prix
            TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(
                labelText: 'Prix par nuit (DT) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un prix';
                }
                if (double.tryParse(value) == null) {
                  return 'Prix invalide';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Chambres et capacité
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chambresController,
                    decoration: const InputDecoration(
                      labelText: 'Chambres *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _capaciteController,
                    decoration: const InputDecoration(
                      labelText: 'Capacité *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Photo du logement (déplacé ici)
            const Text(
              'Photo du logement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(_selectedImage!),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'Ajouter une photo',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (0-5)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final note = double.tryParse(value);
                  if (note == null || note < 0 || note > 5) {
                    return 'Note invalide (0-5)';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Téléphone et Email
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // Commodités
            const Text(
              'Commodités',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commoditesOptions.map((commodite) {
                final isSelected = _selectedCommodites.contains(commodite);
                return FilterChip(
                  label: Text(commodite),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCommodites.add(commodite);
                      } else {
                        _selectedCommodites.remove(commodite);
                      }
                    });
                  },
                  selectedColor: Colors.teal[100],
                  checkmarkColor: Colors.teal,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Disponibilité
            SwitchListTile(
              title: const Text('Disponible'),
              subtitle: Text(_disponible ? 'Le logement est disponible' : 'Le logement n\'est pas disponible'),
              value: _disponible,
              onChanged: (value) {
                setState(() => _disponible = value);
              },
              activeColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: _saveLogement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.logement == null ? 'Ajouter le logement' : 'Enregistrer les modifications',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'hotel':
        return 'Hôtel';
      case 'airbnb':
        return 'Airbnb';
      case 'appartement':
        return 'Appartement';
      case 'maison':
        return 'Maison';
      default:
        return type;
    }
  }

  Widget _buildImageWidget(String image) {
    if (_imageService.isBase64Image(image)) {
      // Image base64
      final bytes = _imageService.getBase64ImageBytes(image);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }

    // Image URL
    return Image.network(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.error, color: Colors.red));
      },
    );
  }
}
