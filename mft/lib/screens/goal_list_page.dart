import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mft/screens/add_goal_page.dart';

class GoalListPage extends StatefulWidget {
  const GoalListPage({super.key});

  @override
  State<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends State<GoalListPage> {
  void _navigateToAddGoal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalPage()),
    );
    setState(() {}); // Refresh the list after returning
  }

  void _deleteGoal(String docId) async {
    await FirebaseFirestore.instance.collection('goals').doc(docId).delete();
  }

  void _editGoal(DocumentSnapshot goal) {
    final nameController = TextEditingController(text: goal['name']);
    final descriptionController = TextEditingController(text: goal['description']);
    final amountController = TextEditingController(text: goal['amount'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Goal Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('goals').doc(goal.id).update({
                'name': nameController.text,
                'description': descriptionController.text,
                'amount': double.tryParse(amountController.text) ?? 0.0,
              });
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 77, 31, 185),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Goals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('goals')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No goals added yet.'));
                  }

                  final goals = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(goal['description'] ?? ''),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${goal['amount'].toStringAsFixed(2)} ${goal['currency']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editGoal(goal);
                                    } else if (value == 'delete') {
                                      _deleteGoal(goal.id);
                                    }
                                  },
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [

                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [

                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGoal,
        backgroundColor: const Color.fromARGB(255, 142, 152, 212),
        child: const Icon(Icons.add),
      ),
    );
  }
}
