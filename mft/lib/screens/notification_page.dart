import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? "";
    _checkDueReminders();
    _addDailyReminderIfNeeded();
  }

  Future<void> _addDailyReminderIfNeeded() async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final currentHour = now.hour;
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    if (currentHour >= 22) {
      final reminderDoc = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'reminder')
          .where('date', isEqualTo: dateStr)
          .where('userId', isEqualTo: userId)
          .get();

      if (reminderDoc.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Daily Reminder',
          'subtitle': 'Don\'t forget to add your income and expenses today!',
          'time': 'Today at 10:00 PM',
          'type': 'reminder',
          'date': dateStr,
          'timestamp': Timestamp.now(),
          'userId': userId,
        });
      }
    }
  }

  Future<void> _checkDueReminders() async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

    final reminders = await FirebaseFirestore.instance
        .collection('reminders')
        .where('enabled', isEqualTo: true)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in reminders.docs) {
      final data = doc.data();
      final DateTime date = (data['date'] as Timestamp).toDate();
      final Map<String, dynamic> timeMap = Map<String, dynamic>.from(data['time']);
      final reminderTime = DateTime(date.year, date.month, date.day, timeMap['hour'], timeMap['minute']);

      if (now.isAfter(reminderTime)) {
        final alreadyExists = await FirebaseFirestore.instance
            .collection('notifications')
            .where('type', isEqualTo: 'user_reminder')
            .where('reminderId', isEqualTo: doc.id)
            .where('userId', isEqualTo: userId)
            .get();

        if (alreadyExists.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'title': data['title'] ?? 'Reminder',
            'subtitle': 'Reminder from your schedule',
            'time': DateFormat('yMMMd').add_jm().format(reminderTime),
            'type': 'user_reminder',
            'reminderId': doc.id,
            'timestamp': Timestamp.now(),
            'userId': userId,
          });
        }
      }
    }
  }

  // Only get notifications, not reminders directly
  Stream<List<Map<String, dynamic>>> _getNotificationsOnly() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['source'] = 'notifications';
              return data;
            }).toList());
  }

  Future<void> _deleteNotification(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNotificationsOnly(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text("No Notifications", style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index];

              return Dismissible(
                key: Key(data['id']),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  final confirm = await _showDeleteConfirmationDialog();
                  if (confirm == true) {
                    await _deleteNotification(data['source'], data['id']);
                    return true;
                  }
                  return false;
                },
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete, color: Colors.white, size: 32),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['subtitle']),
                    trailing: Text(data['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}