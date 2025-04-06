import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:accountable/services/ocr_service.dart';
import 'dart:io';

class CreditCardStatementScreen extends StatefulWidget {
  const CreditCardStatementScreen({super.key});

  @override
  _CreditCardStatementScreenState createState() =>
      _CreditCardStatementScreenState();
}

class _CreditCardStatementScreenState extends State<CreditCardStatementScreen> {
  final OcrService _ocrService = OcrService();
  String? _selectedFilePath;
  List<Map<String, String?>> _extractedTransactions = [];
  bool _isProcessing = false;
  bool _passwordRequired = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        setState(() {
          _selectedFilePath = filePath;
          _extractedTransactions = [];
          _passwordRequired = false;
          _isProcessing = true;
        });

        print("Selected file: $filePath");
        await _processFile(filePath);
      } else {
        print("File picking cancelled.");
      }
    } catch (e) {
      print("Error during file picking: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() {
        _selectedFilePath = null;
        _extractedTransactions = [];
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFile(String filePath, {String? password}) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      List<Map<String, String?>> transactions = await _ocrService
          .extractCreditCardStatementData(filePath, password: password);

      if (transactions.isNotEmpty &&
          transactions[0].containsKey('password_required')) {
        setState(() {
          _passwordRequired = true;
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _extractedTransactions = transactions;
        _passwordRequired = false;
        _isProcessing = false;
      });

      print("Extracted ${transactions.length} transactions");
    } catch (e) {
      print("Error processing PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing PDF: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _submitPassword() {
    if (_passwordController.text.isNotEmpty && _selectedFilePath != null) {
      _processFile(_selectedFilePath!, password: _passwordController.text);
      setState(() {
        _passwordRequired = false;
      });
    }
  }

  void _addTransactionToApp(Map<String, String?> transaction) {
    // Convert transaction date - use transaction date as primary, fallback to posting date
    DateTime? transactionDate = _parseDate(transaction['date']) ??
        _parseDate(transaction['posting_date']);

    // Format the description to include both description and dates for reference
    String description = transaction['description'] ?? 'Unknown';
    if (transaction['posting_date'] != null) {
      description += ' (Posted: ${transaction['posting_date']})';
    }

    // Parse amount for transaction type determination
    final String amountStr = transaction['amount'] ?? '0.00';
    final double amountValue = double.tryParse(
            transaction['amount_value'] ?? amountStr.replaceAll(',', '')) ??
        0.0;

    // Determine if this is likely an expense/purchase based on amount or description
    final bool isExpense = amountValue < 0 ||
        (transaction['description']?.toLowerCase().contains('purchase') ??
            false) ||
        !(transaction['description']?.toLowerCase().contains('payment') ??
            false);

    // Get absolute value of amount for display
    final String absAmount = amountValue.abs().toStringAsFixed(2);

    // Determine transaction type based on whether it's an expense
    final String transactionType = isExpense ? 'Withdraw' : 'Deposit';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransaction(
          initialAmount: absAmount,
          initialNotes: description,
          initialDate: transactionDate,
          initialTransactionType: transactionType,
        ),
      ),
    );
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;

    try {
      // Try DD/MM/YYYY format
      final RegExp dateRegex = RegExp(r'(\d{2})/(\d{2})/(\d{4})');
      final match = dateRegex.firstMatch(dateStr);

      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }

      // Try DD MMM YYYY format
      final RegExp monthNameRegex =
          RegExp(r'(\d{2})\s+([A-Za-z]{3})\s+(\d{4})');
      final matchMonthName = monthNameRegex.firstMatch(dateStr);

      if (matchMonthName != null) {
        final day = int.parse(matchMonthName.group(1)!);
        final monthName = matchMonthName.group(2)!;
        final year = int.parse(matchMonthName.group(3)!);

        final months = {
          'Jan': 1,
          'Feb': 2,
          'Mar': 3,
          'Apr': 4,
          'May': 5,
          'Jun': 6,
          'Jul': 7,
          'Aug': 8,
          'Sep': 9,
          'Oct': 10,
          'Nov': 11,
          'Dec': 12
        };

        final month = months[monthName] ?? 1;
        return DateTime(year, month, day);
      }
    } catch (e) {
      print("Error parsing date: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        title: const Text('Credit Card Statement'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.credit_card,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload your credit card statement PDF',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Password dialog if required
            if (_passwordRequired) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'This PDF is password protected',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the password to decrypt the file. Your password will not be stored.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.blueGrey.shade600,
                        hintText: 'PDF Password',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      onSubmitted: (_) => _submitPassword(),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _submitPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade300,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          child: const Text('Submit',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _pickAndProcessFile,
                          child: const Text('Choose Different File',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: Text(
                  _selectedFilePath == null ? 'SELECT PDF FILE' : 'CHANGE FILE',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isProcessing ? null : _pickAndProcessFile,
              ),
            ],

            if (_selectedFilePath != null && !_passwordRequired) ...[
              const SizedBox(height: 15),
              Text(
                'Selected: ${_selectedFilePath!.split(Platform.pathSeparator).last}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],

            // Processing indicator
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                'Processing PDF...\nThis may take a moment',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],

            // Transactions list
            if (_extractedTransactions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Found ${_extractedTransactions.length} Transactions',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: _extractedTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _extractedTransactions[index];
                    // Parse amount for display with color based on positive/negative
                    final String amountStr = transaction['amount'] ?? '0.00';
                    final double amountValue = double.tryParse(
                            transaction['amount_value'] ??
                                amountStr.replaceAll(',', '')) ??
                        0.0;
                    final bool isExpense = amountValue < 0 ||
                        transaction['description']
                                ?.toLowerCase()
                                .contains('purchase') ==
                            true;

                    final Color amountColor =
                        isExpense ? Colors.red.shade300 : Colors.green.shade300;

                    return Card(
                      color: Colors.blueGrey.shade800,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 0),
                      child: ListTile(
                        title: Text(
                          transaction['description'] ?? 'Unknown Merchant',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.date_range,
                                    size: 14, color: Colors.white60),
                                SizedBox(width: 4),
                                Text(
                                  'Trans: ${transaction['date'] ?? 'Unknown'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            if (transaction['posting_date'] != null)
                              Row(
                                children: [
                                  Icon(Icons.book,
                                      size: 14, color: Colors.white60),
                                  SizedBox(width: 4),
                                  Text(
                                    'Post: ${transaction['posting_date']}',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            Row(
                              children: [
                                Icon(Icons.attach_money,
                                    size: 14, color: Colors.white60),
                                SizedBox(width: 4),
                                Text(
                                  'Amount: ${transaction['amount'] ?? 'Unknown'}',
                                  style: TextStyle(
                                      color: amountColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => _addTransactionToApp(transaction),
                          tooltip: 'Add this transaction',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_isProcessing &&
                _selectedFilePath != null &&
                !_passwordRequired) ...[
              const SizedBox(height: 30),
              const Text(
                'No transactions found in the statement.\nTry a different file or check file format.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ] else if (!_isProcessing && _selectedFilePath == null) ...[
              const Expanded(
                child: Center(
                  child: Text(
                    'Upload a credit card statement PDF to extract transactions automatically.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
