import 'package:accountable/backend/app_state.dart';
import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  bool isAutomaticUpload = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
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
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
                );

                if (result != null && result.files.isNotEmpty) {
                  final pickedFile = result.files.first;

                  final receipt = ReceiptFile(
                    name: pickedFile.name,
                    path: pickedFile.path ?? '',
                  );

                  

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Selected file: ${receipt.name}")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No file selected.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'SELECT FILE',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransaction()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add a transaction manually',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
