import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  double totalIncome = 0;
  double totalExpense = 0;
  List<Map<String, dynamic>> incomeData = [];
  List<Map<String, dynamic>> expenseData = [];
  String selectedFilter = 'Monthly';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final incomeSnapshot = await FirebaseFirestore.instance
        .collection('incomes')
        .where('uid', isEqualTo: uid)
        .get();

    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('uid', isEqualTo: uid)
        .get();

    double incomeTotal = 0;
    double expenseTotal = 0;
    List<Map<String, dynamic>> incomes = [];
    List<Map<String, dynamic>> expenses = [];

    for (var doc in incomeSnapshot.docs) {
      var data = doc.data();
      var date = _parseDate(data['date']);
      if (date != null) {
        incomes.add({'amount': data['amount'], 'date': date});
        incomeTotal += (data['amount'] as num).toDouble();
      }
    }

    for (var doc in expenseSnapshot.docs) {
      var data = doc.data();
      var date = _parseDate(data['date']);
      if (date != null) {
        expenses.add({'amount': data['amount'], 'date': date});
        expenseTotal += (data['amount'] as num).toDouble();
      }
    }

    setState(() {
      incomeData = incomes;
      expenseData = expenses;
      totalIncome = incomeTotal;
      totalExpense = expenseTotal;
    });
  }

  DateTime? _parseDate(dynamic dateField) {
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) return DateTime.tryParse(dateField);
    return null;
  }

  List<Map<String, dynamic>> _filteredData(String type) {
    final now = DateTime.now();
    final data = type == 'income' ? incomeData : expenseData;
    return data.where((e) {
      final date = e['date'] as DateTime;
      if (selectedFilter == 'Monthly') {
        return date.month == now.month && date.year == now.year;
      } else if (selectedFilter == 'Weekly') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      } else {
        return date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
      }
    }).toList();
  }

  double _total(String type) {
    final filtered = _filteredData(type);
    return filtered
        .map<double>((e) => (e['amount'] as num).toDouble())
        .fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final income = _total('income');
    final expense = _total('expense');
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Budget Overview", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildBudgetCard(balance, income, expense),
              const SizedBox(height: 20),
              _buildInfoSection("Income", income, Colors.green),
              const SizedBox(height: 10),
              _buildInfoSection("Expenses", expense, Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Filter: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        DropdownButton<String>(
          value: selectedFilter,
          items: ['Daily', 'Weekly', 'Monthly']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedFilter = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBudgetCard(double balance, double income, double expense) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.deepPurple.shade50,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text("Total Balance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "LKR ${balance.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryTile("Income", income, Colors.green),
                _summaryTile("Expenses", expense, Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String title, double value, Color color) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          "LKR ${value.toStringAsFixed(2)}",
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text("LKR ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
