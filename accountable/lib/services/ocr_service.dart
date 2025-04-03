import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:io'; // Required for File operations if needed, though path is usually sufficient
import 'package:image/image.dart' as img; // Add this for image processing
import 'dart:typed_data'; // Add this for Uint8List

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
          RegExp(r'(\.[^\.]+)$'), // Match file extension
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
    final amountKeywords = RegExp(r'(จำนวนเงิน|จํานวนพิน|จํานวนเงิน|AMOUNT)',
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
    RegExp amountRegex =
        RegExp(r'(\d{1,3}(?:,\d{3})*\.\d{2})\b'); // More specific regex
    if (amountLineIndex != null) {
      // Found line with amount keyword, extract amount from it
      Match? match = amountRegex.firstMatch(lines[amountLineIndex]);
      if (match != null) {
        amount = match.group(1);
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
    if (RegExp(r'shop|branch|สาขา|เดลี่|ท็อปส์|รี้|มณี|โลตัส',
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

  /// Extracts recipient and amount from a banking e-slip image.
  ///
  /// [imagePath] The path to the e-slip image file.
  /// Returns a Map containing the 'recipient' and 'amount'. Returns null values if extraction fails.
  Future<Map<String, String?>> extractSlipData(String imagePath) async {
    String ocrText = await _extractTextFromImage(imagePath);
    if (ocrText.isEmpty) {
      return {'recipient': null, 'amount': null}; // Return nulls if OCR failed
    }
    return _parseSlipData(ocrText);
  }
}
