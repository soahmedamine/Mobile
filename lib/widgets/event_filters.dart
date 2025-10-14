import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventFilters extends StatefulWidget {
  const EventFilters({
    super.key,
    this.onApply,
    this.onClear,
    this.initialKeyword,
    this.initialCity,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialFavoritesOnly = false,
    required this.cityProvider,
    required this.categoryProvider,
  });

  final void Function({
    String? keyword,
    String? city,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    bool? favoritesOnly,
  })? onApply;
  final VoidCallback? onClear;
  final String? initialKeyword;
  final String? initialCity;
  final String? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final bool initialFavoritesOnly;
  final Future<List<String>> Function() cityProvider;
  final Future<List<String>> Function() categoryProvider;

  @override
  State<EventFilters> createState() => _EventFiltersState();
}

class _EventFiltersState extends State<EventFilters> {
  late TextEditingController _keywordController;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _selectedCity;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _favoritesOnly = false;
  List<String> _cities = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.initialKeyword);
    _minPriceController = TextEditingController(text: widget.initialMinPrice?.toString());
    _maxPriceController = TextEditingController(text: widget.initialMaxPrice?.toString());
    _selectedCity = widget.initialCity;
    _selectedCategory = widget.initialCategory;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _favoritesOnly = widget.initialFavoritesOnly;
    _loadOptions();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.cityProvider(),
        widget.categoryProvider(),
      ]);
      setState(() {
        _cities = results[0];
        _categories = results[1];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _startDate == null || _endDate == null
          ? null
          : DateTimeRange(start: _startDate!, end: _endDate!),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyFilters() {
    widget.onApply?.call(
      keyword: _keywordController.text.trim().isEmpty ? null : _keywordController.text.trim(),
      city: _selectedCity?.isEmpty == true ? null : _selectedCity,
      category: _selectedCategory?.isEmpty == true ? null : _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      minPrice: _minPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_minPriceController.text.trim()),
      maxPrice: _maxPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_maxPriceController.text.trim()),
      favoritesOnly: _favoritesOnly,
    );
  }

  void _clearFilters() {
    setState(() {
      _keywordController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCity = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _favoritesOnly = false;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd('fr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtres', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            labelText: 'Recherche (mot-clé, ville, catégorie)',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                value: _selectedCity,
                decoration: const InputDecoration(labelText: 'Ville'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Toutes les villes')),
                  ..._cities.map((city) => DropdownMenuItem<String?>(value: city, child: Text(city))).toList(),
                ],
                onChanged: (value) => setState(() => _selectedCity = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Toutes les catégories')),
                  ..._categories.map((category) => DropdownMenuItem<String?>(value: category, child: Text(category))).toList(),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix minimum'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix maximum'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(context),
                icon: const Icon(Icons.date_range),
                label: Text(
                  _startDate == null || _endDate == null
                      ? 'Sélectionner une période'
                      : '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _favoritesOnly,
                onChanged: (value) => setState(() => _favoritesOnly = value ?? false),
                title: const Text('Favoris uniquement'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Appliquer'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Réinitialiser'),
            ),
          ],
        ),
      ],
    );
  }
}
