import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

// Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF6A5E7A);
const Color _secondaryColor = Color(0xFF888888);
const Color _accentColor = Color(0xFF9B8EB8);
const Color _textColor = Color(0xFFE0E0E0);
const Color _backgroundDark = Color(0xFF2D2B35);
const Color _cardDark = Color(0xFF3A364A);
const Color _errorColor = Color(0xFFE57373); // Light red for errors

class TransactionDetailScreen extends StatelessWidget {
  final Trans transaction; // Add transaction field

  const TransactionDetailScreen(
      {super.key, required this.transaction}); // Update constructor

  // Helper function to get icon based on transaction type
  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.food:
        return Icons.restaurant;
      case TransactionType.personal:
        return Icons.person;
      case TransactionType.utility:
        return Icons.lightbulb;
      case TransactionType.transportation:
        return Icons.directions_bus;
      case TransactionType.health:
        return Icons.local_hospital;
      case TransactionType.leisure:
        return Icons.movie;
      case TransactionType.other:
      default:
        return Icons.category;
    }
  }

  // Helper function to get string representation of transaction type
  String _getStringForType(TransactionType type) {
    return transTypeToString(type); // Use existing helper
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE dd MMM yy')
        .format(transaction.transactionDate); // Format the date

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaction Detail',
            style: TextStyle(color: _textColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate, // Use formatted date
              style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                // Changed from const Row
                children: [
                  const Icon(Icons.arrow_upward,
                      color: _errorColor), // Assuming all are expenses for now
                  const SizedBox(width: 8),
                  Text(
                      transaction.amount
                          .toStringAsFixed(2), // Use transaction amount
                      style: const TextStyle(color: _textColor, fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
                _getIconForType(transaction.transType),
                _getStringForType(transaction.transType),
                context), // Use transaction type icon and string
            const SizedBox(height: 10),
            _buildInfoTile(Icons.edit, transaction.transName,
                context), // Use transaction name/notes
            const SizedBox(height: 20),
            // _buildSlipInfo(), // Commented out mock slip info
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: _cardDark,
                        title: const Text('Delete Transaction',
                            style: TextStyle(color: _textColor)),
                        content: const Text(
                            'Are you sure you want to delete this transaction?',
                            style: TextStyle(color: _textColor)),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: _accentColor)),
                          ),
                          TextButton(
                            onPressed: () {
                              // Get the transaction list
                              final transactionsList = TransList();

                              // Delete from database
                              transaction.deleteFromDB();

                              // Remove the transaction from memory
                              transactionsList.removeTransaction(transaction);

                              // Go back to home page
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Go back to home
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: _errorColor)),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: _errorColor, fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textColor),
          const SizedBox(width: 8),
          Expanded(
            // Wrap Text in Expanded to prevent overflow and allow alignment
            child: Text(text,
                style: const TextStyle(color: _textColor, fontSize: 16)),
          ),
          Align(
            // Keep Align for the edit button
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.edit, color: _accentColor),
              onPressed: () async {
                // Pass transaction data to edit screen
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddTransaction(
                              initialAmount:
                                  transaction.amount.toStringAsFixed(2),
                              initialNotes: transaction.transName,
                              initialDate: transaction.transactionDate,
                              initialTransactionType:
                                  "Withdraw", // Assuming it's a withdrawal
                              initialCategory:
                                  transTypeToString(transaction.transType)
                                      .toLowerCase(),
                            )));

                // Pop back to home page to refresh the transaction list
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  // Commented out mock slip info method
  /*
  Widget _buildSlipInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Slip Info',
              style: TextStyle(color: _textColor, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _secondaryColor,
                child: Icon(Icons.person, color: _backgroundDark),
              ),
              const SizedBox(width: 8),
              Column(
                // Changed from const Column
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You', // Keep placeholder for now
                      style: TextStyle(color: _textColor, fontSize: 14)),
                  const Text('นายประยุทธ์ น.', // Keep placeholder for now
                      style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
                  Text(
                      DateFormat('EEE dd MMM yy HH:mm').format(transaction
                          .transactionDate), // Use transaction date/time
                      style:
                          const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                color: _secondaryColor,
                child: const Center(
                  child: Text('Slip',
                      style: TextStyle(color: _backgroundDark, fontSize: 14)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
  */
}
