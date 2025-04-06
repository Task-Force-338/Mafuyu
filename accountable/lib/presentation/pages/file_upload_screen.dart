import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:accountable/presentation/pages/credit_card_statement_screen.dart';
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
const Color _cardLightDark = Color(0xFF4A4758);

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool isAutomaticUpload = false;
  final OcrService _ocrService = OcrService();
  String? _selectedFilePath;
  Map<String, String?>? _ocrResult;
  bool _isProcessing = false;

  Future<void> _pickAndProcessFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        setState(() {
          _selectedFilePath = filePath;
          _ocrResult = null;
          _isProcessing = true;
        });

        print("Selected file: $filePath");

        Map<String, String?> ocrData =
            await _ocrService.extractSlipData(filePath);

        setState(() {
          _ocrResult = ocrData;
          _isProcessing = false;
        });

        if (_ocrResult != null) {
          print(
              "OCR Result: Recipient: ${_ocrResult!['recipient']}, Amount: ${_ocrResult!['amount']}");
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransaction(
                  initialAmount: _ocrResult!['amount'],
                  initialNotes: _ocrResult!['recipient'],
                ),
              ),
            );
          }
        } else {
          print("OCR failed or returned null.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to extract data from slip.')),
            );
          }
        }
      } else {
        print("File picking cancelled.");
      }
    } catch (e) {
      print("Error during file picking or OCR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() {
        _selectedFilePath = null;
        _ocrResult = null;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Upload E-Slip', style: TextStyle(color: _textColor)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Automatic Upload',
                    style: TextStyle(color: _textColor, fontSize: 16),
                  ),
                  Switch(
                    value: isAutomaticUpload,
                    onChanged: (value) {
                      setState(() {
                        isAutomaticUpload = value;
                      });
                    },
                    activeColor: _accentColor,
                    activeTrackColor: _primaryColor,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Upload options tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long, color: _textColor),
                  label:
                      const Text('E-Slip', style: TextStyle(color: _textColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    // We're already on this screen
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.credit_card, color: _textColor),
                  label: const Text(
                    'Credit Card\nStatement',
                    style: TextStyle(color: _textColor),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cardLightDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreditCardStatementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Icon(
              Icons.cloud_upload,
              color: _accentColor,
              size: 80,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isProcessing ? null : _pickAndProcessFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: _textColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SELECT FILE',
                      style: TextStyle(color: _textColor, fontSize: 16),
                    ),
            ),
            if (_selectedFilePath != null) ...[
              const SizedBox(height: 20),
              Text(
                'Selected: ${_selectedFilePath!.split(Platform.pathSeparator).last}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (_ocrResult != null) ...[
              const SizedBox(height: 10),
              Text(
                'Recipient: ${_ocrResult!['recipient'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Amount: ${_ocrResult!['amount'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                print("Manual transaction button pressed");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransaction(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add a transaction manually',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
