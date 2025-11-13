import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';
import 'home_screen.dart';

class BudgetScreen extends StatefulWidget {
  final String travelId;
  
  const BudgetScreen({Key? key, required this.travelId}) : super(key: key);

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  late Future<Map<String, dynamic>> _budgetData;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _amountController = TextEditingController();
  String _selectedCategory = budgetCategories.first;
  String _selectedType = 'expense';
  String _description = '';
  String _selectedCurrency = 'USD';
  DateTime _selectedDate = DateTime.now();
  
  // Tabs
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBudgetData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  void _loadBudgetData() {
    setState(() {
      _budgetData = _getBudgetData();
    });
  }
  
  Future<Map<String, dynamic>> _getBudgetData() async {
    final categoryTotals = await _budgetService.getCategoryTotals(widget.travelId);
    final totalSpent = await _budgetService.getTotalSpent(widget.travelId);
    final totalBudget = await _budgetService.getTotalBudget(widget.travelId);
    final prediction = await _budgetService.predictFutureExpenses(widget.travelId, 7);
    
    return {
      'categoryTotals': categoryTotals,
      'totalSpent': totalSpent,
      'totalBudget': totalBudget,
      'prediction': prediction,
    };
  }
  
  Future<void> _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      final budget = Budget(
        travelId: widget.travelId,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        date: _selectedDate,
        description: _description,
        type: _selectedType,
      );
      
      await _budgetService.insertBudget(budget);
      if (!mounted) return;
      
      // Reset form
      _amountController.clear();
      _description = '';
      _selectedCategory = budgetCategories.first;
      _selectedType = 'expense';
      
      // Refresh data
      _loadBudgetData();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
            'Gestion Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.assessment), text: 'Aperçu'),
              Tab(icon: Icon(Icons.add_chart), text: 'Analyse'),
              Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[800]!, Colors.blue[500]!, Colors.blue[200]!],
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTransactionDialog(context),
          icon: const Icon(Icons.add, size: 24.0),
          label: const Text('Ajouter'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[700],
          elevation: 4,
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _budgetData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        final totalSpent = data['totalSpent'] as double;
        final totalBudget = data['totalBudget'] as double;
        final remainingBudget = totalBudget - totalSpent;
        final prediction = data['prediction'] as Map<String, dynamic>;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Budget Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 28),
                          const SizedBox(width: 8),
                          const Text('Budget Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\$${totalBudget.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalBudget > 0 ? totalSpent / totalBudget : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dépensé', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Restant', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '\$${remainingBudget.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Prediction Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.orange[700], size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'Prévision de Dépenses',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Moyenne Journalière:',
                              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            ),
                            Text(
                              '\$${(prediction['dailyAverage'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prévision Hebdomadaire:',
                              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            ),
                            Text(
                              '\$${(prediction['predictedExpense'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Recent Transactions
              Row(
                children: [
                  Icon(Icons.history, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Transactions Récentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentTransactions(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _budgetData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        final categoryTotals = data['categoryTotals'] as Map<String, double>;
        
        if (categoryTotals.isEmpty) {
          return Center(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune dépense',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez votre première transaction!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Prepare data for pie chart
        final pieChartSections = categoryTotals.entries.map((entry) {
          return PieChartSectionData(
            color: _getCategoryColor(entry.key),
            value: entry.value,
            title: '\$${entry.value.toStringAsFixed(0)}',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Pie Chart
              SizedBox(
                height: 320,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart, color: Colors.blue[700], size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Dépenses par Catégorie',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Category Breakdown
              Row(
                children: [
                  Icon(Icons.category, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Détails par Catégorie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: categoryTotals.entries.map((entry) => _buildCategoryRow(
                      entry.key,
                      entry.value,
                      _getCategoryColor(entry.key),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.blue[700], size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Devise',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'TND']
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency, style: const TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Budget Settings Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.orange[700], size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Paramètres Budget',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Configurez vos préférences de budget de voyage ici.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.green[700], size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Gestion des Données',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement export functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité d\'export bientôt disponible!')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Exporter les Données', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentTransactions() {
    return FutureBuilder<List<Budget>>(
      future: _budgetService.getBudgets(widget.travelId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajoutez votre première transaction!',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        
        final transactions = snapshot.data!.take(5).toList();
        
        return Column(
          children: transactions.map((transaction) => Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(transaction.category),
                radius: 24,
                child: Text(
                  transaction.category[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                transaction.category,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                '${transaction.description?.isNotEmpty == true ? '${transaction.description} • ' : ''}'
                '${DateFormat('MMM d, y').format(transaction.date)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: transaction.type == 'expense' ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${transaction.type == 'expense' ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: transaction.type == 'expense' ? Colors.red[700] : Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }
  
  Widget _buildCategoryRow(String category, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.9), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    
    final index = budgetCategories.indexOf(category);
    return index != -1 ? colors[index % colors.length] : Colors.grey;
  }
  
  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Type selector (Income/Expense)
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Expense'),
                              value: 'expense',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Income'),
                              value: 'income',
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: budgetCategories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date picker
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM d, y').format(_selectedDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _description = value;
                        },
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _addTransaction();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
