import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEntryPage extends StatefulWidget {
  final String docId;
  final String type; // Either 'income' or 'expense'

  const EditEntryPage({Key? key, required this.docId, required this.type}) : super(key: key);

  @override
  _EditEntryPageState createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecord();
  }

  void _fetchRecord() async {
    setState(() {
      _isLoading = true;
    });

    final doc = await FirebaseFirestore.instance
        .collection(widget.type == 'income' ? 'incomes' : 'expenses')
        .doc(widget.docId)
        .get();

    if (doc.exists) {
      _amountController.text = doc['amount'].toString();
      _categoryController.text = doc['category'] ?? '';
      _dateController.text = doc['date'].toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _saveEntry() async {
    if (_amountController.text.isEmpty || _categoryController.text.isEmpty) {
      return; // Validation for empty fields
    }

    setState(() {
      _isLoading = true;
    });

    await FirebaseFirestore.instance.collection(widget.type == 'income' ? 'incomes' : 'expenses').doc(widget.docId).update({
      'amount': double.parse(_amountController.text),
      'category': _categoryController.text,
      'date': _dateController.text, // Add logic for date if required
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.type.capitalize} Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: 'Date'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveEntry,
                    child: const Text('Save'),
                  ),
                ],
              ),
      ),
    );
  }
}

extension StringCapitalization on String {
  String get capitalize => this[0].toUpperCase() + this.substring(1).toLowerCase();
}
