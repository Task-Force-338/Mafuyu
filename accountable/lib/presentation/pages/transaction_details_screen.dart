import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

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
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Transaction Detail',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate, // Use formatted date
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                // Changed from const Row
                children: [
                  const Icon(Icons.arrow_upward,
                      color: Colors.red), // Assuming all are expenses for now
                  const SizedBox(width: 8),
                  Text(
                      transaction.amount
                          .toStringAsFixed(2), // Use transaction amount
                      style:
                          const TextStyle(color: Colors.white, fontSize: 20)),
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
            _buildSlipInfo(), // Keep slip info for now, might need adjustment later
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontSize: 18),
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
        color: Colors.blueGrey.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            // Wrap Text in Expanded to prevent overflow and allow alignment
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          Align(
            // Keep Align for the edit button
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                // TODO: Pass transaction data to edit screen
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AddTransaction()) // Pass transaction later
                    );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlipInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Slip Info',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(width: 8),
              Column(
                // Changed from const Column
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You', // Keep placeholder for now
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  const Text('นายประยุทธ์ น.', // Keep placeholder for now
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                      DateFormat('EEE dd MMM yy HH:mm').format(transaction
                          .transactionDate), // Use transaction date/time
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade400,
                child: const Center(
                  child: Text('Slip',
                      style: TextStyle(color: Colors.black, fontSize: 14)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
