import 'package:flutter/material.dart';
import '../../../models/expense_model.dart';

class BudgetTracker extends StatelessWidget {
  final double totalBudget;
  final double totalExpenses;
  final VoidCallback onAddExpense;

  const BudgetTracker({
    Key? key,
    required this.totalBudget,
    required this.totalExpenses,
    required this.onAddExpense, required List expenses,
  }) : super(key: key);

  double get remainingBudget => totalBudget - totalExpenses;
  double get progressPercentage => totalBudget > 0 ? (totalExpenses / totalBudget) : 0;
  bool get isOverBudget => remainingBudget < 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Suivi du Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_chart, color: Colors.blue),
                  onPressed: onAddExpense,
                  tooltip: 'Ajouter une dépense',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: progressPercentage > 1 ? 1 : progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red :
                progressPercentage > 0.8 ? Colors.orange : Colors.green,
              ),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),

            // Progress Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(1)}% utilisé',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'Dépassement!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Numbers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBudgetItem(
                  'Budget Total',
                  '\$${totalBudget.toStringAsFixed(2)}',
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
                _buildBudgetItem(
                  'Dépensé',
                  '\$${totalExpenses.toStringAsFixed(2)}',
                  Colors.orange,
                  Icons.money_off,
                ),
                _buildBudgetItem(
                  'Reste',
                  '\$${remainingBudget.abs().toStringAsFixed(2)}',
                  isOverBudget ? Colors.red : Colors.green,
                  isOverBudget ? Icons.warning : Icons.savings,
                ),
              ],
            ),

            // Warning Message
            if (isOverBudget) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention! Vous avez dépassé votre budget de \$${remainingBudget.abs().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}