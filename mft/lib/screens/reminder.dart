import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final _auth = FirebaseAuth.instance;
  late final String userId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      userId = "";
    }
  }

  void _addReminder() {
    String title = "";
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Reminder",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(selectedDate == null
                        ? "Pick a date"
                        : DateFormat.yMMMMd().format(selectedDate!)),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setModalState(() => selectedDate = pickedDate);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: Text(selectedTime == null
                        ? "Pick a time"
                        : selectedTime!.format(context)),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setModalState(() => selectedTime = pickedTime);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (title.isNotEmpty &&
                          selectedDate != null &&
                          selectedTime != null) {
                        _saveReminder(title, selectedDate!, selectedTime!);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please complete all fields")),
                        );
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Save Reminder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _editReminder(String docId, String currentTitle, DateTime currentDate,
      TimeOfDay currentTime) {
    String title = currentTitle;
    DateTime? selectedDate = currentDate;
    TimeOfDay? selectedTime = currentTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Reminder",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: title),
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(selectedDate == null
                        ? "Pick a date"
                        : DateFormat.yMMMMd().format(selectedDate!)),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setModalState(() => selectedDate = pickedDate);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: Text(selectedTime == null
                        ? "Pick a time"
                        : selectedTime!.format(context)),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setModalState(() => selectedTime = pickedTime);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (title.isNotEmpty &&
                          selectedDate != null &&
                          selectedTime != null) {
                        FirebaseFirestore.instance
                            .collection('reminders')
                            .doc(docId)
                            .update({
                          'title': title,
                          'date': Timestamp.fromDate(selectedDate!),
                          'time': {
                            'hour': selectedTime!.hour,
                            'minute': selectedTime!.minute
                          },
                          'userId': userId, // <-- Ensure this is updated too
                        });
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.update),
                    label: const Text("Update Reminder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _deleteReminder(String docId) {
    FirebaseFirestore.instance.collection('reminders').doc(docId).delete();
  }

  void _saveReminder(String title, DateTime date, TimeOfDay time) {
    FirebaseFirestore.instance.collection('reminders').add({
      'userId': userId, // <-- Use 'userId' for consistency
      'title': title,
      'date': Timestamp.fromDate(date),
      'time': {'hour': time.hour, 'minute': time.minute},
      'enabled': true, // Optional: for notification logic
    });
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat.yMMMMd().add_jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Reminders Yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? '';
              final date = (data['date'] as Timestamp).toDate();
              final timeMap = data['time'] as Map<String, dynamic>;
              final time =
                  TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']);

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(_formatDateTime(date, time)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReminder(doc.id, title, date, time);
                      } else if (value == 'delete') {
                        _deleteReminder(doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ),
    );
  }
}