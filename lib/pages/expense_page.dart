import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String _category = '';
  String _note = '';
  double _amount = 0.0;
  int? _selectedIndex;

  final CollectionReference expensesRef = FirebaseFirestore.instance.collection(
    'expenses',
  );

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _downloadExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Request storage permission on Android
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Storage permission denied')));
        return;
      }
    }

    final querySnapshot =
        await expensesRef
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .get();

    final expenses = querySnapshot.docs;

    List<List<dynamic>> rows = [
      ['Category', 'Note', 'Amount', 'Date'],
    ];

    for (var doc in expenses) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      rows.add([
        data['category'] ?? '',
        data['note'] ?? '',
        data['amount'] ?? '',
        '${date.day}/${date.month}/${date.year}',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }
    final path = '${downloadsDirectory.path}/expenses.csv';
    final file = File(path);

    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expenses downloaded to $path'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  double calculateTotal(List<DocumentSnapshot> docs) {
    double total = 0.0;
    for (var doc in docs) {
      total += doc['amount'];
    }
    return total;
  }

  void _addExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to add expenses.')),
        );
        return;
      }
      await expensesRef.add({
        'category': _category,
        'note': _note,
        'amount': _amount,
        'date': Timestamp.now(),
        'userId': user.uid,
      });
      Navigator.of(context).pop();
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Add Expense'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Category'),
                  onSaved: (value) => _category = value!,
                  validator:
                      (value) => value!.isEmpty ? 'Enter a category' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Note'),
                  onSaved: (value) => _note = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _amount = double.parse(value!),
                  validator:
                      (value) => value!.isEmpty ? 'Enter an amount' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(onPressed: _addExpense, child: Text('Add')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF123953), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await _logout(context);
              } else if (value == 'download') {
                await _downloadExpenses();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Download'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF123953), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              user == null
                  ? null
                  : expensesRef
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('date', descending: true)
                      .snapshots(),
          builder: (context, snapshot) {
            if (user == null) {
              return const Center(
                child: Text(
                  'Please log in to view expenses.',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong: \${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No expenses yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }
            final docs = snapshot.data!.docs;
            double total = calculateTotal(docs);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    32 + kToolbarHeight,
                    16,
                    12,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Spent',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final expense = docs[index];
                      Timestamp ts = expense['date'];
                      DateTime date = ts.toDate();
                      final category = expense['category'] ?? '';
                      final categoryColor = _getCategoryColor(category);
                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        onDismissed: (direction) async {
                          final deletedData = Map<String, dynamic>.from(
                            expense.data() as Map,
                          );
                          final deletedRef = expense.reference;
                          await deletedRef.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Expense deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await deletedRef.set(deletedData);
                                },
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Card(
                            color:
                                _selectedIndex == index
                                    ? Colors.blue[50]
                                    : Colors.white,
                            elevation: _selectedIndex == index ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: categoryColor,
                                child: Text(
                                  category.isNotEmpty
                                      ? category[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense['note'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${date.day}/${date.month}/${date.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: SizedBox(
                                height: 48,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${expense['amount'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedIndex =
                                      _selectedIndex == index ? null : index;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 8),
        child: FloatingActionButton(
          onPressed: _showAddExpenseDialog,
          child: const Icon(Icons.add, size: 30),
          backgroundColor: const Color(0xFFF1CA9C),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Helper for category color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orangeAccent;
      case 'travel':
        return Colors.blueAccent;
      case 'shopping':
        return Colors.purpleAccent;
      case 'bills':
        return Colors.redAccent;
      case 'entertainment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
