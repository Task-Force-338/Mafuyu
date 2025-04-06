import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io'; // Required for File operations if needed, though path is usually sufficient
import 'package:image/image.dart' as img; // Add this for image processing
import 'dart:typed_data'; // Add this for Uint8List
import 'dart:math'; // Import for min, max functions
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OcrService {
  /// Extracts text from an image file using Tesseract OCR.
  ///
  /// [imagePath] The path to the image file.
  /// Returns the extracted text as a single string.
  Future<String> _extractTextFromImage(String imagePath) async {
    try {
      // Apply preprocessing filters for better OCR results
      String processedImagePath = await _preprocessImage(imagePath);

      // Use the processed image for OCR
      String text = await FlutterTesseractOcr.extractText(
        processedImagePath,
        language: 'tha+eng', // Combine Thai and English languages
        args: {
          "psm": "6", // Assuming a single uniform block of text
          "preserve_interword_spaces": "1", // Preserve word spacing
          // Additional config can be added here
        },
      );

      // Clean up temporary processed image
      if (processedImagePath != imagePath) {
        try {
          File(processedImagePath).deleteSync();
        } catch (e) {
          print("Warning: Failed to delete temp image: $e");
        }
      }

      return text;
    } catch (e) {
      print("Error during Tesseract OCR: $e");
      // Consider more robust error handling/logging
      return "";
    }
  }

  /// Extracts text from a PDF file using flutter_pdf_text.
  ///
  /// [pdfPath] The path to the PDF file.
  /// Returns the extracted text as a single string.
  Future<String> _extractTextFromPdf(String pdfPath, {String? password}) async {
    try {
      // Load the PDF document using flutter_pdf_text
      PDFDoc? doc;

      try {
        if (password != null && password.isNotEmpty) {
          doc = await PDFDoc.fromPath(pdfPath, password: password);
        } else {
          doc = await PDFDoc.fromPath(pdfPath);
        }
      } catch (e) {
        if (e.toString().contains('password') ||
            e.toString().contains('encrypted')) {
          // Document is encrypted but no password was provided
          print("PDF requires a password but none was provided");
          return "PASSWORD_REQUIRED";
        } else {
          rethrow; // Other errors should be handled by the outer catch block
        }
      }

      // Extract text from all pages
      String text = await doc.text;

      return text;
    } catch (e) {
      print("Error during PDF text extraction: $e");
      // Consider more robust error handling/logging

      // Fallback to Syncfusion if flutter_pdf_text fails
      return _extractTextFromPdfUsingSyncfusion(pdfPath, password: password);
    }
  }

  /// Fallback method using Syncfusion if flutter_pdf_text fails
  Future<String> _extractTextFromPdfUsingSyncfusion(String pdfPath,
      {String? password}) async {
    try {
      // Load the PDF document
      File file = File(pdfPath);
      List<int> bytes = await file.readAsBytes();

      PdfDocument document;
      try {
        // Try to open the document with password if provided
        if (password != null && password.isNotEmpty) {
          document = PdfDocument(inputBytes: bytes, password: password);
        } else {
          document = PdfDocument(inputBytes: bytes);
        }
      } catch (e) {
        if (e.toString().contains('password')) {
          // Document is encrypted but no password was provided
          print("PDF requires a password but none was provided (Syncfusion)");
          return "PASSWORD_REQUIRED";
        } else {
          rethrow; // Other errors should be handled by the outer catch block
        }
      }

      // Extract text from all pages
      String text = '';
      PdfTextExtractor extractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        text += extractor.extractText(startPageIndex: i) + '\n';
      }

      // Dispose the document
      document.dispose();

      return text;
    } catch (e) {
      print("Error during PDF text extraction using Syncfusion: $e");
      return "";
    }
  }

  /// Preprocesses the image to improve OCR accuracy
  ///
  /// [imagePath] The path to the original image
  /// Returns the path to the processed image (may be the same if processing fails)
  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Read the image file
      List<int> bytes = File(imagePath).readAsBytesSync();
      Uint8List imageBytes = Uint8List.fromList(bytes);
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print("Warning: Failed to decode image for preprocessing");
        return imagePath;
      }

      // --- Enhanced Preprocessing Steps ---

      // 1. Convert to grayscale
      img.Image grayscale = img.grayscale(image);

      // 2. Adjust Contrast
      // Increasing contrast can help separate text from background elements.
      // The value (e.g., 1.5) can be tuned based on testing.
      // Values > 1 increase contrast, < 1 decrease it.
      img.Image processed = img.adjustColor(grayscale, contrast: 1.5);

      // Optional: Invert if text becomes light on dark background
      // Tesseract often prefers dark text on a light background.
      // Test if inversion improves results for your slips
      // processed = img.invert(processed);

      // --- Save the processed image ---
      String tempPath = imagePath.replaceAll(
          RegExp(
              r'(\.([^.]+)$'), // Match file extension (fixed for Windows paths)
          '_processed\$1');

      // Save as PNG for potentially better quality after thresholding (lossless)
      File(tempPath).writeAsBytesSync(img.encodePng(processed));

      print("Image preprocessed with adaptive thresholding: $tempPath");
      return tempPath;
    } catch (e) {
      print("Error during image preprocessing: $e");
      return imagePath; // Return original if preprocessing fails
    }
  }

  /// Processes the OCR text to find the recipient and amount.
  /// This is where the core logic for parsing the slip text will go.
  ///
  /// [ocrText] The raw text extracted by Tesseract.
  /// Returns a Map containing the 'recipient' and 'amount'.
  Map<String, String?> _parseSlipData(String ocrText) {
    String? recipient;
    String? amount;
    // Normalize potential OCR errors for keywords
    String normalizedOcrText = ocrText
        .replaceAll(' ไปยัง ', 'ไปยัง') // Handle spaces around keywords
        .replaceAll(' ไป ', 'ไป');

    List<String> lines = normalizedOcrText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    int? recipientLineIndex;
    int? amountLineIndex;

    // --- Pass 1: Find potential lines using keywords ---
    final recipientKeywords =
        RegExp(r'(ไปยัง|ไป|ถึง|TO)', caseSensitive: false);
    final amountKeywords = RegExp(
        r'(จำนวนเงิน|จํานวนพิน|จํานวนเงิน|จํานวน|AMOUNT)',
        caseSensitive: false);

    bool recipientFound = false; // Flag to stop searching once found

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // --- Check for Recipient ---
      if (!recipientFound &&
          recipientLineIndex == null &&
          recipientKeywords.hasMatch(line)) {
        // Try to extract recipient from the SAME line first
        List<String> parts = line
            .split(RegExp(r'(ไปยัง|ไป|ถึง|TO)\s*|@|~', caseSensitive: false));
        if (parts.length > 1 &&
            parts[1].trim().isNotEmpty &&
            _isPlausibleName(parts[1].trim())) {
          recipient = parts[1].trim();
          recipientLineIndex = i; // Mark the line index where it was found
          recipientFound = true; // Stop searching for recipient keywords
        } else {
          // If not found on the same line, mark the NEXT line index for checking in Pass 2
          if (i + 1 < lines.length) {
            recipientLineIndex = i + 1;
          }
          // We don't set recipientFound = true here, as we haven't confirmed the name yet
        }
      }

      // --- Check for Amount ---
      if (amountLineIndex == null && amountKeywords.hasMatch(line)) {
        amountLineIndex = i;
        // We could potentially stop searching for amount too if needed, but let's keep it simple
      }

      // Optimization: If both are potentially located, we could break the loop
      // if (recipientLineIndex != null && amountLineIndex != null) break;
    }

    // --- Pass 2: Extract data from identified lines or use fallback ---

    // Extract Recipient ONLY if not already found in Pass 1
    if (!recipientFound && recipientLineIndex != null) {
      // Ensure we didn't find it on the same line already
      String potentialRecipientLine = lines[recipientLineIndex].trim();

      // Check if the line contains name separators like @ or ~
      List<String> parts = potentialRecipientLine.split(RegExp(r'@|~'));
      if (parts.length > 1 &&
          parts[1].trim().isNotEmpty &&
          _isPlausibleName(parts[1].trim())) {
        recipient = parts[1].trim();
      }
      // Otherwise check if the whole line looks like a name
      else if (_isPlausibleName(potentialRecipientLine)) {
        recipient = potentialRecipientLine;
      }

      // Check following lines for additional recipient info (like shop name/branch)
      if (recipient != null && recipientLineIndex + 1 < lines.length) {
        String nextLine = lines[recipientLineIndex + 1].trim();
        // If the next line also looks like part of the name and doesn't start with ID-like terms
        if (_isPlausibleName(nextLine) &&
            !nextLine.startsWith(
                RegExp(r'(Biller|ID|รหัส)', caseSensitive: false))) {
          // Don't add parentheses - many shop names already have specific formatting
          recipient += " " + nextLine;
        }
      }
    }

    // Fallback for recipient if not found through keywords
    if (recipient == null) {
      // Look for patterns that might indicate recipient (like "SCB มณี SHOP" or shop names)
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();

        // Check for lines that have shop-like patterns
        if ((line.contains('SHOP') ||
                line.contains('Shop') ||
                line.contains('ร้าน') ||
                line.contains('CAFE') ||
                line.contains('QSNCC') ||
                line.contains('นิธิธนันท์กร') ||
                line.contains('บมจ.') ||
                line.contains('มณี') ||
                line.contains('SCB') ||
                line.contains('KBank')) &&
            _isPlausibleName(line)) {
          recipient = line;
          break;
        }
      }
    }

    // Extract Amount
    RegExp amountRegex = RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})'); // Fixed regex
    RegExp amountRegex2 = RegExp(r'(\d+\.\d{2})\s*บาท'); // Thai receipt format

    if (amountLineIndex != null) {
      // Found line with amount keyword, extract amount from it
      Match? match = amountRegex.firstMatch(lines[amountLineIndex]);
      if (match != null) {
        amount = match.group(1);
      } else {
        match = amountRegex2.firstMatch(lines[amountLineIndex]);
        if (match != null) {
          amount = match.group(1);
        }
      }
    } else {
      // Fallback: Search all lines for the amount pattern if keyword wasn't found
      for (String line in lines) {
        // Avoid lines with fees if possible
        if (line.contains('ค่าธรรมเนียม') || line.contains('FEE')) continue;

        Match? match = amountRegex.firstMatch(line);
        if (match != null) {
          // Take the first plausible amount found if no keyword line exists
          amount = match.group(1);
          break; // Stop after finding the first potential amount
        }

        match = amountRegex2.firstMatch(line);
        if (match != null) {
          amount = match.group(1);
          break;
        }
      }
    }

    // --- Clean up ---
    if (recipient != null) {
      // Remove only standalone account-like patterns
      recipient = recipient
          .replaceAll(
              RegExp(r'\b(xxx-xxx\d{3,}(-\d+)?|xxx-x-x\d{4}-x)\b',
                  caseSensitive: false),
              '')
          .trim();

      // Remove unwanted leading/trailing symbols (more compatible regex)
      // Removes leading chars that are not word chars, @, or ~
      // Removes trailing chars that are not word chars
      recipient = recipient.replaceAll(RegExp(r'^[^\w@~]+|[^\w]+$'), '').trim();

      // Replace multiple spaces with a single space
      recipient = recipient.replaceAll(RegExp(r'\s+'), ' ');
    }

    print("--- OCR Text ---");
    print(ocrText); // Keep raw OCR for debugging
    print("--- Extracted ---");
    print("Recipient: $recipient");
    print("Amount: $amount");
    print("-----------------");

    return {
      'recipient': recipient,
      'amount': amount,
    };
  }

  /// Helper function to check if a line is likely a name
  bool _isPlausibleName(String line) {
    if (line.isEmpty) return false;

    // Reject lines that are just IDs or numeric content
    if (RegExp(r'^[\d\s-]+$').hasMatch(line))
      return false; // Pure digits/spaces/hyphens

    // Allow lines with shop-specific patterns even if they contain digits
    // Pattern like "Shop Name 1234" or "Branch-XYZ" should be valid
    if (RegExp(
            r'shop|branch|cafe|qsncc|สาขา|เดลี่|ท็อปส์|รี้|มณี|โลตัส|นิธิธนันท์กร|บมจ',
            caseSensitive: false)
        .hasMatch(line)) {
      return true;
    }

    // Check if it contains at least one Thai character or letter
    bool hasThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(line);
    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(line);

    if (!hasThai && !hasLetter) return false;

    // Check for specific patterns that definitely aren't names
    if (RegExp(r'^(Biller ID|ID|Account|รหัส|เลขที่)').hasMatch(line))
      return false;

    // Check if it's a masked account number (e.g., xxx-xxx123-4)
    if (RegExp(r'^x{3}-x{3}\d{3}-\d$').hasMatch(line)) return false;

    return true; // Seems plausible
  }

  /// Extracts recipient and amount from a banking e-slip (image or PDF).
  ///
  /// [filePath] The path to the e-slip image or PDF file.
  /// Returns a Map containing the 'recipient' and 'amount'. Returns null values if extraction fails.
  Future<Map<String, String?>> extractSlipData(String filePath,
      {String? password}) async {
    String ocrText = "";
    if (filePath.toLowerCase().endsWith('.pdf')) {
      ocrText = await _extractTextFromPdf(filePath, password: password);

      // Check if password is required
      if (ocrText == "PASSWORD_REQUIRED") {
        return {'password_required': 'true'};
      }
    } else {
      // Assuming image otherwise, could add more robust type checking
      ocrText = await _extractTextFromImage(filePath);
    }

    if (ocrText.isEmpty) {
      return {
        'recipient': null,
        'amount': null
      }; // Return nulls if extraction failed
    }
    return _parseSlipData(ocrText);
  }

  /// Parse the text from a credit card statement to extract transactions
  List<Map<String, String?>> _parseStatementTransactions(String statementText) {
    List<Map<String, String?>> transactions = [];

    // Try the regex pattern from the test app first - this works better for most credit card statements
    RegExp transactionRegex = RegExp(
        r"(\d{2}/\d{2}/\d{2})\s+" // Transaction Date
        r"(\d{2}/\d{2}/\d{2})\s+" // Posting Date
        r"([A-Za-z0-9\s\(\)\\.,&/-]+?)\s+" // Description with allowed characters
        r"([\d,]+\.\d{2})[\s\n]*" // Amount (handling commas and periods)
        );

    // Find all matches
    Iterable<RegExpMatch> matches = transactionRegex.allMatches(statementText);

    print("Found ${matches.length} matches with primary pattern");

    // If we found transactions with the primary pattern
    if (matches.isNotEmpty) {
      for (RegExpMatch match in matches) {
        String description = match.group(3) ?? '';
        String amount = match.group(4) ?? '';

        // Remove commas from amount and convert to double
        double amountValue = _commaToDouble(amount);

        transactions.add({
          'date': match.group(1),
          'posting_date': match.group(2),
          'description': _cleanupDescription(description),
          'amount': amount,
          'amount_value': amountValue.toString(),
        });
      }
      return transactions;
    }

    // Try Thai-specific formats (common in KBank, SCB, etc.)
    RegExp thaiRegex = RegExp(
        r"(\d{2}/\d{2}/\d{2})\s+" // Date in DD/MM/YY format
        r"([ก-๙A-Za-z0-9\s\(\)\\.,&/-]+?)\s+" // Thai and English description
        r"([\d,]+\.\d{2})" // Amount
        );

    matches = thaiRegex.allMatches(statementText);
    print("Found ${matches.length} matches with Thai pattern");

    if (matches.isNotEmpty) {
      for (RegExpMatch match in matches) {
        String amount = match.group(3) ?? '';
        double amountValue = _commaToDouble(amount);

        transactions.add({
          'date': match.group(1),
          'description': _cleanupDescription(match.group(2) ?? ''),
          'amount': amount,
          'amount_value': amountValue.toString(),
        });
      }
      return transactions;
    }

    // Fallback to more generic patterns
    return _fallbackTransactionExtraction(statementText);
  }

  /// Convert comma-formatted number to double
  double _commaToDouble(String amountStr) {
    try {
      // Remove commas from the string
      String cleanAmount = amountStr.replaceAll(',', '');
      // Parse the resulting string to a double
      return double.parse(cleanAmount);
    } catch (e) {
      print("Error converting amount to double: $e");
      return 0.0;
    }
  }

  /// Additional pattern matching for Thai bank statements
  List<Map<String, String?>> _extractThaiStatementPatterns(String text) {
    List<Map<String, String?>> results = [];

    // KBank Pattern - Thai language pattern common in Kasikorn statements
    // วันที่ DD/MM/YY รายการ Description จำนวนเงิน Amount บาท
    final kbankRegex =
        RegExp(r"วันที่\s+(\d{2}/\d{2}/\d{2})" // Date after "วันที่"
            r"(?:\s+รายการ\s+)?" // Optional "รายการ" label
            r"(.+?)" // Description (non-greedy)
            r"(?:จำนวนเงิน|จํานวนเงิน)?\s*" // Optional "จำนวนเงิน" label
            r"([\d,]+\.\d{2})\s*บาท" // Amount followed by "บาท"
            );

    // Find all KBank pattern matches
    Iterable<RegExpMatch> kbankMatches = kbankRegex.allMatches(text);
    for (RegExpMatch match in kbankMatches) {
      results.add({
        'date': match.group(1),
        'description': _cleanupDescription(match.group(2) ?? ''),
        'amount': match.group(3),
      });
    }

    return results;
  }

  /// Fallback method for transaction extraction using more generic patterns
  List<Map<String, String?>> _fallbackTransactionExtraction(
      String statementText) {
    List<Map<String, String?>> transactions = [];
    List<String> lines = statementText.split('\n');

    // Patterns to identify transactions in credit card statements
    final datePattern = RegExp(
        r'(\d{2}/\d{2}/\d{2,4}|\d{2}\s+[A-Za-z]{3}\s+\d{2,4})'); // Matches dates like DD/MM/YYYY or DD MMM YYYY
    final amountPattern =
        RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})'); // Matches amounts like 1,234.56

    // Common patterns that indicate transaction sections in statements
    final transactionSectionPattern = RegExp(
        r'(transactions|รายการ|activity|purchases|charges|TRANSACTION DETAIL)',
        caseSensitive: false);

    bool inTransactionSection = false;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) continue;

      // Check if we've entered a transaction section
      if (transactionSectionPattern.hasMatch(line)) {
        inTransactionSection = true;
        continue;
      }

      // Skip lines until we find the transaction section
      if (!inTransactionSection) continue;

      // Check if the line contains a date and an amount - likely a transaction
      if (datePattern.hasMatch(line) && amountPattern.hasMatch(line)) {
        // Extract the date
        final dateMatch = datePattern.firstMatch(line)!;
        String date = dateMatch.group(1)!;

        // Extract the amount
        final amountMatch = amountPattern.firstMatch(line)!;
        String amount = amountMatch.group(1)!;

        // Extract the description (everything between date and amount)
        int descStart =
            line.indexOf(dateMatch.group(0)!) + dateMatch.group(0)!.length;
        int descEnd = line.lastIndexOf(amountMatch.group(0)!);

        String description = "";
        if (descEnd > descStart) {
          description = line.substring(descStart, descEnd).trim();
        } else {
          // If we can't extract description from the same line, check next line
          if (i + 1 < lines.length && !datePattern.hasMatch(lines[i + 1])) {
            description = lines[i + 1].trim();
            i++; // Skip the next line as we've already processed it
          }
        }

        // Clean up the description
        description = _cleanupDescription(description);

        transactions
            .add({'date': date, 'description': description, 'amount': amount});
      } else if (datePattern.hasMatch(line)) {
        // Case where date is on one line but description and amount are on next line
        final dateMatch = datePattern.firstMatch(line)!;
        String date = dateMatch.group(1)!;

        // Check next line for description and amount
        if (i + 1 < lines.length) {
          String nextLine = lines[i + 1].trim();
          final amountMatch = amountPattern.firstMatch(nextLine);

          if (amountMatch != null) {
            String amount = amountMatch.group(1)!;

            // Extract description
            String description = nextLine
                .substring(0, nextLine.lastIndexOf(amountMatch.group(0)!))
                .trim();
            description = _cleanupDescription(description);

            transactions.add(
                {'date': date, 'description': description, 'amount': amount});

            i++; // Skip the next line
          }
        }
      }
    }

    return transactions;
  }

  /// Clean up transaction descriptions
  String _cleanupDescription(String description) {
    // Remove excess whitespace
    description = description.replaceAll(RegExp(r'\s+'), ' ');

    // Remove common prefixes/suffixes in credit card statements
    final prefixesToRemove = [
      'Purchase ',
      'Payment to ',
      'Charge at ',
      'PURCHASE ',
      'POS PURCHASE '
    ];

    for (String prefix in prefixesToRemove) {
      if (description.startsWith(prefix)) {
        description = description.substring(prefix.length);
      }
    }

    return description.trim();
  }

  /// Extracts multiple transactions from a credit card statement PDF
  Future<List<Map<String, String?>>> extractCreditCardStatementData(
      String filePath,
      {String? password}) async {
    String pdfText = "";
    List<Map<String, String?>> transactions = [];

    // Extract text from PDF
    if (filePath.toLowerCase().endsWith('.pdf')) {
      pdfText = await _extractTextFromPdf(filePath, password: password);

      // Check if password is required
      if (pdfText == "PASSWORD_REQUIRED") {
        return [
          {'password_required': 'true'}
        ];
      }

      print(
          "PDF Text Extracted: ${pdfText.substring(0, min(500, pdfText.length))}...");

      // Parse the extracted text for transactions
      transactions = _parseStatementTransactions(pdfText);

      // If no transactions found with primary patterns, try Thai-specific patterns
      if (transactions.isEmpty) {
        print(
            "No transactions found with primary patterns. Trying Thai patterns...");
        transactions = _extractThaiStatementPatterns(pdfText);
      }

      // Log the transactions found
      if (transactions.isNotEmpty) {
        print("Found ${transactions.length} transactions");
        print("First transaction: ${transactions.first}");
      } else {
        print("No transactions found in the PDF");
      }
    } else {
      print("Not a PDF file: $filePath");
      return [];
    }

    return transactions;
  }
}
