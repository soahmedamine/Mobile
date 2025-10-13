import 'package:flutter/material.dart';
import '../../../models/expense_model.dart';

class BudgetTracker extends StatelessWidget {
  final double totalBudget;
  final List<Expense> expenses;
  final VoidCallback onAddExpense;

  const BudgetTracker({
    Key? key,
    required this.totalBudget,
    required this.expenses,
    required this.onAddExpense,
  }) : super(key: key);

  double get totalExpenses {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get remainingBudget {
    return totalBudget - totalExpenses;
  }

  double get progressPercentage {
    return totalBudget > 0 ? (totalExpenses / totalBudget) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: onAddExpense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercentage > 0.8 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetItem('Total Budget', '\$${totalBudget.toStringAsFixed(2)}', Colors.blue),
                _buildBudgetItem('Spent', '\$${totalExpenses.toStringAsFixed(2)}', Colors.orange),
                _buildBudgetItem('Remaining', '\$${remainingBudget.toStringAsFixed(2)}',
                    remainingBudget >= 0 ? Colors.green : Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            if (expenses.isNotEmpty) ...[
              const Text(
                'Recent Expenses:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...expenses.take(3).map((expense) => _buildExpenseItem(expense)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return ListTile(
      leading: const Icon(Icons.money_off, color: Colors.red),
      title: Text(expense.description),
      subtitle: Text(expense.category),
      trailing: Text(
        '\$${expense.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      dense: true,
    );
  }
}