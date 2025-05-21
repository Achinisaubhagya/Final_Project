import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  String _selectedPeriod = 'monthly';
  String _selectedMonth = DateFormat.MMMM().format(DateTime.now());
  String _selectedWeek = 'Week 1';
  String _selectedDay = DateFormat.EEEE().format(DateTime.now());

  final List<String> _periods = ['daily', 'weekly', 'monthly'];
  final List<String> _months = DateFormat.MMMM().dateSymbols.MONTHS;
  final List<String> _weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'];
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String? _userId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  Future<void> fetchUserId() async {
    setState(() {
      _loadingUser = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final identitySnap = await FirebaseFirestore.instance
          .collection('identity')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (identitySnap.docs.isNotEmpty) {
        final identityData = identitySnap.docs.first.data();
        setState(() {
          _userId = identityData['userId']?.toString();
          _loadingUser = false;
        });
      } else {
        setState(() {
          _userId = null;
          _loadingUser = false;
        });
      }
    } else {
      setState(() {
        _userId = null;
        _loadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Expenses",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.deepPurple.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loadingUser
              ? const Center(child: CircularProgressIndicator())
              : (_userId == null
                  ? const Center(child: Text("User not found", style: TextStyle(color: Colors.white)))
                  : Column(
                      children: [
                        // Period Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Summary",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            DropdownButton<String>(
                              value: _selectedPeriod,
                              dropdownColor: Colors.deepPurple.shade100,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white),
                              underline: Container(height: 0),
                              onChanged: (value) => setState(() => _selectedPeriod = value!),
                              items: _periods.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Period-specific Selector
                        if (_selectedPeriod == 'monthly') _buildMonthSelector(),
                        if (_selectedPeriod == 'weekly') _buildWeekSelector(),
                        if (_selectedPeriod == 'daily') _buildDaySelector(),
                        const SizedBox(height: 12),

                        // Expense List
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _userId == null
                                ? null
                                : FirebaseFirestore.instance
                                    .collection('expenses')
                                    .where('userId', isEqualTo: _userId)
                                    .orderBy('date', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No expense records found.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final filtered = snapshot.data!.docs.where((doc) {
                                final dateField = doc['date'];
                                DateTime? date;

                                if (dateField is Timestamp) {
                                  date = dateField.toDate();
                                } else if (dateField is String) {
                                  try {
                                    date = DateTime.parse(dateField);
                                  } catch (_) {
                                    return false;
                                  }
                                } else {
                                  return false;
                                }

                                switch (_selectedPeriod) {
                                  case 'monthly':
                                    return DateFormat.MMMM().format(date) == _selectedMonth;
                                  case 'weekly':
                                    int week = ((date.day - 1) ~/ 7) + 1;
                                    return 'Week $week' == _selectedWeek;
                                  case 'daily':
                                    return DateFormat.EEEE().format(date) == _selectedDay;
                                }
                                return true;
                              }).toList();

                              return ListView(
                                children: filtered.map((doc) {
                                  final dateField = doc['date'];
                                  DateTime date;

                                  if (dateField is Timestamp) {
                                    date = dateField.toDate();
                                  } else if (dateField is String) {
                                    date = DateTime.tryParse(dateField) ?? DateTime.now();
                                  } else {
                                    return const SizedBox();
                                  }

                                  return expenseTile(
                                    doc['category'] ?? 'No category',
                                    DateFormat('dd/MM/yy').format(date),
                                    "LKR. ${doc['amount']}",
                                    doc,
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    )),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() => DropdownButton<String>(
        value: _selectedMonth,
        isExpanded: true,
        dropdownColor: Colors.deepPurple.shade100,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        underline: Container(height: 1, color: Colors.white),
        onChanged: (value) => setState(() => _selectedMonth = value!),
        items: _months.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      );

  Widget _buildWeekSelector() => DropdownButton<String>(
        value: _selectedWeek,
        isExpanded: true,
        dropdownColor: Colors.deepPurple.shade100,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        underline: Container(height: 1, color: Colors.white),
        onChanged: (value) => setState(() => _selectedWeek = value!),
        items: _weeks.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      );

  Widget _buildDaySelector() => DropdownButton<String>(
        value: _selectedDay,
        isExpanded: true,
        dropdownColor: Colors.deepPurple.shade100,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        underline: Container(height: 1, color: Colors.white),
        onChanged: (value) => setState(() => _selectedDay = value!),
        items: _days.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      );

  Widget expenseTile(String category, String date, String amount, DocumentSnapshot doc) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editExpense(doc);
                } else if (value == 'delete') {
                  _deleteExpense(doc.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExpense(String id) async {
    await FirebaseFirestore.instance.collection('expenses').doc(id).delete();
  }

  void _editExpense(DocumentSnapshot doc) {
    final TextEditingController _amountController = TextEditingController(text: doc['amount'].toString());
    final TextEditingController _categoryController = TextEditingController(text: doc['category']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('expenses')
                    .doc(doc.id)
                    .update({
                  'category': _categoryController.text,
                  'amount': double.tryParse(_amountController.text) ?? 0,
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}