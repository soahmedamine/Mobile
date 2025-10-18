import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../services/image_service.dart';
import '../widgets/app_drawer.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final Event? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _venueController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'EUR');
  final _externalUrlController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isActive = true;
  bool _isLoading = false;
  String? _selectedImage;

  final EventService _eventService = EventService();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _cityController.text = event.city ?? '';
      _venueController.text = event.venue ?? '';
      _categoryController.text = event.category ?? '';
      _priceController.text = event.price?.toString() ?? '';
      _currencyController.text = event.currency ?? 'EUR';
      _externalUrlController.text = event.externalUrl ?? '';
      _startDate = event.startDate;
      _endDate = event.endDate;
      _startTime = event.startDate == null ? null : TimeOfDay.fromDateTime(event.startDate!);
      _endTime = event.endDate == null ? null : TimeOfDay.fromDateTime(event.endDate!);
      _isActive = event.isActive;
      _selectedImage = event.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate ?? DateTime.now() : _endDate ?? _startDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? _startTime ?? TimeOfDay.now();
    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String image) {
    if (_imageService.isBase64Image(image)) {
      final bytes = _imageService.getBase64ImageBytes(image);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      }
    }
    return Image.network(
      image,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 50),
        );
      },
    );
  }

  DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null) {
      return null;
    }
    final timeOfDay = time ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de début.')),
      );
      return;
    }

    final startDateTime = _combine(_startDate, _startTime);
    final endDateTime = _combine(_endDate, _endTime);
    if (endDateTime != null && startDateTime != null && endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être après la date de début.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = Event(
        id: widget.event?.id,
        remoteId: widget.event?.remoteId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        price: _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim()),
        currency: _currencyController.text.trim().isEmpty ? 'EUR' : _currencyController.text.trim().toUpperCase(),
        externalUrl: _externalUrlController.text.trim().isEmpty ? null : _externalUrlController.text.trim(),
        imageUrl: _selectedImage,
        isFavorite: widget.event?.isFavorite ?? false,
        isActive: _isActive,
      );

      await _eventService.saveEvent(event);

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMEEEEd('fr');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.event == null ? 'Nouvel événement' : 'Modifier l\'événement',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: AbsorbPointer(
            absorbing: _isLoading,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Titre de l'événement"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le titre est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Ville'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(labelText: 'Lieu précis'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Photo de l\'événement',
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de début'),
                              Row(
                                children: [
                                  Flexible(
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        _startDate == null ? 'Choisir une date' : dateFormat.format(_startDate!),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _pickDate(isStart: true),
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.access_time),
                                    label: Text(_startTime == null
                                        ? 'Heure'
                                        : _startTime!.format(context)),
                                    onPressed: () => _pickTime(isStart: true),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de fin (optionnel)'),
                              Row(
                                children: [
                                  Flexible(
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        _endDate == null ? 'Choisir une date' : dateFormat.format(_endDate!),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _pickDate(isStart: false),
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                        _endTime == null ? 'Heure' : _endTime!.format(context)),
                                    onPressed: () => _pickTime(isStart: false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(labelText: 'Devise'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _externalUrlController,
                      decoration: const InputDecoration(labelText: 'Lien externe'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      title: const Text('Événement actif'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: Text(widget.event == null ? 'Créer' : 'Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
