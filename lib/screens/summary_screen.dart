import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        backgroundColor: const Color(0xFF080A14),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load expenses',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final expenses = snapshot.data?.docs ?? [];

          double total = 0;
          double food = 0;
          double shopping = 0;
          double transport = 0;
          double other = 0;

          final now = DateTime.now();

          for (final doc in expenses) {
            final data = doc.data() as Map<String, dynamic>;

            final amount =
                (data['amount'] as num?)?.toDouble() ?? 0;

            final category =
            (data['category'] ?? '').toString().toLowerCase();

            final dateString =
            (data['date'] ?? '').toString();

            DateTime? expenseDate;

            try {
              expenseDate = DateTime.parse(dateString);
            } catch (_) {
              expenseDate = null;
            }

            // Current month only
            if (expenseDate != null &&
                expenseDate.year == now.year &&
                expenseDate.month == now.month) {
              total += amount;

              if (category == 'food') {
                food += amount;
              } else if (category == 'shopping') {
                shopping += amount;
              } else if (category == 'transport') {
                transport += amount;
              } else {
                other += amount;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${_monthName(now.month)} ${now.year}',
                  style: const TextStyle(
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 25),

                // Total card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF292C50),
                        Color(0xFF171A30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL SPENDING',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '${expenses.length} expense records',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _categoryCard(
                  'Food',
                  food,
                  Icons.restaurant,
                  total,
                ),

                const SizedBox(height: 12),

                _categoryCard(
                  'Shopping',
                  shopping,
                  Icons.shopping_bag,
                  total,
                ),

                const SizedBox(height: 12),

                _categoryCard(
                  'Transport',
                  transport,
                  Icons.directions_car,
                  total,
                ),

                const SizedBox(height: 12),

                _categoryCard(
                  'Other',
                  other,
                  Icons.category,
                  total,
                ),

                const SizedBox(height: 25),

                if (total == 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141622),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 40,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No expenses found for this month.',
                          style: TextStyle(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryCard(
      String title,
      double amount,
      IconData icon,
      double total,
      ) {
    double percentage = 0;

    if (total > 0) {
      percentage = amount / total;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.deepPurpleAccent,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}