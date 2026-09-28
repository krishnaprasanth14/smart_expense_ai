import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() =>
      _AIInsightsScreenState();
}

class _AIInsightsScreenState
    extends State<AIInsightsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<QuerySnapshot> expenseStream;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;

    expenseStream = FirebaseFirestore.instance
        .collection('expenses')
        .where(
      'userId',
      isEqualTo: user?.uid,
    )
        .snapshots();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() +
        text.substring(1);
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }

  String getInsight(
      String topCategory,
      double topAmount,
      double total,
      ) {
    if (total == 0) {
      return 'Start adding expenses to get personalized AI spending insights.';
    }

    final percentage =
        (topAmount / total) * 100;

    if (percentage >= 50) {
      return 'Your highest spending is on $topCategory. '
          'This category takes a large part of your total spending.';
    }

    if (percentage >= 30) {
      return '$topCategory is currently your highest spending category. '
          'Keep an eye on this category to manage your budget better.';
    }

    return 'Your spending is distributed across different categories. '
        'Continue tracking your expenses to understand your habits.';
  }

  String getSuggestion(
      String topCategory,
      double topAmount,
      double total,
      ) {
    if (total == 0) {
      return 'Add a few expenses and SmartExpense AI will generate suggestions for you.';
    }

    if (topCategory == 'Food') {
      return 'Try reducing food spending by 10%. '
          'You could save approximately ₹${(topAmount * 0.10).toStringAsFixed(0)}.';
    }

    if (topCategory == 'Shopping') {
      return 'Review unnecessary purchases before buying. '
          'A 10% reduction could save approximately ₹${(topAmount * 0.10).toStringAsFixed(0)}.';
    }

    if (topCategory == 'Travel') {
      return 'Plan trips and compare travel costs in advance '
          'to reduce unnecessary spending.';
    }

    if (topCategory == 'Entertainment') {
      return 'Consider setting a monthly entertainment limit '
          'to keep this expense under control.';
    }

    if (topCategory == 'Bills') {
      return 'Review your recurring bills and subscriptions '
          'to identify services you no longer need.';
    }

    if (topCategory == 'Health') {
      return 'Keep health expenses planned and maintain a '
          'separate emergency budget for unexpected costs.';
    }

    return 'Track your expenses regularly and set a monthly '
        'budget for your major spending categories.';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Spending Insights'),
        backgroundColor:
        const Color(0xFF080A14),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to analyze expenses',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          double total = 0;

          final Map<String, double>
          categoryTotals = {};

          for (final doc in docs) {
            final data =
            doc.data()
            as Map<String, dynamic>;

            final amount =
                (data['amount'] as num?)
                    ?.toDouble() ??
                    0;

            final category =
                data['category']
                    ?.toString()
                    .toLowerCase() ??
                    'other';

            total += amount;

            categoryTotals[category] =
                (categoryTotals[category] ??
                    0) +
                    amount;
          }

          String topCategory = 'None';
          double topAmount = 0;

          if (categoryTotals.isNotEmpty) {
            final topEntry =
            categoryTotals.entries.reduce(
                  (a, b) =>
              a.value > b.value ? a : b,
            );

            topCategory =
                capitalize(topEntry.key);
            topAmount = topEntry.value;
          }

          final percentage = total == 0
              ? 0.0
              : (topAmount / total) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient:
                    const LinearGradient(
                      colors: [
                        Color(0xFF512DA8),
                        Color(0xFF7C4DFF),
                      ],
                    ),
                    borderRadius:
                    BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .deepPurpleAccent
                            .withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors.white
                                  .withOpacity(
                                0.15,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                14,
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Smart AI Analysis',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Your spending patterns, '
                            'analyzed automatically.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // TOTAL SPENDING
                const Text(
                  'Spending Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        Icons.account_balance_wallet,
                        '₹${total.toStringAsFixed(0)}',
                        'Total Spent',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        Icons.receipt_long,
                        docs.length.toString(),
                        'Expenses',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // TOP CATEGORY
                const Text(
                  'Top Spending Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141622),
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors
                              .deepPurpleAccent
                              .withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          getCategoryIcon(
                            topCategory,
                          ),
                          color:
                          Colors.deepPurpleAccent,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              topCategory,
                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '₹${topAmount.toStringAsFixed(0)} spent',
                              style:
                              const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.deepPurpleAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // AI INSIGHT
                buildInsightCard(
                  icon: Icons.insights,
                  title: 'AI Insight',
                  text: getInsight(
                    topCategory,
                    topAmount,
                    total,
                  ),
                ),

                const SizedBox(height: 15),

                // AI SUGGESTION
                buildInsightCard(
                  icon: Icons.lightbulb_outline,
                  title: 'Smart Suggestion',
                  text: getSuggestion(
                    topCategory,
                    topAmount,
                    total,
                  ),
                ),

                const SizedBox(height: 25),

                // CATEGORY BREAKDOWN
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (categoryTotals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141622),
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        'Add expenses to see your breakdown.',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  )
                else
                  ...categoryTotals.entries.map(
                        (entry) {
                      final category =
                      capitalize(entry.key);

                      final amount = entry.value;

                      final percent = total == 0
                          ? 0.0
                          : amount / total;

                      return Container(
                        margin:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding:
                        const EdgeInsets.all(15),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(0xFF141622),
                          borderRadius:
                          BorderRadius.circular(
                            15,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  getCategoryIcon(
                                    category,
                                  ),
                                  color: Colors
                                      .deepPurpleAccent,
                                  size: 21,
                                ),
                                const SizedBox(
                                    width: 10),
                                Expanded(
                                  child: Text(
                                    category,
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${amount.toStringAsFixed(0)}',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                              child:
                              LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor:
                                Colors.white10,
                                valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                                  Colors
                                      .deepPurpleAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 25),

                // AI STATUS
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141622),
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.green
                          .withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.greenAccent,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI analysis is based on your '
                              'stored expense data.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildStatCard(
      IconData icon,
      String value,
      String label,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.deepPurpleAccent,
            size: 25,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInsightCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.deepPurpleAccent
              .withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent
                  .withOpacity(0.12),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurpleAccent,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}