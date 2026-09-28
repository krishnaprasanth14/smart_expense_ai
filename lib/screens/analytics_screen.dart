import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool isLoading = true;

  double totalSpent = 0.0;
  double averageDaily = 0.0;
  int expenseCount = 0;

  String highestCategory = 'None';
  double highestCategoryAmount = 0.0;

  final Map<String, double> categoryTotals = {};

  final List<String> categories = [
    'Food',
    'Shopping',
    'Travel',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final now = DateTime.now();

      final month = now.month.toString().padLeft(2, '0');
      final year = now.year.toString();

      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      double total = 0.0;
      int count = 0;

      final Map<String, double> totals = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final date = data['date']?.toString() ?? '';

        if (!date.startsWith('$year-$month')) {
          continue;
        }

        final amount = (data['amount'] ?? 0).toDouble();
        final category = data['category']?.toString() ?? 'Other';

        total += amount;
        count++;

        totals[category] = (totals[category] ?? 0.0) + amount;
      }

      String topCategory = 'None';
      double topAmount = 0.0;

      totals.forEach((category, amount) {
        if (amount > topAmount) {
          topAmount = amount;
          topCategory = category;
        }
      });

      final int daysInMonth = now.day;

      final double average =
      count == 0 ? 0.0 : total / daysInMonth;

      if (mounted) {
        setState(() {
          totalSpent = total;
          expenseCount = count;
          averageDaily = average;
          highestCategory = topCategory;
          highestCategoryAmount = topAmount;

          categoryTotals.clear();
          categoryTotals.addAll(totals);

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Analytics error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A14),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurpleAccent,
        ),
      )
          : RefreshIndicator(
        onRefresh: loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildSummaryCards(),

              const SizedBox(height: 25),

              _buildCategoryChart(),

              const SizedBox(height: 25),

              _buildCategoryDetails(),

              const SizedBox(height: 25),

              _buildInsightCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5E35B1),
            Color(0xFF311B92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.analytics_rounded,
            size: 38,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          const Text(
            'Spending Analytics',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${months[now.month - 1]} ${now.year}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Spent',
                '₹${totalSpent.toStringAsFixed(0)}',
                Icons.currency_rupee,
                Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Expenses',
                '$expenseCount',
                Icons.receipt_long,
                Colors.blueAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Daily Average',
                '₹${averageDaily.toStringAsFixed(0)}',
                Icons.today,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Top Category',
                highestCategory,
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121528),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (categoryTotals.isEmpty) {
      return _emptyCard(
        'No expenses available',
        'Add expenses to see your spending analytics.',
      );
    }

    double maxValue = 0.0;

    for (final value in categoryTotals.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    final double chartMaxY =
    maxValue == 0.0 ? 100.0 : maxValue * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121528),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Spending',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Where your money is going this month',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),

                borderData: FlBorderData(
                  show: false,
                ),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();

                        if (index < 0 ||
                            index >= categories.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding:
                          const EdgeInsets.only(top: 8),
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: List.generate(
                  categories.length,
                      (index) {
                    final double amount =
                        categoryTotals[categories[index]] ??
                            0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          width: 22,
                          borderRadius:
                          const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: Colors.deepPurpleAccent,
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
    );
  }

  Widget _buildCategoryDetails() {
    if (categoryTotals.isEmpty) {
      return const SizedBox();
    }

    final sortedCategories =
    categoryTotals.entries.toList()
      ..sort(
            (a, b) => b.value.compareTo(a.value),
      );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121528),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ...sortedCategories.map(
                (entry) {
              final double percentage = totalSpent == 0.0
                  ? 0.0
                  : (entry.value / totalSpent) * 100;

              return Padding(
                padding:
                const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          '₹${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 7,
                        backgroundColor:
                        Colors.grey.shade800,
                        valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                          Colors.deepPurpleAccent,
                        ),
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
  }

  Widget _buildInsightCard() {
    String title;
    String message;
    IconData icon;
    Color color;

    if (expenseCount == 0) {
      title = 'Start Tracking';
      message =
      'Add some expenses to get personalized spending insights.';
      icon = Icons.lightbulb_outline;
      color = Colors.blue;
    } else if (highestCategoryAmount >
        totalSpent * 0.5) {
      title = 'High Category Spending';
      message =
      '$highestCategory is taking more than half of your monthly spending.';
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    } else if (expenseCount >= 20) {
      title = 'Frequent Spending';
      message =
      'You have recorded $expenseCount expenses this month. Keep tracking to understand your spending habits.';
      icon = Icons.insights;
      color = Colors.deepPurpleAccent;
    } else {
      title = 'Healthy Tracking';
      message =
      'Your expense data is being tracked. Continue adding expenses for better insights.';
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
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
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(
      String title,
      String message,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF121528),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 50,
            color: Colors.deepPurpleAccent,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}