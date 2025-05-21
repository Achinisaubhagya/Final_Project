import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({Key? key}) : super(key: key);

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  String selectedType = 'Income';
  final List<String> types = ['Income', 'Expense'];

  String selectedCategory = 'Salary';
  final Map<String, List<String>> categories = {
    'Income': ['Salary', 'Business', 'Investment', 'Other'],
    'Expense': ['Food', 'Transportation', 'Shopping', 'Bills', 'Other'],
  };

  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? userId;
  String? uid;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    selectedCategory = categories[selectedType]![0];
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final QuerySnapshot identityDoc = await FirebaseFirestore.instance
            .collection('identity')
            .where('email', isEqualTo: user.email)
            .get();

        if (identityDoc.docs.isNotEmpty) {
          final userData = identityDoc.docs.first.data() as Map<String, dynamic>;
          setState(() {
            userId = userData['userId'] as String?;
            uid = userData['uid'] as String?;
            userEmail = userData['email'] as String?;
          });
          print('User Data Fetched - UserId: $userId, Uid: $uid, Email: $userEmail');
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> saveDataToFirebase() async {
    try {
      if (amountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount'), backgroundColor: Colors.red),
        );
        return;
      }

      if (userId == null || uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found. Please login again.'), backgroundColor: Colors.red),
        );
        return;
      }

      String rawAmount = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      int amount = int.tryParse(rawAmount) ?? 0;

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
        );
        return;
      }

      final data = {
        'userId': userId,
        'uid': uid,
        'email': userEmail,
        'type': selectedType,
        'category': selectedCategory,
        'date': Timestamp.fromDate(selectedDate),
        'amount': amount,
        'description': descController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final collection = selectedType.toLowerCase() + 's';
      await FirebaseFirestore.instance.collection(collection).add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedType added successfully'),
          backgroundColor: selectedType == 'Income' ? Colors.green : Colors.red,
        ),
      );

      amountController.clear();
      descController.clear();
      setState(() {
        selectedDate = DateTime.now();
        dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add data: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep all existing build method code exactly as is
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Add Today Data",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ... Keep all existing form fields code exactly as is ...
                      // Type Selection
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: types.map((type) {
                            bool isSelected = selectedType == type;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(
                                    type,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: type == 'Income' ? Colors.green : Colors.red,
                                  backgroundColor: Colors.white,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedType = type;
                                        selectedCategory = categories[type]![0];
                                      });
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Category",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        value: selectedCategory,
                        items: categories[selectedType]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val!),
                      ),
                      const SizedBox(height: 20),

                      // Date Picker
                      TextFormField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: "Date",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        readOnly: true,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                              dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Amount Field
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: "Amount *",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: selectedType == 'Income' ? Colors.green : Colors.red
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: "Description (Optional)",
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: const Icon(Icons.description, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'Income' ? Colors.green : Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: saveDataToFirebase,
                          child: Text(
                            "Save $selectedType",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}