import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTransaction extends StatefulWidget {
  final String? initialAmount;
  final String? initialNotes;

  const AddTransaction({
    super.key,
    this.initialAmount,
    this.initialNotes,
  });

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String transactionType = 'Withdraw';
  String? selectedCategory;
  DateTime? selectedDate;
  final List<String> categories = [
    'food',
    'personal',
    'utility',
    'transportation',
    'health',
    'leisure',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed data if available
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount!;
    }
    if (widget.initialNotes != null) {
      notesController.text = widget.initialNotes!;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SingleChildScrollView(
            child: Column(
              children: categories
                  .map((category) => RadioListTile<String>(
                        title: Text(category),
                        value: category,
                        groupValue: selectedCategory,
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Transaction Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Deposit', 'Withdraw']
                .map((type) => RadioListTile<String>(
                      title: Text(type),
                      value: type,
                      groupValue: transactionType,
                      onChanged: (value) {
                        setState(() {
                          transactionType = value!;
                        });
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Transaction',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amount',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                suffixText: 'THB',
                suffixStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Date',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white70)),
                ),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : '${selectedDate!.toLocal()}'.split(' ')[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Notes',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            TextField(
              controller: notesController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _showCategoryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                  ),
                  child: Text(
                    selectedCategory ?? 'Add Category',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showTransactionTypeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                  ),
                  child: Text(
                    transactionType,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade500,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  final notes = notesController.text;
                  debugPrint("selectedCategory: $selectedCategory");
                  final typeStr = selectedCategory?.toLowerCase() ?? "other";
                  debugPrint("transactionType: $typeStr");
                  final transType = stringToTransType(typeStr);
                  debugPrint("transactionType: $transType");
                  final date = selectedDate ?? DateTime.now();

                  if (amount == null || notes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please fill in all fields")),
                    );
                    return;
                  }

                  final trans = Trans.withType(
                    transName: notes,
                    transactionDate: date,
                    amount: amount,
                    transType: transType,
                  );

                  trans.saveToDB(); // inserts into SQLite
                  TransList().addTransaction(trans); // add to in-memory session
                  debugPrint("==== Current TransList Transactions ====");
                  for (var t in TransList().transactions) {
                    debugPrint(t.toString());
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction saved")),
                  );
                },
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
