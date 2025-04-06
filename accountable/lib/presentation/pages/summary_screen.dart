import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:provider/provider.dart';
import '../../backend/app_state.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

// Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF6A5E7A);
const Color _secondaryColor = Color(0xFF888888);
const Color _accentColor = Color(0xFF9B8EB8);
const Color _textColor = Color(0xFFE0E0E0);
const Color _backgroundDark = Color(0xFF2D2B35);
const Color _cardDark = Color(0xFF3A364A);

// Custom chart colors in Mafuyu theme
final List<Color> _chartColors = [
  Color(0xFF6A5E7A), // Primary
  Color(0xFF888888), // Secondary
  Color(0xFF9B8EB8), // Accent
  Color(0xFF59546D), // Darker Primary
  Color(0xFF7A8CA3), // Desaturated Light Blue
  Color(0xFF807794), // Lighter Primary
  Color(0xFFAA9FC0), // Lighter Accent
  Color(0xFF6D7A8C), // Desaturated Medium Blue
  Color(0xFF9188A3), // Medium Lavender
  Color(0xFF584F6D), // Deepest Indigo
];

// Helper function to get icon based on transaction type
IconData _getIconForTransactionType(TransactionType type) {
  switch (type) {
    case TransactionType.food:
      return Icons.restaurant;
    case TransactionType.personal:
      return Icons.person;
    case TransactionType.utility:
      return Icons.lightbulb_outline;
    case TransactionType.transportation:
      return Icons.directions_car;
    case TransactionType.health:
      return Icons.healing;
    case TransactionType.leisure:
      return Icons.sports_esports; // Or other relevant icon. idk im not a cop.
    case TransactionType.other:
      return Icons.category;
    default:
      return Icons.category; // Default fallback
  }
}

class BudgetSummaryScreen extends StatelessWidget {
  const BudgetSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transList = Provider.of<TransList>(context);
    final insights = transList.generateInsights();

    final chartData = insights.entries.map((entry) {
      return {'category': transTypeToString(entry.key), 'amount': entry.value};
    }).toList();

    final insightListTiles =
        insights.entries.where((entry) => entry.value > 0).map((entry) {
      // Get the specific category type
      final categoryType = entry.key;
      // Filter transactions for this category
      final categoryTransactions = transList.transactions
          .where((trans) => trans.transType == categoryType)
          .toList();

      return ListTile(
        leading:
            Icon(_getIconForTransactionType(categoryType), color: _textColor),
        title: Text(transTypeToString(categoryType),
            style: TextStyle(color: _textColor)),
        trailing: Text(entry.value.toStringAsFixed(2),
            style: TextStyle(color: _textColor)),
        onTap: () {
          // Show dialog on tap
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                backgroundColor: _cardDark,
                title: Text('${transTypeToString(categoryType)} Transactions',
                    style: TextStyle(color: _textColor)),
                children: categoryTransactions.isEmpty
                    ? [
                        ListTile(
                            title: Text('No transactions found.',
                                style: TextStyle(color: _textColor)))
                      ]
                    : categoryTransactions.map((trans) {
                        return ListTile(
                          title: Text(trans.transName,
                              style: TextStyle(color: _textColor)),
                          subtitle: Text(
                              DateFormat('yyyy-MM-dd')
                                  .format(trans.transactionDate),
                              style: TextStyle(
                                  color: Color(0xFFBBBBBB))), // Format date
                          trailing: Text(trans.amount.toStringAsFixed(2),
                              style: TextStyle(color: _textColor)),
                        );
                      }).toList(),
              );
            },
          );
        },
      );
    }).toList();

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title:
            const Text('Budget Summary', style: TextStyle(color: _textColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: _backgroundDark,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    chartData.isEmpty
                        ? Center(
                            child: Text(
                                'No transaction data available for summary.',
                                style: TextStyle(color: _textColor)))
                        : SizedBox(
                            height: 200,
                            child: Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 350,
                              height: 300,
                              child: Chart(
                                data: chartData,
                                variables: {
                                  'category': Variable(
                                    accessor: (Map map) =>
                                        map['category'] as String,
                                  ),
                                  'amount': Variable(
                                    accessor: (Map map) => map['amount'] as num,
                                    scale: LinearScale(min: 0),
                                  ),
                                },
                                transforms: [
                                  Proportion(
                                    variable: 'amount',
                                    as: 'percent',
                                  )
                                ],
                                marks: [
                                  IntervalMark(
                                    position:
                                        Varset('percent') / Varset('category'),
                                    label: LabelEncode(
                                        encoder: (tuple) => Label(
                                              tuple['category'].toString(),
                                            )),
                                    color: ColorEncode(
                                        variable: 'category',
                                        values: _chartColors),
                                    modifiers: [StackModifier()],
                                  )
                                ],
                                coord: PolarCoord(
                                  transposed: true,
                                  dimCount: 1,
                                  startRadius: 0.4,
                                ),
                                selections: {'tap': PointSelection()},
                              ),
                            ),
                          ),
                    Divider(color: _secondaryColor),
                    Expanded(
                      child: ListView(
                        children: insightListTiles.isEmpty
                            ? [
                                Center(
                                    child: Text('No spending details.',
                                        style: TextStyle(color: _textColor)))
                              ]
                            : insightListTiles,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
