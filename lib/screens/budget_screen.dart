import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController budgetController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  double monthlyBudget = 0.0;
  double monthlySpent = 0.0;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadBudgetAndExpenses();
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Future<void> loadBudgetAndExpenses() async {
    final user = auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Load budget
      final budgetDoc =
      await firestore.collection('budgets').doc(user.uid).get();

      if (budgetDoc.exists) {
        final data = budgetDoc.data();

        monthlyBudget =
            (data?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;

        budgetController.text =
        monthlyBudget > 0 ? monthlyBudget.toStringAsFixed(0) : '';
      }

      // Load expenses
      final expenseSnapshot = await firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();

      double total = 0.0;

      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();

        final dateString = data['date']?.toString() ?? '';

        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        try {
          final expenseDate = DateTime.parse(dateString);

          if (expenseDate.year == now.year &&
              expenseDate.month == now.month) {
            total += amount;
          }
        } catch (_) {
          // Ignore invalid dates.
        }
      }

      monthlySpent = total;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      await checkBudgetNotifications();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading budget: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> saveBudget() async {
    final user = auth.currentUser;

    if (user == null) {
      return;
    }

    final value = double.tryParse(budgetController.text.trim());

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await firestore.collection('budgets').doc(user.uid).set({
        'userId': user.uid,
        'monthlyBudget': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      monthlyBudget = value;

      await checkBudgetNotifications();

      if (mounted) {
        setState(() {
          isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly budget saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> checkBudgetNotifications() async {
    if (monthlyBudget <= 0) {
      return;
    }

    final percentage = (monthlySpent / monthlyBudget) * 100;

    if (monthlySpent >= monthlyBudget) {
      await NotificationService.showBudgetExceeded();
    } else if (percentage >= 80) {
      await NotificationService.showBudgetWarning(percentage);
    }
  }

  double get usagePercentage {
    if (monthlyBudget <= 0) {
      return 0.0;
    }

    return monthlySpent / monthlyBudget;
  }

  double get remainingAmount {
    return monthlyBudget - monthlySpent;
  }

  String get budgetStatus {
    if (monthlyBudget <= 0) {
      return 'No budget set';
    }

    if (monthlySpent > monthlyBudget) {
      return 'Budget exceeded';
    }

    if (monthlySpent == monthlyBudget) {
      return 'Budget reached';
    }

    if (usagePercentage >= 0.8) {
      return 'Almost reached';
    }

    return 'Under control';
  }

  Color get statusColor {
    if (monthlyBudget <= 0) {
      return Colors.grey;
    }

    if (monthlySpent >= monthlyBudget) {
      return Colors.redAccent;
    }

    if (usagePercentage >= 0.8) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Budget',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: loadBudgetAndExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBudgetInput(),
              const SizedBox(height: 24),
              _buildBudgetOverview(),
              const SizedBox(height: 24),
              _buildProgressCard(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildSmartTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.deepPurpleAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Set Monthly Budget',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Monthly Budget',
              prefixText: '₹ ',
              filled: true,
              fillColor: const Color(0xFF0D1020),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : saveBudget,
              icon: isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(
                isSaving ? 'Saving...' : 'Save Budget',
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Budget',
            amount: formatAmount(monthlyBudget),
            icon: Icons.wallet,
            iconColor: Colors.deepPurpleAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Spent',
            amount: formatAmount(monthlySpent),
            icon: Icons.payments,
            iconColor: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = usagePercentage.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Usage',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(
              statusColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(usagePercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Remaining: ${formatAmount(remainingAmount)}',
                style: TextStyle(
                  color: remainingAmount >= 0
                      ? Colors.grey.shade300
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(
              monthlySpent >= monthlyBudget && monthlyBudget > 0
                  ? Icons.warning_rounded
                  : Icons.insights,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  budgetStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTips() {
    String title;
    String message;
    IconData icon;

    if (monthlyBudget <= 0) {
      title = 'Set a budget';
      message =
      'Set a monthly budget to start monitoring your spending.';
      icon = Icons.lightbulb_outline;
    } else if (monthlySpent >= monthlyBudget) {
      title = 'Reduce spending';
      message =
      'Your spending has crossed your monthly budget. Try limiting non-essential expenses.';
      icon = Icons.warning_amber_rounded;
    } else if (usagePercentage >= 0.8) {
      title = 'Budget almost reached';
      message =
      'You have used more than 80% of your monthly budget. Keep an eye on upcoming expenses.';
      icon = Icons.notifications_active_outlined;
    } else {
      title = 'Good progress';
      message =
      'Your spending is currently within your monthly budget. Keep tracking your expenses.';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.amberAccent,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade400,
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
}