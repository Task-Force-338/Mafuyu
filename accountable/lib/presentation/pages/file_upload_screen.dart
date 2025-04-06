import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:accountable/services/ocr_service.dart';
import 'dart:io';

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
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        title: const Text('Upload E-Slip'),
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
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Automatic Upload',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: isAutomaticUpload,
                    onChanged: (value) {
                      setState(() {
                        isAutomaticUpload = value;
                      });
                    },
                    activeColor: Colors.white,
                  )
                ],
              ),
            ),
            const SizedBox(height: 50),
            const Icon(
              Icons.cloud_upload,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isProcessing ? null : _pickAndProcessFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SELECT FILE',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
