import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  double totalIncome = 0;
  double totalExpense = 0;
  List<Map<String, dynamic>> incomeData = [];
  List<Map<String, dynamic>> expenseData = [];
  String selectedFilter = 'Monthly';
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    final incomeSnapshot = await FirebaseFirestore.instance
        .collection('incomes')
        .where('uid', isEqualTo: userId)
        .get();

    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('uid', isEqualTo: userId)
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
        title: const Text("History", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(),
              const SizedBox(height: 16),
              _buildSummaryCard(balance, income, expense),
              const SizedBox(height: 20),
              _buildPieChart(income, expense),
              const SizedBox(height: 20),
              _buildBarChart(income, expense),
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
        const Text("View: ", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSummaryCard(double balance, double income, double expense) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Total Balance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("LKR ${balance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 24, color: Colors.deepPurple)),
            const Divider(height: 20),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("LKR ${value.toStringAsFixed(2)}", style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildPieChart(double income, double expense) {
    final total = income + expense;
    if (total == 0)
      return const Text("No data available to display pie chart.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Income vs Expense - Pie Chart",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                  value: income,
                  color: Colors.green,
                  title: "${((income / total) * 100).toStringAsFixed(1)}%",
                  radius: 60,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: expense,
                  color: Colors.red,
                  title: "${((expense / total) * 100).toStringAsFixed(1)}%",
                  radius: 60,
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Legend(color: Colors.green, label: "Income"),
            Legend(color: Colors.red, label: "Expense"),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(double income, double expense) {
    const fixedMaxY = 90000.0; // Fixed maxY to 90000

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Income vs Expense - Bar Chart",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: fixedMaxY,
              barGroups: [
                BarChartGroupData(x: 0, barRods: [
                  BarChartRodData(
                      toY: income > fixedMaxY ? fixedMaxY : income,
                      color: Colors.green,
                      width: 30),
                ]),
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(
                      toY: expense > fixedMaxY ? fixedMaxY : expense,
                      color: Colors.red,
                      width: 30),
                ]),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 15000,
                    getTitlesWidget: (value, _) =>
                        Text('LKR ${value.toInt()}'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text("Income");
                        case 1:
                          return const Text("Expense");
                        default:
                          return const Text("");
                      }
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    );
  }
}

class Legend extends StatelessWidget {
  final Color color;
  final String label;
  const Legend({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
