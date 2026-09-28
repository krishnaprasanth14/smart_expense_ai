import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_expense_screen.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> expenseData;

  const ExpenseDetailsScreen({
    super.key,
    required this.documentId,
    required this.expenseData,
  });

  String formatAmount(dynamic amount) {
    final double value = (amount as num?)?.toDouble() ?? 0.0;
    return '₹${value.toStringAsFixed(2)}';
  }

  String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'shopping':
        return '🛍️';
      case 'travel':
        return '✈️';
      case 'bills':
        return '💡';
      case 'entertainment':
        return '🎬';
      case 'health':
        return '❤️';
      default:
        return '💰';
    }
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'shopping':
        return Colors.pinkAccent;
      case 'travel':
        return Colors.blueAccent;
      case 'bills':
        return Colors.amber;
      case 'entertainment':
        return Colors.purpleAccent;
      case 'health':
        return Colors.redAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  Future<void> deleteExpense(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151827),
          title: const Text(
            'Delete Expense?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this expense?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(documentId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting expense: $e'),
          ),
        );
      }
    }
  }

  void editExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          documentId: documentId,
          expenseData: expenseData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        expenseData['title']?.toString() ?? 'Expense';

    final String category =
        expenseData['category']?.toString() ?? 'Other';

    final String date =
        expenseData['date']?.toString() ?? 'Unknown date';

    final Color categoryColor =
    getCategoryColor(category);

    return Scaffold(
      backgroundColor: const Color(0xFF080A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080A14),
        elevation: 0,
        title: const Text(
          'Expense Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => editExpense(context),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => deleteExpense(context),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Expense icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  getCategoryIcon(category),
                  style: const TextStyle(
                    fontSize: 45,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Amount
            Text(
              formatAmount(expenseData['amount']),
              style: TextStyle(
                color: categoryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111425),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.category_outlined,
                    title: 'Category',
                    value: category,
                    iconColor: categoryColor,
                  ),
                  const Divider(
                    color: Colors.white12,
                    height: 30,
                  ),
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    value: date,
                    iconColor: Colors.blueAccent,
                  ),
                  const Divider(
                    color: Colors.white12,
                    height: 30,
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    title: 'Amount',
                    value: formatAmount(
                      expenseData['amount'],
                    ),
                    iconColor: Colors.greenAccent,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Edit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => editExpense(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Edit Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Delete button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => deleteExpense(context),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Delete Expense',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}