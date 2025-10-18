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
          title: const Text('Travel Budget Tracker'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.assessment), text: 'Overview'),
              Tab(icon: Icon(Icons.add_chart), text: 'Analytics'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildAnalyticsTab(),
            _buildSettingsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTransactionDialog(context),
          child: const Icon(Icons.add),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total Budget', style: TextStyle(fontSize: 18)),
                      Text(
                        '\$${totalBudget.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: totalBudget > 0 ? totalSpent / totalBudget : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Spent: \$${totalSpent.toStringAsFixed(2)}'),
                          Text('Remaining: \$${remainingBudget.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Prediction Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending Prediction',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Daily Average: \$${(prediction['dailyAverage'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Predicted Weekly Expense: \$${(prediction['predictedExpense'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Recent Transactions
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
          return const Center(
            child: Text('No expenses yet. Add your first transaction!'),
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
                height: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Spending by Category',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
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
              
              const SizedBox(height: 20),
              
              // Category Breakdown
              const Text(
                'Category Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...categoryTotals.entries.map((entry) => _buildCategoryRow(
                entry.key,
                entry.value,
                _getCategoryColor(entry.key),
              )),
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
          const Text(
            'Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            items: ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'TND']
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
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
          
          const SizedBox(height: 20),
          
          const Text(
            'Budget Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Configure your travel budget preferences here.'),
          
          const SizedBox(height: 20),
          
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export Data'),
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
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No transactions yet. Add your first transaction!'),
            ),
          );
        }
        
        final transactions = snapshot.data!.take(5).toList();
        
        return Column(
          children: transactions.map((transaction) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(transaction.category),
                child: Text(
                  transaction.category[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(transaction.category),
              subtitle: Text(
                '${transaction.description?.isNotEmpty == true ? '${transaction.description} • ' : ''}'
                '${DateFormat('MMM d, y').format(transaction.date)}',
              ),
              trailing: Text(
                '${transaction.type == 'expense' ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: transaction.type == 'expense' ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }
  
  Widget _buildCategoryRow(String category, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(category),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
