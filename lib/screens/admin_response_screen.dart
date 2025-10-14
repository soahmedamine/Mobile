import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper_new.dart';
import '../services/bad_word_filter.dart';
import 'home_screen.dart';

class AdminResponseScreen extends StatefulWidget {
  final Map<String, dynamic> reclamation;

  const AdminResponseScreen({
    super.key,
    required this.reclamation,
  });

  @override
  State<AdminResponseScreen> createState() => _AdminResponseScreenState();
}

class _AdminResponseScreenState extends State<AdminResponseScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final BadWordFilter _badWordFilter = BadWordFilter();
  final _responseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedStatus = 'new';
  bool _isSubmitting = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _selectedStatus = widget.reclamation[DatabaseHelper.columnStatus] ?? 'new';
    _responseController.text = widget.reclamation[DatabaseHelper.columnResponse] ?? '';
  }

  Future<void> _checkAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    setState(() {
      _isAdmin = role == 'admin';
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String _getString(String key, {String defaultValue = ''}) {
    final value = widget.reclamation[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  Future<void> _saveResponse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      // Filter bad words from the response
      final filteredResponse = _badWordFilter.filterText(_responseController.text.trim());
      
      // Check if bad words were detected
      if (_badWordFilter.containsBadWords(_responseController.text.trim()) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Attention: Des mots inappropriés ont été détectés et filtrés.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      final updatedReclamation = Map<String, dynamic>.from(widget.reclamation);
      updatedReclamation[DatabaseHelper.columnStatus] = _selectedStatus;
      updatedReclamation[DatabaseHelper.columnResponse] = filteredResponse;

      await _dbHelper.updateReclamation(updatedReclamation);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Only administrators can access this page.'),
        ),
      );
    }

    final subject = _getString(DatabaseHelper.columnSubject, defaultValue: 'No Subject');
    final message = _getString(DatabaseHelper.columnMessage, defaultValue: 'No Message');
    final name = _getString(DatabaseHelper.columnName, defaultValue: 'Not provided');
    final email = _getString(DatabaseHelper.columnEmail, defaultValue: 'Not provided');
    final dateStr = _getString(DatabaseHelper.columnDate);
    final date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
    final formattedDate = date != null
        ? DateFormat('MMM d, y • HH:mm').format(date)
        : 'No date';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          tooltip: 'Back to Home',
        ),
        title: const Text('Admin Response'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _saveResponse,
            tooltip: 'Save Response',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reclamation Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.report_problem, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Reclamation Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person, 'Name', name),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.email, 'Email', email),
                      const SizedBox(height: 16),
                      Text(
                        'Subject',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Message',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      // Show attachment if exists
                      if (widget.reclamation[DatabaseHelper.columnAttachment] != null &&
                          widget.reclamation[DatabaseHelper.columnAttachment].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Pièce jointe',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(widget.reclamation[DatabaseHelper.columnAttachment]),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Status Selection
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'new',
                    label: Text('New'),
                    icon: Icon(Icons.fiber_new),
                  ),
                  ButtonSegment<String>(
                    value: 'in_progress',
                    label: Text('In Progress'),
                    icon: Icon(Icons.pending),
                  ),
                  ButtonSegment<String>(
                    value: 'resolved',
                    label: Text('Resolved'),
                    icon: Icon(Icons.check_circle),
                  ),
                ],
                selected: {_selectedStatus},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedStatus = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Admin Response
              Text(
                'Admin Response',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _responseController,
                decoration: InputDecoration(
                  hintText: 'Enter your response to the user...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a response';
                  }
                  if (value.trim().length < 10) {
                    return 'Response must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _saveResponse,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Response'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
