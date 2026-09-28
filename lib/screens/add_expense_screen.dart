import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? documentId;
  final Map<String, dynamic>? expenseData;

  const AddExpenseScreen({
    super.key,
    this.documentId,
    this.expenseData,
  });

  bool get isEditing => documentId != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  String selectedCategory = 'Food';
  bool isLoading = false;

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

    // Load existing expense when editing
    if (widget.expenseData != null) {
      titleController.text =
          widget.expenseData!['title']?.toString() ?? '';

      amountController.text =
          widget.expenseData!['amount']?.toString() ?? '';

      final savedCategory =
          widget.expenseData!['category']?.toString() ?? 'Food';

      if (categories.contains(_capitalize(savedCategory))) {
        selectedCategory = _capitalize(savedCategory);
      }
    }
  }

  Future<void> saveExpense() async {
    final title = titleController.text.trim();
    final amountText = amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      showMessage('Please fill all fields');
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      showMessage('Enter a valid amount');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please login again');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.isEditing) {
        // UPDATE EXISTING EXPENSE
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.documentId)
            .update({
          'title': title,
          'amount': amount,
          'category': selectedCategory.toLowerCase(),
        });

        if (!mounted) return;

        showMessage('Expense updated successfully');
      } else {
        // ADD NEW EXPENSE
        await FirebaseFirestore.instance.collection('expenses').add({
          'title': title,
          'amount': amount,
          'category': selectedCategory.toLowerCase(),
          'date': _formatDate(DateTime.now()),
          'userId': user.uid,
        });

        if (!mounted) return;

        showMessage('Expense added successfully');
      }

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      showMessage(
        e.message ?? 'Unable to save expense',
      );
    } catch (e) {
      showMessage('Something went wrong');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
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
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Expense' : 'Add Expense',
        ),
        backgroundColor: const Color(0xFF080A14),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                editing
                    ? 'Update your expense'
                    : 'Add a new expense',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                editing
                    ? 'Change the details and save your changes.'
                    : 'Record your spending and keep track of your money.',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 30),

              // TITLE
              const Text(
                'Expense Title',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: titleController,
                decoration: inputDecoration(
                  'Example: Breakfast',
                  Icons.receipt_long_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // AMOUNT
              const Text(
                'Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: amountController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration(
                  'Example: 250',
                  Icons.currency_rupee,
                ),
              ),

              const SizedBox(height: 20),

              // CATEGORY
              const Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141622),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF141622),
                    items: categories.map(
                          (category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcon(category),
                                color:
                                Colors.deepPurpleAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(category),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveExpense,
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
                    height: 22,
                    width: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        editing
                            ? Icons.save_outlined
                            : Icons.add,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        editing
                            ? 'Update Expense'
                            : 'Add Expense',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // CANCEL BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    Colors.deepPurpleAccent,
                    side: const BorderSide(
                      color: Colors.deepPurpleAccent,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(
      String hint,
      IconData icon,
      ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFF141622),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Travel':
        return Icons.directions_car;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }
}