import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String selectedCurrency = 'INR (₹)';

  Future<void> changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user.email!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset link sent to your email.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset link: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  void showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _currencyOption('INR (₹)'),
              _currencyOption('USD (\$)'),
              _currencyOption('EUR (€)'),
              _currencyOption('GBP (£)'),
            ],
          ),
        );
      },
    );
  }

  Widget _currencyOption(String currency) {
    return RadioListTile<String>(
      title: Text(currency),
      value: currency,
      groupValue: selectedCurrency,
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedCurrency = value;
        });

        Navigator.pop(context);
      },
    );
  }

  void showAboutDialogBox() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About SmartExpense AI'),
          content: const Text(
            'SmartExpense AI is a personal expense tracking '
                'application built using Flutter and Firebase.\n\n'
                'Features include expense management, budgeting, '
                'analytics, AI spending insights and notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Account'),

          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),

          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Manage spending and budget alerts',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('Preferences'),

          _buildSettingsTile(
            icon: Icons.currency_rupee,
            title: 'Currency',
            subtitle: selectedCurrency,
            onTap: showCurrencyDialog,
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('Security'),

          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Send a password reset link',
            onTap: changePassword,
          ),

          const SizedBox(height: 20),

          _buildSectionTitle('Application'),

          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'About SmartExpense AI',
            onTap: showAboutDialogBox,
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
        top: 4,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.deepPurpleAccent.shade100,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15182A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Container(
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
        trailing: trailing ??
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
        onTap: onTap,
      ),
    );
  }
}