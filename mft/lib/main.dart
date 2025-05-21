import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mft/screens/welcome_screen.dart';
import 'package:mft/screens/login_page.dart';
import 'package:mft/screens/signup_page.dart';
import 'package:mft/screens/forgot.dart';
import 'package:mft/screens/update.dart';
import 'package:mft/screens/dashboard.dart';
import 'package:mft/screens/today_page.dart';
import 'package:mft/screens/expense_page.dart';
import 'package:mft/screens/income_page.dart';
import 'package:mft/screens/notification_page.dart';
import 'package:mft/screens/goal_list_page.dart';
import 'package:mft/screens/add_goal_page.dart';
import 'package:mft/screens/profile_page.dart';
import 'package:mft/screens/settings_page.dart';
import 'package:mft/screens/history_page.dart';
import 'package:mft/screens/budget_page.dart';
import 'package:mft/screens/edit_profile.dart';
import 'package:mft/screens/reminder.dart';

import 'package:mft/screens/app_guide.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/forgot': (context) => ForgotPasswordPage(),
        '/update': (context) => UpdatePasswordPage(),
        '/dashboard': (context) => DashboardPage(),
        '/today': (context) => TodayPage(),
        '/expense': (context) => ExpensePage(),
        '/income': (context) => IncomePage(),
        '/notification': (context) => NotificationPage(),
        '/goal_list': (context) => GoalListPage(),
        '/add_goal': (context) => AddGoalPage(),
        '/profile': (context) => ProfilePage(),
        '/budget': (context) => BudgetPage(),
        '/history': (context) => HistoryPage(),
        '/settings': (context) => SettingsPage(),
        '/edit_profile': (context) => EditProfilePage(),
        '/reminder': (context) => ReminderPage(),
      
        '/app_guide': (context) => AppGuidePage(),
      },
    );
  }
}
