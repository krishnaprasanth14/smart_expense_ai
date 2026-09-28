import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'signup_screen.dart';
import 'add_expense_screen.dart';
import 'expense_chart_screen.dart';
import 'advanced_analytics_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';
import 'expense_details_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset email sent',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Unable to send reset email',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent
                        .withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'SmartExpense AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Track your expenses smarter',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      color: Colors.white60,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.deepPurpleAccent,
                    ),
                    filled: true,
                    fillColor:
                    const Color(0xFF111425),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Colors.white60,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.deepPurpleAccent,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                          !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54,
                      ),
                    ),
                    filled: true,
                    fillColor:
                    const Color(0xFF111425),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                    isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color:
                          Colors.deepPurpleAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  late final Stream<QuerySnapshot> expenseStream;

  final TextEditingController searchController =
  TextEditingController();

  String selectedCategory = 'All';
  String selectedSort = 'Newest First';

  final List<String> categories = [
    'All',
    'Food',
    'Shopping',
    'Travel',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
  ];

  final List<String> sortOptions = [
    'Newest First',
    'Oldest First',
    'Highest Amount',
    'Lowest Amount',
  ];

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      expenseStream = FirebaseFirestore.instance
          .collection('expenses')
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .snapshots();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      selectedCategory = 'All';
      selectedSort = 'Newest First';
    });
  }

  bool isCurrentMonth(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();

      return date.year == now.year &&
          date.month == now.month;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteExpense(
      BuildContext context,
      String documentId,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
          const Color(0xFF151827),
          title: const Text(
            'Delete Expense?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this expense?',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                ),
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

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Expense deleted successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting expense: $e',
            ),
          ),
        );
      }
    }
  }

  void editExpense(
      BuildContext context,
      String documentId,
      Map<String, dynamic> data,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          documentId: documentId,
          expenseData: data,
        ),
      ),
    );
  }

  void openExpenseDetails(
      BuildContext context,
      String documentId,
      Map<String, dynamic> data,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseDetailsScreen(
              documentId: documentId,
              expenseData: data,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFF080A14),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF080A14),
        elevation: 0,
        title: const Text(
          'SmartExpense AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Advanced Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdvancedAnalyticsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.analytics_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Expense Chart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const ExpenseChartScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.bar_chart_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance
                  .signOut();

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const LoginScreen(),
                ),
                    (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No expenses found',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }

          final allDocs = snapshot.data!.docs;

          double monthlyTotal = 0;

          final Map<String, double>
          categoryTotals = {};

          for (final doc in allDocs) {
            final data =
            doc.data()
            as Map<String, dynamic>;

            final date =
                data['date']?.toString() ?? '';

            final amount =
                (data['amount'] as num?)
                    ?.toDouble() ??
                    0.0;

            final category =
                data['category']
                    ?.toString() ??
                    'Other';

            if (isCurrentMonth(date)) {
              monthlyTotal += amount;

              categoryTotals[category] =
                  (categoryTotals[category] ??
                      0.0) +
                      amount;
            }
          }

          String highestCategory = 'None';
          double highestCategoryAmount = 0;

          categoryTotals.forEach(
                (category, amount) {
              if (amount >
                  highestCategoryAmount) {
                highestCategoryAmount =
                    amount;
                highestCategory = category;
              }
            },
          );

          final searchText =
          searchController.text
              .trim()
              .toLowerCase();

          List<QueryDocumentSnapshot>
          filteredDocs =
          List.from(allDocs);

          if (searchText.isNotEmpty) {
            filteredDocs =
                filteredDocs.where((doc) {
                  final data = doc.data()
                  as Map<String, dynamic>;

                  final title =
                      data['title']
                          ?.toString()
                          .toLowerCase() ??
                          '';

                  return title.contains(
                    searchText,
                  );
                }).toList();
          }

          if (selectedCategory != 'All') {
            filteredDocs =
                filteredDocs.where((doc) {
                  final data = doc.data()
                  as Map<String, dynamic>;

                  final category =
                      data['category']
                          ?.toString() ??
                          '';

                  return category ==
                      selectedCategory;
                }).toList();
          }

          filteredDocs.sort((a, b) {
            final dataA = a.data()
            as Map<String, dynamic>;

            final dataB = b.data()
            as Map<String, dynamic>;

            final amountA =
                (dataA['amount'] as num?)
                    ?.toDouble() ??
                    0.0;

            final amountB =
                (dataB['amount'] as num?)
                    ?.toDouble() ??
                    0.0;

            final dateA =
                dataA['date']?.toString() ??
                    '';

            final dateB =
                dataB['date']?.toString() ??
                    '';

            switch (selectedSort) {
              case 'Oldest First':
                return dateA.compareTo(
                  dateB,
                );

              case 'Highest Amount':
                return amountB.compareTo(
                  amountA,
                );

              case 'Lowest Amount':
                return amountA.compareTo(
                  amountB,
                );

              case 'Newest First':
              default:
                return dateB.compareTo(
                  dateA,
                );
            }
          });

          return SingleChildScrollView(
            padding:
            const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Spending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.all(20),
                  decoration:
                  BoxDecoration(
                    gradient:
                    const LinearGradient(
                      colors: [
                        Color(0xFF512DA8),
                        Color(0xFF7E57C2),
                      ],
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total spent this month',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '₹${monthlyTotal.toStringAsFixed(2)}',
                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        'Highest category: $highestCategory',
                        style:
                        const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child:
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const ExpenseChartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.bar_chart,
                    ),
                    label: const Text(
                      'View Expense Chart',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.deepPurpleAccent,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child:
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const AdvancedAnalyticsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.analytics_outlined,
                    ),
                    label: const Text(
                      'Advanced Analytics',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFF3949AB,
                      ),
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child:
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const BudgetScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons
                          .account_balance_wallet_outlined,
                    ),
                    label: const Text(
                      'Manage Monthly Budget',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.deepPurpleAccent,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Search & Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                  searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration:
                  InputDecoration(
                    hintText:
                    'Search expenses...',
                    hintStyle:
                    const TextStyle(
                      color: Colors.white38,
                    ),
                    prefixIcon:
                    const Icon(
                      Icons.search,
                      color:
                      Colors.deepPurpleAccent,
                    ),
                    filled: true,
                    fillColor:
                    const Color(
                      0xFF111425,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child:
                      DropdownButtonFormField<
                          String>(
                        value:
                        selectedCategory,
                        dropdownColor:
                        const Color(
                          0xFF151827,
                        ),
                        style:
                        const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        InputDecoration(
                          labelText:
                          'Category',
                          labelStyle:
                          const TextStyle(
                            color:
                            Colors.white60,
                          ),
                          filled: true,
                          fillColor:
                          const Color(
                            0xFF111425,
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                        items:
                        categories
                            .map(
                              (category) {
                            return DropdownMenuItem<
                                String>(
                              value:
                              category,
                              child: Text(
                                category,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            selectedCategory =
                                value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                      DropdownButtonFormField<
                          String>(
                        value: selectedSort,
                        dropdownColor:
                        const Color(
                          0xFF151827,
                        ),
                        style:
                        const TextStyle(
                          color: Colors.white,
                        ),
                        decoration:
                        InputDecoration(
                          labelText: 'Sort',
                          labelStyle:
                          const TextStyle(
                            color:
                            Colors.white60,
                          ),
                          filled: true,
                          fillColor:
                          const Color(
                            0xFF111425,
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                        items:
                        sortOptions
                            .map(
                              (sort) {
                            return DropdownMenuItem<
                                String>(
                              value: sort,
                              child: Text(
                                sort,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            selectedSort =
                                value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Align(
                  alignment:
                  Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                    clearFilters,
                    icon: const Icon(
                      Icons.clear_all,
                      size: 18,
                    ),
                    label: const Text(
                      'Clear Filters',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text(
                      'All Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredDocs.length}',
                      style: const TextStyle(
                        color:
                        Colors.deepPurpleAccent,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (filteredDocs.isEmpty)
                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      30,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFF111425,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Colors
                              .grey.shade700,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'No expenses found',
                          style:
                          TextStyle(
                            color: Colors
                                .grey
                                .shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                ...filteredDocs.map(
                      (doc) {
                    final data = doc.data()
                    as Map<String,
                        dynamic>;

                    final title =
                        data['title']
                            ?.toString() ??
                            'Expense';

                    final category =
                        data['category']
                            ?.toString() ??
                            'Other';

                    final date =
                        data['date']
                            ?.toString() ??
                            '';

                    final amount =
                        (data['amount']
                        as num?)
                            ?.toDouble() ??
                            0.0;

                    return _buildExpenseCard(
                      context,
                      doc.id,
                      data,
                      title,
                      category,
                      date,
                      amount,
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        backgroundColor:
        Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const AddExpenseScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Expense',
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
      BuildContext context,
      String documentId,
      Map<String, dynamic> data,
      String title,
      String category,
      String date,
      double amount,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111425),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(16),
        onTap: () {
          openExpenseDetails(
            context,
            documentId,
            data,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color: Colors
                      .deepPurpleAccent
                      .withOpacity(
                    0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons
                      .receipt_long_outlined,
                  color:
                  Colors.deepPurpleAccent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      '$category • $date',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 13,
                    color:
                    Colors.white38,
                  ),
                ],
              ),

              PopupMenuButton<String>(
                color:
                const Color(
                  0xFF151827,
                ),
                onSelected:
                    (value) {
                  if (value == 'edit') {
                    editExpense(
                      context,
                      documentId,
                      data,
                    );
                  } else if (value ==
                      'delete') {
                    deleteExpense(
                      context,
                      documentId,
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Edit',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline,
                          color:
                          Colors.redAccent,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Delete',
                          style:
                          TextStyle(
                            color:
                            Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}