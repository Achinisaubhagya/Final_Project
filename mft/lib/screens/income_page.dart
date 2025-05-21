import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({Key? key}) : super(key: key);

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
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
        title: const Text("Income", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                            const Text("Filter by", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            DropdownButton<String>(
                              value: _selectedPeriod,
                              dropdownColor: Colors.deepPurple.shade100,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white),
                              underline: Container(height: 0),
                              onChanged: (value) => setState(() => _selectedPeriod = value!),
                              items: _periods.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_selectedPeriod == 'monthly') _buildMonthSelector(),
                        if (_selectedPeriod == 'weekly') _buildWeekSelector(),
                        if (_selectedPeriod == 'daily') _buildDaySelector(),

                        const SizedBox(height: 10),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _userId == null
                                ? null
                                : FirebaseFirestore.instance
                                    .collection('incomes')
                                    .where('userId', isEqualTo: _userId)
                                    .orderBy('date', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text("No income records found", style: TextStyle(color: Colors.white)));
                              }

                              final filteredDocs = snapshot.data!.docs.where((doc) {
                                DateTime date;
                                final dateField = doc['date'];

                                if (dateField is Timestamp) {
                                  date = dateField.toDate();
                                } else if (dateField is String) {
                                  date = DateTime.tryParse(dateField) ?? DateTime.now();
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
                                  default:
                                    return true;
                                }
                              }).toList();

                              return ListView.builder(
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredDocs[index];
                                  final dateField = doc['date'];
                                  DateTime date;

                                  if (dateField is Timestamp) {
                                    date = dateField.toDate();
                                  } else if (dateField is String) {
                                    date = DateTime.tryParse(dateField) ?? DateTime.now();
                                  } else {
                                    date = DateTime.now();
                                  }

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(doc['category'] ?? 'No category', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("LKR. ${doc['amount']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editIncome(doc);
                                              } else if (value == 'delete') {
                                                _deleteIncome(doc.id);
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
                                },
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

  void _editIncome(DocumentSnapshot doc) {
    final TextEditingController categoryController = TextEditingController(text: doc['category']);
    final TextEditingController amountController = TextEditingController(text: doc['amount'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Income"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('incomes').doc(doc.id).update({
                'category': categoryController.text,
                'amount': double.tryParse(amountController.text) ?? doc['amount'],
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _deleteIncome(String docId) async {
    await FirebaseFirestore.instance.collection('incomes').doc(docId).delete();
  }
}