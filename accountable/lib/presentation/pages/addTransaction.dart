import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF6A5E7A);
const Color _secondaryColor = Color(0xFF888888);
const Color _accentColor = Color(0xFF9B8EB8);
const Color _textColor = Color(0xFFE0E0E0);
const Color _backgroundDark = Color(0xFF2D2B35);
const Color _cardDark = Color(0xFF3A364A);

class AddTransaction extends StatefulWidget {
  final String? initialAmount;
  final String? initialNotes;
  final DateTime? initialDate;
  final String? initialTransactionType;
  final String? initialCategory;

  const AddTransaction({
    super.key,
    this.initialAmount,
    this.initialNotes,
    this.initialDate,
    this.initialTransactionType,
    this.initialCategory,
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
      // Only auto-generate category if no initialCategory was provided
      if (widget.initialCategory == null) {
        _autoGenerateCategory(widget.initialNotes!);
      }
    }
    // Initialize date if provided
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate;
    }
    // Initialize transaction type if provided
    if (widget.initialTransactionType != null) {
      transactionType = widget.initialTransactionType!;
    }
    // Initialize category if provided
    if (widget.initialCategory != null) {
      selectedCategory = widget.initialCategory;
    }
  }

  // Helper function to call generateCategory asynchronously
  Future<void> _autoGenerateCategory(String notes) async {
    // Create a temporary transaction object just for category generation
    // We need some dummy values for date and amount, they aren't used by generateCategory
    final tempTrans = Trans(
      transName: notes,
      transactionDate: DateTime.now(), // Dummy date
      amount: 0.0, // Dummy amount
      transType: TransactionType.other, // Start with default
    );

    await tempTrans.generateCategory(); // Call the Firestore function

    // Update the state if a category other than 'other' was generated
    if (tempTrans.transType != TransactionType.other) {
      setState(() {
        // Convert the generated enum back to the lowercase string used by the UI
        selectedCategory = transTypeToString(tempTrans.transType).toLowerCase();
        debugPrint("Automatically set category to: $selectedCategory");
      });
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
          backgroundColor: _cardDark,
          title: Text('Select Category', style: TextStyle(color: _textColor)),
          content: SingleChildScrollView(
            child: Column(
              children: categories
                  .map((category) => RadioListTile<String>(
                        title:
                            Text(category, style: TextStyle(color: _textColor)),
                        value: category,
                        groupValue: selectedCategory,
                        activeColor: _accentColor,
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
          backgroundColor: _cardDark,
          title: Text('Select Transaction Type',
              style: TextStyle(color: _textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Deposit', 'Withdraw']
                .map((type) => RadioListTile<String>(
                      title: Text(type, style: TextStyle(color: _textColor)),
                      value: type,
                      groupValue: transactionType,
                      activeColor: _accentColor,
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryColor,
              onPrimary: _textColor,
              surface: _cardDark,
              onSurface: _textColor,
            ),
            dialogBackgroundColor: _backgroundDark,
          ),
          child: child!,
        );
      },
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
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Transaction', style: TextStyle(color: _textColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount',
                style: TextStyle(
                    color: _textColor.withOpacity(0.7), fontSize: 16)),
            TextField(
              controller: amountController,
              style: const TextStyle(color: _textColor),
              decoration: InputDecoration(
                suffixText: 'THB',
                suffixStyle: const TextStyle(color: _textColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _textColor.withOpacity(0.7)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Date',
                style: TextStyle(
                    color: _textColor.withOpacity(0.7), fontSize: 16)),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: _textColor.withOpacity(0.7))),
                ),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : '${selectedDate!.toLocal()}'.split(' ')[0],
                  style: const TextStyle(color: _textColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Notes',
                style: TextStyle(
                    color: _textColor.withOpacity(0.7), fontSize: 16)),
            TextField(
              controller: notesController,
              style: const TextStyle(color: _textColor),
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _textColor.withOpacity(0.7)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _showCategoryDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  child: Text(
                    selectedCategory ?? 'Add Category',
                    style: const TextStyle(color: _textColor),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _showTransactionTypeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                  ),
                  child: Text(
                    transactionType,
                    style: const TextStyle(color: _textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
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

                  // Check if we're in edit mode (all initial values were provided)
                  bool isEditMode = widget.initialAmount != null &&
                      widget.initialNotes != null &&
                      widget.initialDate != null &&
                      widget.initialCategory != null;

                  final transactionsList = TransList();

                  if (isEditMode) {
                    // Find and update the existing transaction
                    for (int i = 0;
                        i < transactionsList.transactions.length;
                        i++) {
                      final existingTrans = transactionsList.transactions[i];
                      // Check if this is the same transaction we're editing
                      if (existingTrans.transName == widget.initialNotes &&
                          existingTrans.transactionDate == widget.initialDate &&
                          existingTrans.amount.toStringAsFixed(2) ==
                              widget.initialAmount) {
                        // Replace with updated transaction
                        final updatedTrans = Trans.withType(
                          transName: notes,
                          transactionDate: date,
                          amount: amount,
                          transType: transType,
                        );

                        // Update in database using the new method
                        updatedTrans.updateInDB(existingTrans);

                        // Remove the old transaction
                        transactionsList.removeTransaction(existingTrans);

                        // Add the updated transaction
                        transactionsList.addTransaction(updatedTrans);
                        updatedTrans.voteCategory();

                        // Exit the loop once updated
                        break;
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Transaction updated")),
                    );
                  } else {
                    // Create new transaction
                    final trans = Trans.withType(
                      transName: notes,
                      transactionDate: date,
                      amount: amount,
                      transType: transType,
                    );

                    trans.saveToDB(); // inserts into SQLite
                    transactionsList
                        .addTransaction(trans); // add to in-memory session
                    trans.voteCategory(); // Vote for the category in Firestore

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Transaction saved")),
                    );
                  }

                  debugPrint("==== Current TransList Transactions ====");
                  for (var t in transactionsList.transactions) {
                    debugPrint(t.toString());
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(color: _textColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
