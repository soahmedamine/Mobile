import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../database/database_helper_new.dart';
import '../services/bad_word_filter.dart';
import '../providers/alert_provider.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  Timer? _speechTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    if (widget.note != null) {
      _subjectController.text = widget.note![DatabaseHelper.columnSubject] ?? '';
      _messageController.text = widget.note![DatabaseHelper.columnMessage] ?? '';
      _imageData = widget.note![DatabaseHelper.columnImageData];
    }
  }
  
  @override
  void dispose() {
    _speechTimer?.cancel();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  // Initialize speech to text
  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = _speech.isListening;
        });
        if (status == 'done') {
          _stopListening();
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de reconnaissance vocale: $error')),
          );
        }
      },
    );
  }
  
  // Start listening to speech
  Future<void> _startListening(TextEditingController controller) async {
    try {
      if (!_isListening) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('Speech recognition status: $status');
            if (status == 'done') {
              _stopListening();
            }
          },
          onError: (error) {
            print('Speech recognition error: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $error')),
              );
            }
            _stopListening();
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
            _lastWords = '';
          });
          
          await _speech.listen(
            onResult: (result) {
              print('Speech recognition result: ${result.recognizedWords}');
              setState(() {
                _lastWords = result.recognizedWords;
                controller.text = _lastWords;
                
                // Reset the timer on each new word
                _speechTimer?.cancel();
                _speechTimer = Timer(const Duration(seconds: 3), _stopListening);
              });
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: true,
            localeId: 'fr_FR',
            listenMode: stt.ListenMode.dictation,
            onSoundLevelChange: (level) {
              // Optional: Add sound level visualization if needed
            },
          );
          
          // Auto-stop after 30 seconds of no speech
          _speechTimer = Timer(const Duration(seconds: 30), _stopListening);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La reconnaissance vocale n\'est pas disponible sur cet appareil'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in _startListening: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
      _stopListening();
    }
  }
  
  // Stop listening to speech
  Future<void> _stopListening() async {
    _speechTimer?.cancel();
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        print('Error stopping speech recognition: $e');
      }
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }
  
  // Speech to text functionality has been removed

  // Toggle speech input for a specific field
  Future<void> _toggleListening(TextEditingController controller) async {
    try {
      if (_isListening) {
        await _stopListening();
      } else {
        // Request microphone permission
        bool hasPermission = await _speech.hasPermission;
        
        if (!hasPermission) {
          hasPermission = await _speech.initialize();
        }
        
        if (hasPermission) {
          await _startListening(controller);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission du microphone non accordée'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error in _toggleListening: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
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

      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      
      if (widget.note != null) {
        // Update existing note
        note[DatabaseHelper.columnId] = widget.note![DatabaseHelper.columnId];
        await _dbHelper.updateNote(note);
        
        if (!mounted) return;
        
        // Add alert for updated note
        await alertProvider.addAlert(
          title: 'Note mise à jour',
          message: 'La note "${filteredSubject.isNotEmpty ? filteredSubject : 'Sans titre'}" a été mise à jour.',
          type: 'note',
          itemId: widget.note![DatabaseHelper.columnId].toString(),
          action: 'updated',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Note mise à jour avec succès!')),
        );
      } else {
        // Insert new note
        final id = await _dbHelper.insertNote(note);

        if (!mounted) return;
        _formKey.currentState!.reset();
        setState(() {
          _imageData = null;
        });

        // Add alert for new note
        await alertProvider.addAlert(
          title: 'Nouvelle note',
          message: 'Une nouvelle note a été créée : ${filteredSubject.isNotEmpty ? filteredSubject : 'Sans titre'}',
          type: 'note',
          itemId: id.toString(),
          action: 'added',
        );

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
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  color: _isListening ? Colors.red : Colors.blue,
                                ),
                                onPressed: () => _toggleListening(_messageController),
                                tooltip: _isListening ? 'Arrêter la dictée' : 'Dictée vocale',
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
                          if (_isListening) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Parlez maintenant...',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
