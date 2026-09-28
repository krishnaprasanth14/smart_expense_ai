import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final TextEditingController nameController;

  bool isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;

    nameController = TextEditingController(
      text: user?.displayName ?? '',
    );
  }

  Future<void> saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final name = nameController.text.trim();

    if (name.isEmpty) {
      showMessage('Please enter your name');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await user.updateDisplayName(name);
      await user.reload();

      if (!mounted) return;

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      showMessage('Profile updated successfully');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      showMessage('Unable to update profile');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF080A14),
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.close : Icons.edit_outlined,
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;

                if (!isEditing) {
                  nameController.text =
                      user.displayName ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .snapshots(),
        builder: (context, snapshot) {
          final expenses = snapshot.data?.docs ?? [];

          double total = 0;

          for (final expense in expenses) {
            final data =
            expense.data() as Map<String, dynamic>;

            total +=
                (data['amount'] as num?)?.toDouble() ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 15),

                // PROFILE AVATAR
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C4DFF),
                        Color(0xFF512DA8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent
                            .withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      getInitials(
                        user.displayName ?? user.email ?? 'U',
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : 'SmartExpense User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  user.email ?? '',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 30),

                // EDIT PROFILE
                if (isEditing)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141622),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                            ),
                            filled: true,
                            fillColor:
                            const Color(0xFF202236),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                            isSaving ? null : saveProfile,
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.deepPurpleAccent,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // STATISTICS
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        Icons.receipt_long,
                        expenses.length.toString(),
                        'Expenses',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard(
                        Icons.account_balance_wallet,
                        '₹${total.toStringAsFixed(0)}',
                        'Total Spent',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ACCOUNT INFORMATION
                buildSection(
                  title: 'Account Information',
                  children: [
                    buildInfoTile(
                      Icons.email_outlined,
                      'Email',
                      user.email ?? 'Not available',
                    ),
                    buildInfoTile(
                      Icons.verified_user_outlined,
                      'Account Status',
                      user.emailVerified
                          ? 'Email Verified'
                          : 'Email Not Verified',
                    ),
                    buildInfoTile(
                      Icons.security_outlined,
                      'Authentication',
                      'Firebase Authentication',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // APP INFORMATION
                buildSection(
                  title: 'SmartExpense AI',
                  children: [
                    buildInfoTile(
                      Icons.auto_awesome,
                      'AI Expense Tracking',
                      'Smart spending management',
                    ),
                    buildInfoTile(
                      Icons.cloud_outlined,
                      'Data Storage',
                      'Cloud Firestore',
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Logout',
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
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'SmartExpense AI',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Manage your money smarter.',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
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

  Widget buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget buildInfoTile(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: Colors.deepPurpleAccent,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ');

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }

    return 'U';
  }
}