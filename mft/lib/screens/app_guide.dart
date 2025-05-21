import 'package:flutter/material.dart';
import 'package:mft/screens/dashboard.dart';

class AppGuidePage extends StatelessWidget {
  const AppGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Guide"),
        backgroundColor: const Color.fromARGB(255, 98, 119, 240),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to the MFT Budgeting App!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 98, 119, 240),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "This guide will help you navigate and understand the key features of the app.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildGuideSection(
                context,
                Icons.access_alarm,
                "Track Your Daily Income & Expenses",
                "Quickly log your daily income and expenses to maintain a solid record of your financial activity.",
              ),
              _buildGuideSection(
                context,
                Icons.calendar_today,
                "Plan Future Expenses",
                "Use the calendar feature to forecast upcoming expenses and prepare for the future.",
              ),
              _buildGuideSection(
                context,
                Icons.account_balance_wallet,
                "Monitor Your Balance",
                "Easily keep an eye on your balance, helping you stay within budget and avoid overspending.",
              ),
              _buildGuideSection(
                context,
                Icons.bar_chart,
                "Analyze with Reports",
                "Get weekly and monthly reports to visualize your financial trends and make informed decisions.",
              ),
              _buildGuideSection(
                context,
                Icons.check_circle_outline,
                "Set Financial Goals",
                "Create goals for saving, spending, or investing and track your progress toward achieving them.",
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 100, 120, 235),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Got It! Let's Start Budgeting",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "We hope this guide has helped. Enjoy managing your finances!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(
      BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color.fromARGB(255, 98, 119, 240),
            child: Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 45, 45, 45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
