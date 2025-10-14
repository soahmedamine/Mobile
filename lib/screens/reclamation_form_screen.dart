import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper_new.dart';
import '../services/bad_word_filter.dart';
import 'chat_screen_new.dart';
import '../widgets/app_drawer.dart';

class ReclamationFormScreen extends StatefulWidget {
  const ReclamationFormScreen({super.key});

  @override
  ReclamationFormScreenState createState() => ReclamationFormScreenState();
}

class ReclamationFormScreenState extends State<ReclamationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final _badWordFilter = BadWordFilter();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  String? _attachmentBase64;
  String? _attachmentFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachmentBase64 = base64Encode(bytes);
          _attachmentFileName = image.name;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📎 Image ajoutée: ${image.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentBase64 = null;
      _attachmentFileName = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      // Filter bad words from subject and message
      final filteredSubject = _badWordFilter.filterText(_subjectController.text.trim());
      final filteredMessage = _badWordFilter.filterText(_messageController.text.trim());
      
      // Check if bad words were detected
      final hadBadWords = _badWordFilter.containsBadWords(_subjectController.text.trim()) ||
                          _badWordFilter.containsBadWords(_messageController.text.trim());
      
      final reclamation = {
        DatabaseHelper.columnName: _nameController.text.trim(),
        DatabaseHelper.columnEmail: _emailController.text.trim(),
        DatabaseHelper.columnSubject: filteredSubject,
        DatabaseHelper.columnMessage: filteredMessage,
        DatabaseHelper.columnDate: DateTime.now().toIso8601String(),
        DatabaseHelper.columnStatus: 'new',
        DatabaseHelper.columnAttachment: _attachmentBase64,
      };

      await _dbHelper.insertReclamation(reclamation);

      if (!mounted) return;
      _formKey.currentState!.reset();
      setState(() {
        _attachmentBase64 = null;
        _attachmentFileName = null;
      });

      // Show different message based on bad word detection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hadBadWords 
              ? '⚠️ Réclamation soumise! Attention: des mots inappropriés ont été filtrés (remplacés par ***).'
              : '✅ Votre réclamation a été soumise avec succès!',
          ),
          backgroundColor: hadBadWords ? Colors.orange : Colors.green,
          duration: Duration(seconds: hadBadWords ? 5 : 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle Réclamation'),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: 'Assistance',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.travel_explore),
              tooltip: 'Culture & Infos Locales',
              onPressed: () => Navigator.pushNamed(context, '/culture'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Déconnexion',
              onPressed: _logout,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Veuillez entrer votre nom' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Sujet',
                    prefixIcon: Icon(Icons.subject),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Veuillez entrer un sujet' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre message';
                    }
                    if (value.length < 10) {
                      return 'Le message doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Attachment section
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Ajouter une pièce jointe (image)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                
                // Show attached file preview
                if (_attachmentBase64 != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.image, color: Colors.blue),
                      title: Text(_attachmentFileName ?? 'Image'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _removeAttachment,
                        tooltip: 'Supprimer',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(_attachmentBase64!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Soumettre la réclamation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
