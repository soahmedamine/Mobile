import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper_new.dart';
import '../services/bad_word_filter.dart';

class NoteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? note; // For editing existing notes
  
  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final _badWordFilter = BadWordFilter();

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  String? _imageData;
  final _imagePicker = ImagePicker();
  
  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentLocale = 'en_US';
  String _listeningFor = ''; // 'subject' or 'message'

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    if (widget.note != null) {
      _subjectController.text = widget.note![DatabaseHelper.columnSubject] ?? '';
      _messageController.text = widget.note![DatabaseHelper.columnMessage] ?? '';
      _imageData = widget.note![DatabaseHelper.columnImageData];
    }
  }
  
  Future<void> _initSpeech() async {
    // Request microphone permission
    PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Permission microphone refusée. La reconnaissance vocale ne fonctionnera pas.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${error.errorMsg}')),
            );
          }
        },
      );
      
      if (_speechAvailable) {
        // Get available locales
        final locales = await _speech.locales();
        // Try to find French locale, otherwise use default
        final frenchLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('fr'),
          orElse: () => locales.first,
        );
        setState(() {
          _currentLocale = frenchLocale.localeId;
        });
      }
    } catch (e) {
      print('Speech initialization error: $e');
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _startListening(String field) async {
    // Check permission again before starting
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Permission microphone requise pour la reconnaissance vocale.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ La reconnaissance vocale n\'est pas disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isListening = true;
      _listeningFor = field;
    });
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          if (field == 'subject') {
            _subjectController.text = result.recognizedWords;
          } else if (field == 'message') {
            _messageController.text = result.recognizedWords;
          }
        });
      },
      localeId: _currentLocale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }
  
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _listeningFor = '';
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageData = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageData = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_email') ?? '';

      // Filter bad words from text inputs
      final filteredSubject = _badWordFilter.filterText(_subjectController.text.trim());
      final filteredMessage = _badWordFilter.filterText(_messageController.text.trim());
      
      // Check if bad words were detected
      final hasBadWords = _badWordFilter.containsBadWords(_subjectController.text.trim()) ||
                          _badWordFilter.containsBadWords(_messageController.text.trim());
      
      if (hasBadWords && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Attention: Des mots inappropriés ont été détectés et filtrés.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      final note = {
        DatabaseHelper.columnUserId: userId,
        DatabaseHelper.columnSubject: filteredSubject,
        DatabaseHelper.columnMessage: filteredMessage,
        DatabaseHelper.columnStatus: 'active',
        DatabaseHelper.columnImageData: _imageData,
      };

      if (widget.note != null) {
        // Update existing note
        note[DatabaseHelper.columnId] = widget.note![DatabaseHelper.columnId];
        await _dbHelper.updateNote(note);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Note mise à jour avec succès!')),
        );
      } else {
        // Insert new note
        await _dbHelper.insertNote(note);

        if (!mounted) return;
        _formKey.currentState!.reset();
        setState(() {
          _imageData = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Note créée avec succès!')),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: Text(
          isEditing ? 'Modifier la Note' : 'Nouvelle Note',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[800]!,
              Colors.blue[500]!,
              Colors.blue[200]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 48,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isEditing ? 'Modifier votre note' : 'Créer une nouvelle note',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEditing 
                              ? 'Mettez à jour les informations de votre note'
                              : 'Enregistrez vos idées et pensées importantes',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject Field
                          TextFormField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              labelText: 'Sujet *',
                              hintText: 'Le titre de votre note',
                              prefixIcon: const Icon(Icons.title),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningFor == 'subject'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color: _isListening && _listeningFor == 'subject'
                                      ? Colors.red
                                      : Colors.blue[700],
                                ),
                                onPressed: () {
                                  if (_isListening && _listeningFor == 'subject') {
                                    _stopListening();
                                  } else {
                                    _startListening('subject');
                                  }
                                },
                                tooltip: 'Dictée vocale',
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLength: 500,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le sujet est obligatoire';
                              }
                              if (value.trim().length < 3) {
                                return 'Le sujet doit contenir au moins 3 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Message Field
                          TextFormField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              labelText: 'Message *',
                              hintText: 'Décrivez votre note en détail',
                              prefixIcon: const Icon(Icons.message),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isListening && _listeningFor == 'message'
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color: _isListening && _listeningFor == 'message'
                                      ? Colors.red
                                      : Colors.blue[700],
                                ),
                                onPressed: () {
                                  if (_isListening && _listeningFor == 'message') {
                                    _stopListening();
                                  } else {
                                    _startListening('message');
                                  }
                                },
                                tooltip: 'Dictée vocale',
                              ),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 8,
                            maxLength: 5000,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le message est obligatoire';
                              }
                              if (value.trim().length < 10) {
                                return 'Le message doit contenir au moins 10 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Image Section
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Image (optionnel)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (_imageData != null)
                                TextButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete, size: 20),
                                  label: const Text('Supprimer'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (_imageData != null)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(_imageData!),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Ajouter une image'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Mettre à jour' : 'Créer la note',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
