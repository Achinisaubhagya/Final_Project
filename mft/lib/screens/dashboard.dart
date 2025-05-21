import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mft/screens/settings_page.dart';
import 'package:mft/screens/notification_page.dart';
import 'package:mft/screens/income_page.dart';
import 'package:mft/screens/expense_page.dart';
import 'package:mft/screens/today_page.dart';
import 'package:mft/screens/goal_list_page.dart';
import 'package:mft/screens/history_page.dart';
import 'package:mft/screens/budget_page.dart';
import 'package:mft/screens/profile_page.dart' as profile;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  String _fullName = "";
  String? _userId;

  final List<Widget> _pages = [
    const DashboardPage(),
    HistoryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    fetchAndSetUserIdentity();
  }

  // Fetch userId from identity collection using logged in email
  Future<void> fetchAndSetUserIdentity() async {
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
        });
        fetchUserFullName();
      }
    }
  }

  // Fetch user full name from users collection using email
  Future<void> fetchUserFullName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final fullName = snapshot.docs.first['fullName'];
        setState(() {
          _fullName = fullName.split(" ").first; // only get first name
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildHomeContent()
            : _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings"),
          ],
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Listen to both incomes and expenses for real-time updates
    final incomesStream = FirebaseFirestore.instance
        .collection('incomes')
        .where('userId', isEqualTo: _userId)
        .snapshots();

    final expensesStream = FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: _userId)
        .snapshots();

    final goalsStream = FirebaseFirestore.instance
        .collection('goals')
        .where('userId', isEqualTo: _userId)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: incomesStream,
      builder: (context, incomeSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: expensesStream,
          builder: (context, expenseSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: goalsStream,
              builder: (context, goalsSnapshot) {
                double totalIncome = 0;
                double totalExpense = 0;
                int goalCount = 0;

                if (incomeSnapshot.hasData) {
                  for (var doc in incomeSnapshot.data!.docs) {
                    totalIncome += (doc['amount'] as num).toDouble();
                  }
                }

                if (expenseSnapshot.hasData) {
                  for (var doc in expenseSnapshot.data!.docs) {
                    totalExpense += (doc['amount'] as num).toDouble();
                  }
                }

                if (goalsSnapshot.hasData) {
                  goalCount = goalsSnapshot.data!.docs.length;
                }

                double availableBalance = totalIncome - totalExpense;

                return RefreshIndicator(
                  onRefresh: () async {
                    await fetchAndSetUserIdentity();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              profile.ProfilePage()));
                                },
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundImage: AssetImage(
                                          'assets/images/profile icon.jpg'),
                                      radius: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Hi $_fullName 👋",
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const Text("Welcome back!",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_none, size: 30),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            NotificationPage()));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Balance Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BudgetPage()));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3A2EFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.deepPurpleAccent.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Available Balance",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 12),
                                Text(
                                  "LKR ${availableBalance.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 34,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text("Tap to see details",
                                    style: TextStyle(
                                        color: Colors.white60, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Grid with real-time values
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildFeatureCard(
                              context,
                              title: "Income",
                              value: "LKR ${totalIncome.toStringAsFixed(2)}",
                              icon: Icons.attach_money,
                              color: Colors.green,
                              page: IncomePage(),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Expense",
                              value: "LKR ${totalExpense.toStringAsFixed(2)}",
                              icon: Icons.money_off,
                              color: Colors.red,
                              page: ExpensePage(),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Today",
                              value: "View",
                              icon: Icons.today,
                              color: Colors.deepPurple,
                              page: TodayPage(),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Goals",
                              value: "$goalCount Goals",
                              icon: Icons.flag,
                              color: Colors.orange,
                              page: const GoalListPage(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required Widget page}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}