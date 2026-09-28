import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState
    extends State<AdvancedAnalyticsScreen> {
  late final Stream<QuerySnapshot> expenseStream;

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

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      expenseStream = FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  bool isCurrentMonth(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();

      return date.year == now.year && date.month == now.month;
    } catch (_) {
      return false;
    }
  }

  String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

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
      backgroundColor: const Color(0xFF080A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080A14),
        elevation: 0,
        title: const Text(
          'Advanced Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading analytics',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No expense data found'),
            );
          }

          final documents = snapshot.data!.docs;

          final currentMonthExpenses = documents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = data['date']?.toString() ?? '';

            return isCurrentMonth(date);
          }).toList();

          double totalSpent = 0;
          double highestExpense = 0;
          String highestExpenseTitle = 'No expenses';

          final Map<String, double> categoryTotals = {
            for (final category in categories) category: 0.0,
          };

          final Map<int, double> dailyTotals = {};

          for (final doc in currentMonthExpenses) {
            final data = doc.data() as Map<String, dynamic>;

            final double amount =
                (data['amount'] as num?)?.toDouble() ?? 0.0;

            final String category =
                data['category']?.toString() ?? 'Other';

            final String title =
                data['title']?.toString() ?? 'Expense';

            final String dateString =
                data['date']?.toString() ?? '';

            totalSpent += amount;

            if (amount > highestExpense) {
              highestExpense = amount;
              highestExpenseTitle = title;
            }

            if (categoryTotals.containsKey(category)) {
              categoryTotals[category] =
                  categoryTotals[category]! + amount;
            } else {
              categoryTotals['Other'] =
                  categoryTotals['Other']! + amount;
            }

            try {
              final date = DateTime.parse(dateString);

              dailyTotals[date.day] =
                  (dailyTotals[date.day] ?? 0.0) + amount;
            } catch (_) {}
          }

          String highestCategory = 'No category';
          double highestCategoryAmount = 0.0;

          categoryTotals.forEach((category, amount) {
            if (amount > highestCategoryAmount) {
              highestCategoryAmount = amount;
              highestCategory = category;
            }
          });

          final now = DateTime.now();
          final int daysPassed = now.day;

          final double averageDailySpending =
          daysPassed == 0 ? 0.0 : totalSpent / daysPassed;

          double maxCategoryValue = 0.0;

          for (final value in categoryTotals.values) {
            if (value > maxCategoryValue) {
              maxCategoryValue = value;
            }
          }

          double maxDailyValue = 0.0;

          for (final value in dailyTotals.values) {
            if (value > maxDailyValue) {
              maxDailyValue = value;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 20),

                  _buildSummaryGrid(
                    totalSpent,
                    averageDailySpending,
                    currentMonthExpenses.length,
                    highestExpense,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Category-wise Spending',
                    Icons.pie_chart_outline,
                  ),

                  const SizedBox(height: 12),

                  _buildCategoryChart(
                    categoryTotals,
                    maxCategoryValue,
                  ),

                  const SizedBox(height: 24),

                  _buildTopCategoryCard(
                    highestCategory,
                    highestCategoryAmount,
                    totalSpent,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Daily Spending Trend',
                    Icons.show_chart,
                  ),

                  const SizedBox(height: 12),

                  _buildDailyChart(
                    dailyTotals,
                    maxDailyValue,
                    now.day,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Highest Expense',
                    Icons.arrow_upward_rounded,
                  ),

                  const SizedBox(height: 12),

                  _buildHighestExpenseCard(
                    highestExpenseTitle,
                    highestExpense,
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Spending Analysis',
                    Icons.analytics_outlined,
                  ),

                  const SizedBox(height: 12),

                  _buildAnalysisCard(
                    totalSpent,
                    averageDailySpending,
                    highestCategory,
                    highestCategoryAmount,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final monthName = _monthName(DateTime.now().month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5E35B1),
            Color(0xFF7E57C2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$monthName ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
      double totalSpent,
      double averageDaily,
      int expenseCount,
      double highestExpense,
      ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard(
          'Total Spent',
          formatAmount(totalSpent),
          Icons.account_balance_wallet_outlined,
          Colors.deepPurpleAccent,
        ),
        _buildStatCard(
          'Daily Average',
          formatAmount(averageDaily),
          Icons.calendar_today_outlined,
          Colors.blueAccent,
        ),
        _buildStatCard(
          'Expenses',
          expenseCount.toString(),
          Icons.receipt_long_outlined,
          Colors.orangeAccent,
        ),
        _buildStatCard(
          'Highest Expense',
          formatAmount(highestExpense),
          Icons.trending_up,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111425),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.deepPurpleAccent,
          size: 23,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(
      Map<String, double> categoryTotals,
      double maxValue,
      ) {
    final nonZeroCategories = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (nonZeroCategories.isEmpty) {
      return _emptyChart(
        'No category data available',
      );
    }

    // FIX:
    // Always use a positive double value for maxY.
    final double chartMaxY =
    maxValue > 0 ? maxValue * 1.25 : 100.0;

    final double interval =
        chartMaxY / 5.0;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(
        10,
        20,
        20,
        10,
      ),
      decoration: _chartDecoration(),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
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
                interval: interval,
                getTitlesWidget: (
                    value,
                    meta,
                    ) {
                  return Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (
                    value,
                    meta,
                    ) {
                  final int index =
                  value.toInt();

                  if (index < 0 ||
                      index >=
                          nonZeroCategories.length) {
                    return const SizedBox();
                  }

                  final String name =
                      nonZeroCategories[index]
                          .key;

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      name.length > 7
                          ? name.substring(
                        0,
                        7,
                      )
                          : name,
                      style: TextStyle(
                        color:
                        Colors.grey.shade400,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            nonZeroCategories.length,
                (index) {
              final double value =
                  nonZeroCategories[index]
                      .value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    width: 22,
                    borderRadius:
                    BorderRadius.circular(
                      5,
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
    );
  }

  Widget _buildDailyChart(
      Map<int, double> dailyTotals,
      double maxValue,
      int currentDay,
      ) {
    if (dailyTotals.isEmpty) {
      return _emptyChart(
        'No daily spending data available',
      );
    }

    // FIX:
    // Always provide a positive double maxY.
    final double chartMaxY =
    maxValue > 0 ? maxValue * 1.25 : 100.0;

    final List<FlSpot> spots = [];

    for (int day = 1; day <= currentDay; day++) {
      spots.add(
        FlSpot(
          day.toDouble(),
          dailyTotals[day] ?? 0.0,
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(
        10,
        20,
        20,
        10,
      ),
      decoration: _chartDecoration(),
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: currentDay.toDouble(),
          minY: 0,
          maxY: chartMaxY,
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
                getTitlesWidget: (
                    value,
                    meta,
                    ) {
                  return Text(
                    '₹${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval:
                currentDay > 15 ? 5 : 2,
                getTitlesWidget: (
                    value,
                    meta,
                    ) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color:
                      Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color:
              Colors.deepPurpleAccent,
              dotData: FlDotData(
                show: currentDay <= 15,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors
                    .deepPurpleAccent
                    .withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoryCard(
      String category,
      double amount,
      double total,
      ) {
    final double percentage =
    total == 0 ? 0.0 : (amount / total) * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111425),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
          Colors.deepPurpleAccent.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent
                  .withOpacity(0.15),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Spending Category',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatAmount(amount)} • ${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighestExpenseCard(
      String title,
      double amount,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111425),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
              Colors.redAccent.withOpacity(0.12),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.redAccent,
              size: 28,
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
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatAmount(amount),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      double totalSpent,
      double averageDaily,
      String highestCategory,
      double highestCategoryAmount,
      ) {
    String message;

    if (totalSpent == 0) {
      message =
      'No spending recorded this month. Start adding expenses to see your spending analysis.';
    } else if (highestCategoryAmount >
        totalSpent * 0.5) {
      message =
      'More than half of your monthly spending is in $highestCategory. Consider monitoring this category closely.';
    } else if (averageDaily > 1000) {
      message =
      'Your average daily spending is relatively high. Reviewing daily expenses can help control your monthly spending.';
    } else {
      message =
      'Your spending is distributed across different categories. Continue tracking expenses regularly to understand your habits.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111425),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade300,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(String message) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: _chartDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 45,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _chartDecoration() {
    return BoxDecoration(
      color: const Color(0xFF111425),
      borderRadius: BorderRadius.circular(18),
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