import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF6A5E7A);
const Color _secondaryColor = Color(0xFF888888);
const Color _accentColor = Color(0xFF9B8EB8);
const Color _textColor = Color(0xFFE0E0E0);
const Color _backgroundDark = Color(0xFF2D2B35);
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
              child: Text(
                '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Monthly Total: $totalExpense',
                      style: const TextStyle(fontSize: 24, color: _textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (allDailyTrans.isEmpty)
                    const Center(
                        child: Text("No transactions for this month.",
                            style: TextStyle(color: Color(0xFFBBBBBB))))
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: const TextStyle(fontSize: 16, color: _textColor),
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 16, color: _textColor),
                  Text(
                    'Expense $totalExpense',
                    style: const TextStyle(fontSize: 14, color: _textColor),
                  ),
                ],
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
        margin: const EdgeInsets.fromLTRB(40, 0, 0, 20),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: _textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, color: _textColor)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 14, color: _textColor)),
                ],
              ),
            ),
            Text(amount,
                style: const TextStyle(fontSize: 16, color: _textColor)),
          ],
        ),
      ),
    );
  }
}
