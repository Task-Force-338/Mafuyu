import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Updated Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF7A6B8D);
const Color _secondaryColor = Color(0xFF9B8EB8);
const Color _accentColor = Color(0xFFAEA0CC);
const Color _textColor = Color(0xFFF0F0F0);
const Color _backgroundDark = Color(0xFF2A2832);
const Color _cardDark = Color(0xFF3A364A);

class HomePage extends StatefulWidget {
  final String detailsPath;

  const HomePage({super.key, required this.detailsPath});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransList>(context, listen: false).getTransactionsFromDB();
    });
  }

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

  String getFormattedDate(DateTime date) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String getMonthName(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  List<DailyTransList> getAllDaysInMonth(AppState appState, DateTime date) {
    final year = date.year;
    final month = date.month;
    final lastDay = DateUtils.getDaysInMonth(year, month);

    List<DailyTransList> allDays = [];

    for (int day = 1; day <= lastDay; day++) {
      final dateForDay = DateTime(year, month, day);
      final dailyList = appState.getDailyTransList(dateForDay);
      if (dailyList.transactions.isNotEmpty) {
        allDays.add(dailyList);
      }
    }

    return allDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: _textColor),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month - 1,
                  );
                });
              },
            ),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.calendar_today,
                        size: 16, color: _textColor),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: _textColor),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<TransList>(
        builder: (context, transList, child) {
          final appState = AppState();
          appState.transList = transList;

          final allDailyTrans = getAllDaysInMonth(appState, selectedDate);
          debugPrint("DailyTransList for month: $allDailyTrans");

          // Monthly total
          final totalExpense = allDailyTrans
              .expand((day) => day.transactions)
              .fold(0.0, (sum, t) => sum + t.amount)
              .toStringAsFixed(2);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Monthly Total',
                          style: TextStyle(
                            fontSize: 16,
                            color: _textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalExpense',
                          style: const TextStyle(
                            fontSize: 28,
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (allDailyTrans.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Color(0xFF9B8EB8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No transactions for this month.",
                            style: TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to Add Transaction screen
                              context.go('/UploadPage');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Add Transaction"),
                          ),
                        ],
                      ),
                    )
                  else
                    ...allDailyTrans.map((dailyList) {
                      final dayTotal = dailyList.transactions
                          .fold(0.0, (sum, t) => sum + t.amount)
                          .toStringAsFixed(2);

                      final expenseWidgets =
                          dailyList.transactions.map((trans) {
                        return _buildExpenseItem(
                          icon: _getIconForType(trans.transType),
                          title: transTypeToString(trans.transType),
                          subtitle: trans.transName,
                          amount: trans.amount.toStringAsFixed(2),
                          context: context,
                          transaction: trans,
                        );
                      }).toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDayExpense(
                          day: getFormattedDate(dailyList.getDate()),
                          totalExpense: dayTotal,
                          expenses: expenseWidgets,
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayExpense({
    required String day,
    required String totalExpense,
    required List<Widget> expenses,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: _textColor),
                    const SizedBox(width: 4),
                    Text(
                      '$totalExpense',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...expenses,
        ],
      ),
    );
  }

  Widget _buildExpenseItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required BuildContext context,
    Trans? transaction,
  }) {
    return GestureDetector(
      onTap: () {
        if (transaction != null) {
          context.go(widget.detailsPath, extra: transaction);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$amount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
