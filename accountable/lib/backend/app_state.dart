import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart'; // PROVIDER REQUIRES MATERIAL???? WHY????
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for the firebase stuff
// import 'firebase_options.dart'; // for the firebase stuff

FirebaseFirestore firebaseDB = FirebaseFirestore.instance;

// stolen from Mafuyu. Shut up.
// half the codebase is shared between Kanade and Mafuyu anyways.
// If there's an another version, it's gonna be called Ena or Mizuki or something.
class LocalDB {
  // if you touch this make sure to label the commit with BREAKING CHANGE
  static final LocalDB _instance = LocalDB._internal(); // this shi a singleton
  factory LocalDB() => _instance;
  LocalDB._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await init();
    return _db!;
  }

  Future<Database> init() async {
    // init database
    return await openDatabase(
      'transTable.db',
      version: 1,
      onCreate: (Database db, int version) async {
        //if the database doesn't exist, create it
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY,
            transName TEXT,
            transactionDate TEXT,
            transType TEXT,
            amount REAL
          )
        ''');
      },
    );
  }

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await this.db;
    await db.insert('transactions', transaction);
  }

  Future<void> updateTransaction(Map<String, dynamic> oldTransaction,
      Map<String, dynamic> newTransaction) async {
    final db = await this.db;

    // Find the transaction to update by matching transaction date, name and amount
    List<Map<String, dynamic>> matches = await db.query(
      'transactions',
      where: 'transName = ? AND transactionDate = ? AND amount = ?',
      whereArgs: [
        oldTransaction['transName'],
        oldTransaction['transactionDate'],
        oldTransaction['amount']
      ],
    );

    if (matches.isNotEmpty) {
      // Update the found transaction with new data
      await db.update(
        'transactions',
        newTransaction,
        where: 'id = ?',
        whereArgs: [matches.first['id']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await this.db;
    return await db.query('transactions');
  }

  Future<void> deleteTransactions() async {
    final db = await this.db;
    await db.delete('transactions');
  }

  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    final db = await this.db;
    await db.delete(
      'transactions',
      where: 'transName = ? AND transactionDate = ? AND amount = ?',
      whereArgs: [
        transaction['transName'],
        transaction['transactionDate'],
        transaction['amount']
      ],
    );
  }
}

// so that 29,110.00 can be converted to 29110.00. EVERYONE hates it when they see a comma in a number.
double commaToDouble(String input) {
  return double.parse(input.replaceAll(',', ''));
}

enum TransactionType {
  food,
  personal,
  utility,
  transportation,
  health,
  leisure,
  other
}

String transTypeToString(TransactionType type) {
  // FOR USE IN THE UI. WE'RE NOT THAT HIPSTER TO USE ALL LOWERCASE
  switch (type) {
    case TransactionType.food:
      return 'Food';
    case TransactionType.personal:
      return 'Personal';
    case TransactionType.utility:
      return 'Utility';
    case TransactionType.transportation:
      return 'Transportation';
    case TransactionType.health:
      return 'Health';
    case TransactionType.leisure:
      return 'Leisure';
    case TransactionType.other:
      return 'Other';
  }
}

TransactionType stringToTransType(String type) {
  // theoretically type can be null, in which it will return other
  switch (type) {
    case 'food':
      return TransactionType.food;
    case 'personal':
      return TransactionType.personal;
    case 'utility':
      return TransactionType.utility;
    case 'transportation':
      return TransactionType.transportation;
    case 'health':
      return TransactionType.health;
    case 'leisure':
      return TransactionType.leisure;
    case 'other':
      return TransactionType.other;
    default:
      return TransactionType.other;
  }
}

class TransList extends ChangeNotifier {
  // holds the current session's transactions. so that sqlite doesn't get called every time we need to access the transactions
  // we still have to call sqlite when we need to save the transactions, though
  // thats why this CANNOT send the transactions to the remote database. it's just a temporary storage.
  static final TransList _instance = TransList._internal();
  factory TransList() => _instance;
  TransList._internal();

  final List<Trans> transactions = [];

  @override
  String toString() {
    return 'TransList{transactions: $transactions}';
  }

  void addTransaction(Trans transaction) {
    transactions.add(transaction);
    notifyListeners();
  }

  void removeTransaction(Trans transaction) {
    transactions.remove(transaction);
    notifyListeners();
  }

  Map<TransactionType, double> generateInsights() {
    Map<TransactionType, double> insights = {
      TransactionType.food: 0,
      TransactionType.personal: 0,
      TransactionType.utility: 0,
      TransactionType.transportation: 0,
      TransactionType.health: 0,
      TransactionType.leisure: 0,
      TransactionType.other: 0,
    };

    for (Trans trans in transactions) {
      if (trans.transType != null) {
        insights[trans.transType] = insights[trans.transType]! + trans.amount;
      }
    }
    return insights;
  }

  void scorchedEarth() {
    // deletes all transactions. maybe to fetch them again?
    transactions.clear();
    notifyListeners();
  }

  void getTransactionsFromDB() async {
    // get the transactions from the local database
    final db = LocalDB();
    List<Map<String, dynamic>> dbTransactions = await db.getTransactions();

    transactions
        .clear(); // Clear before loading to avoid duplicates if called multiple times
    for (Map<String, dynamic> dbTrans in dbTransactions) {
      transactions.add(Trans.withType(
        transName: dbTrans['transName'],
        transactionDate: DateTime.parse(
            dbTrans['transactionDate']), // PLEASE SAVE IT AS ISO 8601
        amount: dbTrans['amount'],
        transType:
            stringToTransType(dbTrans['transType'].toString().toLowerCase()),
      ));
    }
    notifyListeners();
  }
}

class DailyTransList {
  // represents each day's transactions
  final List<Trans> transactions = [];

  // please use this method to instantiate a DailyTransList object
  static DailyTransList getThisDayList(DateTime date) {
    // nifty function to get the transactions of a specific day
    // if the list doesn't exist, create it
    // if it does, return it

    DailyTransList dailyTransList = DailyTransList();

    TransList transList = TransList(); // get the current session's transactions
    for (Trans trans in transList.transactions) {
      if (trans.transactionDate.year == date.year &&
          trans.transactionDate.month == date.month &&
          trans.transactionDate.day == date.day) {
        dailyTransList.addTransaction(trans);
      }
    }

    return dailyTransList;
  }

  @override
  String toString() {
    return 'DailyTransList{transactions: $transactions}';
  }

  DateTime getDate() {
    // get the date of the transactions. UI guys, u know what 2 do
    return transactions[0].transactionDate;
  }

  void addTransaction(Trans transaction) {
    transactions.add(transaction);
  }
}

class Trans {
  final String transName;
  final DateTime transactionDate;
  final double amount;
  TransactionType transType = TransactionType.other;

  Trans({
    required this.transName,
    required this.transactionDate,
    required this.amount,
    required this.transType,
  });

  Trans.withType({
    // This constructor might become less relevant if generateCategory is always called
    required this.transName,
    required this.transactionDate,
    required this.amount,
    required this.transType,
  });

  // Add a constructor that calls generateCategory automatically? Or rely on caller.
  // Let's rely on the caller for now to call generateCategory explicitly.

  @override
  String toString() {
    // this is stupid. who would want to print a transaction object, let alone log it?
    return 'Transaction{transName: $transName, transactionDate: $transactionDate, amount: $amount, transType: $transType}';
  }

  Future<void> generateCategory() async {
    // Try to find a matching vendor and set the most likely category
    debugPrint("[generateCategory] Starting for '$transName'");
    try {
      final querySnapshot = await firebaseDB.collection("vendors").get();
      debugPrint(
          "[generateCategory] Fetched ${querySnapshot.docs.length} vendors.");
      String? bestVendorName;
      Map<String, dynamic>? vendorData;

      // Find the vendor whose name is contained in the transaction name
      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final vendorName = docData["name"] as String?;
        if (vendorName != null &&
            transName.toLowerCase().contains(vendorName.toLowerCase())) {
          bestVendorName = vendorName;
          vendorData = docData;
          debugPrint(
              "[generateCategory] Found matching vendor '$vendorName' for '$transName'");
          break; // Found a match, stop searching
        }
      }

      if (vendorData != null && vendorData.containsKey("votes")) {
        final votesDynamic = vendorData["votes"] as Map<String, dynamic>? ?? {};
        final Map<String, int> categories = votesDynamic
            .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
        debugPrint("[generateCategory] Vendor votes: $categories");

        if (categories.isNotEmpty) {
          final sortedCategories = categories.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

          final winningCategory = sortedCategories.first.key.toLowerCase();
          transType = stringToTransType(winningCategory);
          debugPrint(
              "[generateCategory] Generated category for '$transName': ${transTypeToString(transType)} (from $winningCategory)");
          return;
        }
      } else {
        debugPrint(
            "[generateCategory] No matching vendor found or vendor has no 'votes' field for '$transName'.");
      }
      // If no vendor match or no votes, keep default or current type (often 'other')
      debugPrint(
          "[generateCategory] Could not generate category for '$transName', defaulting to ${transTypeToString(transType)}");
    } catch (e, s) {
      debugPrint(
          "[generateCategory] Error generating category for '$transName': $e\nStack trace: $s");
      // Keep default type on error
    }
  }

  Future<void> voteCategory() async {
    final categoryToVote = transTypeToString(transType).toLowerCase();
    debugPrint(
        "[voteCategory] Starting for '$transName' with category '$categoryToVote'");

    if (categoryToVote == 'other') {
      debugPrint(
          "[voteCategory] Skipping vote for 'other' category for '$transName'");
      return;
    }

    try {
      final querySnapshot = await firebaseDB.collection("vendors").get();
      debugPrint(
          "[voteCategory] Fetched ${querySnapshot.docs.length} vendors.");
      DocumentReference? vendorDocRef;
      Map<String, dynamic>? vendorData;
      String? foundVendorName;

      // Find the matching vendor document
      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final vendorName = docData["name"] as String?;
        if (vendorName != null &&
            transName.toLowerCase().contains(vendorName.toLowerCase())) {
          vendorDocRef = doc.reference;
          vendorData = docData;
          foundVendorName = vendorName;
          debugPrint(
              "[voteCategory] Found matching vendor '$vendorName' (Doc ID: ${doc.id}) for '$transName'");
          break;
        }
      }

      if (vendorDocRef != null && vendorData != null) {
        final votesDynamic = vendorData["votes"] as Map<String, dynamic>? ?? {};
        final Map<String, int> categories = votesDynamic
            .map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
        debugPrint("[voteCategory] Existing votes: $categories");

        // Increment the vote count for the transaction's category
        categories.update(categoryToVote, (value) => value + 1,
            ifAbsent: () => 1);
        debugPrint("[voteCategory] Updated votes: $categories");

        // Update Firestore
        await vendorDocRef.update({'votes': categories});
        debugPrint(
            "[voteCategory] Successfully voted for category '$categoryToVote' for vendor '$foundVendorName'");
      } else {
        debugPrint(
            "[voteCategory] Vendor not found for '$transName'. Creating new vendor and voting for category '$categoryToVote'.");
        final initialVotes = {
          'food': 0,
          'personal': 0,
          'utility': 0,
          'transportation': 0,
          'health': 0,
          'leisure': 0,
          'other': 0,
        };
        initialVotes[categoryToVote] = 1;
        debugPrint(
            "[voteCategory] Initial votes for new vendor: $initialVotes");

        await firebaseDB.collection("vendors").add({
          'name': transName,
          'votes': initialVotes,
        });
        debugPrint(
            "[voteCategory] Successfully created new vendor '$transName' with initial vote for '$categoryToVote'");
      }
    } catch (e, s) {
      debugPrint(
          "[voteCategory] Error voting for category '$categoryToVote' for '$transName': $e\nStack trace: $s");
    }
  }

  void saveToDB() async {
    // save the transaction to the local database
    final value = transTypeToString(transType).toLowerCase();
    debugPrint("transType: $value");
    final db = LocalDB();
    await db.insertTransaction({
      'transName': transName,
      'transactionDate': transactionDate.toIso8601String(), // HELL YEAH
      'amount':
          amount, // hopefully it saves as number. if breaks, make it so that it saves as REAL
      'transType': value,
    });
  }

  void updateInDB(Trans oldTransaction) async {
    // update the transaction in the local database
    final newValue = transTypeToString(transType).toLowerCase();
    final oldValue = transTypeToString(oldTransaction.transType).toLowerCase();

    debugPrint("Updating transaction from: $oldTransaction to: $this");

    final db = LocalDB();
    await db.updateTransaction(
        // Old transaction data
        {
          'transName': oldTransaction.transName,
          'transactionDate': oldTransaction.transactionDate.toIso8601String(),
          'amount': oldTransaction.amount,
          'transType': oldValue,
        },
        // New transaction data
        {
          'transName': transName,
          'transactionDate': transactionDate.toIso8601String(),
          'amount': amount,
          'transType': newValue,
        });
  }

  void deleteFromDB() async {
    // delete the transaction from the local database
    final value = transTypeToString(transType).toLowerCase();
    debugPrint("Deleting transaction: $this");

    final db = LocalDB();
    await db.deleteTransaction({
      'transName': transName,
      'transactionDate': transactionDate.toIso8601String(),
      'amount': amount,
      'transType': value,
    });
  }
}

class AppState extends ChangeNotifier {
  bool isAutomaticUpload = false;
  bool isDarkMode = false;
  LocalDB db = LocalDB(); // shove all of the database stuff here
  TransList transList = TransList();
  List<DailyTransList> dailyTransLists = [];
  List<ReceiptFile> receipts = [];

  void toggleAutomaticUpload() {
    isAutomaticUpload = !isAutomaticUpload;
    notifyListeners();
  }

  void readReceipt(ReceiptFile receipt) {
    // read the receipt and add the transactions to the transList
    receipt.OCRBS();
    notifyListeners();
  }

  void getInsights() {
    transList.generateInsights();
    notifyListeners();
  }

  DailyTransList getDailyTransList(DateTime date) {
    return DailyTransList.getThisDayList(
        date); // there it is, the object. have fun mapping it to the UI
  }

  // if you do UI and wanna use this, use the methods, then call notifyListeners(). -the backend guy
  // welcome back, observer pattern. we missed you.
}

class ReceiptFile {
  final String name;
  final String path;

  ReceiptFile({required this.name, required this.path})
      : assert(name != null),
        assert(path != null);

  @override
  String toString() {
    return 'ReceiptFile{name: $name, path: $path}';
  }

  void OCRBS() {
    //TODO: make it so that it actually reads the receipt
    // return whatever it reads. maybe a singel transaction object?
  }
}
