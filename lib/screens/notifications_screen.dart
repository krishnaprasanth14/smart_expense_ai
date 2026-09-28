import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool spendingAlerts = true;
  bool budgetAlerts = true;
  bool dailyReminder = false;

  double monthlyBudget = 0.0;
  double monthlySpent = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotificationSettings();
  }

  Future<void> loadNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final spending = await NotificationService.getSpendingAlerts();
    final budget = await NotificationService.getBudgetAlerts();
    final reminder = await NotificationService.getDailyReminder();

    try {
      final budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(user.uid)
          .get();

      if (budgetDoc.exists) {
        final data = budgetDoc.data();

        monthlyBudget =
            (data?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;
      }

      final expenses = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();

      double total = 0.0;

      for (final doc in expenses.docs) {
        final data = doc.data();

        final dateString = data['date']?.toString() ?? '';
        final amount =
            (data['amount'] as num?)?.toDouble() ?? 0.0;

        try {
          final date = DateTime.parse(dateString);

          if (date.year == now.year &&
              date.month == now.month) {
            total += amount;
          }
        } catch (_) {}
      }

      monthlySpent = total;

      if (!mounted) return;

      setState(() {
        spendingAlerts = spending;
        budgetAlerts = budget;
        dailyReminder = reminder;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        spendingAlerts = spending;
        budgetAlerts = budget;
        dailyReminder = reminder;
        isLoading = false;
      });
    }
  }

  Future<void> updateSpendingAlerts(bool value) async {
    setState(() {
      spendingAlerts = value;
    });

    await NotificationService.setSpendingAlerts(value);
  }

  Future<void> updateBudgetAlerts(bool value) async {
    setState(() {
      budgetAlerts = value;
    });

    await NotificationService.setBudgetAlerts(value);
  }

  Future<void> updateDailyReminder(bool value) async {
    setState(() {
      dailyReminder = value;
    });

    await NotificationService.setDailyReminder(value);
  }

  double get budgetPercentage {
    if (monthlyBudget <= 0) {
      return 0;
    }

    return (monthlySpent / monthlyBudget) * 100;
  }

  String get budgetStatus {
    if (monthlyBudget <= 0) {
      return 'No monthly budget set';
    }

    if (monthlySpent >= monthlyBudget) {
      return 'Budget exceeded';
    }

    if (budgetPercentage >= 80) {
      return 'Almost reached';
    }

    return 'Under control';
  }

  Color get budgetStatusColor {
    if (monthlyBudget <= 0) {
      return Colors.grey;
    }

    if (monthlySpent >= monthlyBudget) {
      return Colors.redAccent;
    }

    if (budgetPercentage >= 80) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
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
          : ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildSectionTitle('Notification Settings'),

          _buildNotificationTile(
            icon: Icons.trending_up,
            title: 'Spending Alerts',
            subtitle:
            'Get notified when spending is high',
            value: spendingAlerts,
            onChanged: updateSpendingAlerts,
          ),

          _buildNotificationTile(
            icon: Icons.account_balance_wallet,
            title: 'Budget Alerts',
            subtitle:
            'Get alerts when your budget is nearly reached',
            value: budgetAlerts,
            onChanged: updateBudgetAlerts,
          ),

          _buildNotificationTile(
            icon: Icons.today,
            title: 'Daily Reminder',
            subtitle:
            'Receive a reminder to track your expenses',
            value: dailyReminder,
            onChanged: updateDailyReminder,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Current Status'),

          _buildBudgetStatusCard(),

          const SizedBox(height: 20),

          _buildAlertInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.8),
            Colors.deepPurpleAccent.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.notifications_active,
            size: 42,
            color: Colors.white,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Alerts',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Stay informed about your spending and budget.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurpleAccent.shade100,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(17),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurpleAccent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBudgetStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: budgetStatusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: budgetStatusColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                monthlySpent >= monthlyBudget &&
                    monthlyBudget > 0
                    ? Icons.warning_rounded
                    : Icons.account_balance_wallet,
                color: budgetStatusColor,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  budgetStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: budgetStatusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              Text(
                '₹${monthlySpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              Text(
                '₹${monthlyBudget.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amberAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Alert Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Budget alerts are triggered when you reach '
                '80% of your monthly budget or exceed it.',
            style: TextStyle(
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spending alerts can be used for high spending '
                'categories.',
            style: TextStyle(
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}