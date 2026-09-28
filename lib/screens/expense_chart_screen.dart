import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseChartScreen extends StatelessWidget {
  const ExpenseChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Chart'),
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
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load expenses',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final now = DateTime.now();

          // Current month only
          final currentMonthExpenses = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final dateString = data['date']?.toString() ?? '';

            final date = DateTime.tryParse(dateString);

            if (date == null) return false;

            return date.year == now.year && date.month == now.month;
          }).toList();

          // Category totals
          final Map<String, double> categoryTotals = {};

          for (final doc in currentMonthExpenses) {
            final data = doc.data() as Map<String, dynamic>;

            final category =
                data['category']?.toString().toLowerCase() ?? 'other';

            final amount = (data['amount'] as num?)?.toDouble() ?? 0;

            categoryTotals[category] =
                (categoryTotals[category] ?? 0) + amount;
          }

          if (categoryTotals.isEmpty) {
            return const Center(
              child: Text(
                'No expenses this month',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            );
          }

          final categories = categoryTotals.keys.toList();

          final maxValue = categoryTotals.values.reduce(
                (a, b) => a > b ? a : b,
          );

          // This fixes the maxY error.
          final double chartMaxY =
          maxValue == 0 ? 100 : maxValue * 1.2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Analysis',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${_monthName(now.month)} ${now.year}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141622),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending by Category',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            maxY: chartMaxY,

                            minY: 0,

                            alignment:
                            BarChartAlignment.spaceAround,

                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval:
                              chartMaxY / 5,
                            ),

                            borderData:
                            FlBorderData(show: false),

                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles:
                                SideTitles(showTitles: false),
                              ),

                              rightTitles: const AxisTitles(
                                sideTitles:
                                SideTitles(showTitles: false),
                              ),

                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget:
                                      (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style:
                                      const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget:
                                      (value, meta) {
                                    final index =
                                    value.toInt();

                                    if (index < 0 ||
                                        index >=
                                            categories.length) {
                                      return const SizedBox();
                                    }

                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(
                                        top: 8,
                                      ),
                                      child: Text(
                                        _shortCategory(
                                          categories[index],
                                        ),
                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            barGroups: List.generate(
                              categories.length,
                                  (index) {
                                final amount =
                                    categoryTotals[
                                    categories[index]] ??
                                        0;

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: amount,
                                      width: 28,
                                      borderRadius:
                                      BorderRadius.circular(
                                        6,
                                      ),
                                      color:
                                      Colors.deepPurpleAccent,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Category Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...categories.map(
                      (category) {
                    final amount =
                        categoryTotals[category] ?? 0;

                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141622),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent
                                  .withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color:
                              Colors.deepPurpleAccent,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              _capitalize(category),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
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
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
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

    return months[month];
  }

  static String _shortCategory(String category) {
    if (category.length <= 7) {
      return _capitalize(category);
    }

    return _capitalize(category.substring(0, 7));
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
  }
}