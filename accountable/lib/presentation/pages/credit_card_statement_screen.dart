import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:accountable/services/ocr_service.dart';
import 'dart:io';

// Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF6A5E7A);
const Color _secondaryColor = Color(0xFF888888);
const Color _accentColor = Color(0xFF9B8EB8);
const Color _textColor = Color(0xFFE0E0E0);
const Color _backgroundDark = Color(0xFF2D2B35);
const Color _cardDark = Color(0xFF3A364A);
const Color _errorColor = Color(0xFFE57373); // Light red for errors
const Color _successColor = Color(0xFF81C784); // Light green for success

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
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Credit Card Statement Upload',
          style: TextStyle(color: _textColor),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.credit_card,
                    color: _textColor,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload your credit card statement PDF to automatically extract transactions',
                    style: TextStyle(color: _textColor, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload a PDF statement from your bank',
                    style: TextStyle(
                        color: _textColor.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      fillColor: Colors.transparent,
                      hintText: _selectedFilePath != null
                          ? File(_selectedFilePath!).path.split('/').last
                          : 'No file selected',
                      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _secondaryColor),
                      ),
                    ),
                    style: const TextStyle(color: _textColor),
                  ),
                  const SizedBox(height: 16),
                  // Upload button
                  if (_passwordRequired)
                    Column(
                      children: [
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: _textColor),
                            hintText: 'Enter PDF password',
                            hintStyle:
                                TextStyle(color: _textColor.withOpacity(0.7)),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: _secondaryColor),
                            ),
                          ),
                          style: const TextStyle(color: _textColor),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                          ),
                          child: const Text(
                            'Submit Password',
                            style: TextStyle(color: _textColor),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: _textColor),
                      label: Text(
                        'SELECT PDF FILE',
                        style: const TextStyle(color: _textColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      onPressed: _isProcessing ? null : _pickAndProcessFile,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: _accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Processing your statement...',
                    style: TextStyle(color: _textColor.withOpacity(0.7)),
                  ),
                ],
              ),

            // Transactions list
            if (_extractedTransactions.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: _secondaryColor),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Found ${_extractedTransactions.length} Transactions',
                  style: const TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: _secondaryColor),
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
                        isExpense ? _errorColor : _successColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(transaction['description'] ?? 'Unknown',
                            style: const TextStyle(
                                color: _textColor, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Date: ${transaction['date'] ?? 'Unknown'}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _textColor.withOpacity(0.6)),
                                maxLines: 1),
                            const SizedBox(height: 2),
                            Text(
                                'Posting: ${transaction['posting_date'] ?? 'Unknown'}',
                                style: TextStyle(
                                    color: _textColor.withOpacity(0.7)),
                                maxLines: 1),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(amountStr,
                                style:
                                    TextStyle(fontSize: 14, color: amountColor),
                                maxLines: 1),
                            const SizedBox(height: 2),
                            Text(
                                'Merchant: ${transaction['merchant'] ?? 'Unknown'}',
                                style: TextStyle(
                                    color: _textColor.withOpacity(0.7)),
                                maxLines: 1),
                          ],
                        ),
                        onTap: () => _addTransactionToApp(transaction),
                        // Add icon to show it's tappable
                        leading:
                            const Icon(Icons.add_circle, color: _accentColor),
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_isProcessing && _selectedFilePath != null) ...[
              const SizedBox(height: 30),
              // Show "no transactions found" message
              Text(
                'No transactions found in the document.',
                style: TextStyle(color: _textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 10),
              Text(
                'Try uploading a different statement or check if your bank format is supported.',
                style:
                    TextStyle(color: _textColor.withOpacity(0.7), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
