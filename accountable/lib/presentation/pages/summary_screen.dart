import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:provider/provider.dart';
import '../../backend/app_state.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

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
      return Icons.sports_esports; // Or other relevant icon
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
        leading: Icon(_getIconForTransactionType(categoryType)),
        title: Text(transTypeToString(categoryType)),
        trailing: Text(entry.value.toStringAsFixed(2)),
        onTap: () {
          // Show dialog on tap
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return SimpleDialog(
                title: Text('${transTypeToString(categoryType)} Transactions'),
                children: categoryTransactions.isEmpty
                    ? [const ListTile(title: Text('No transactions found.'))]
                    : categoryTransactions.map((trans) {
                        return ListTile(
                          title: Text(trans.transName),
                          subtitle: Text(DateFormat('yyyy-MM-dd')
                              .format(trans.transactionDate)), // Format date
                          trailing: Text(trans.amount.toStringAsFixed(2)),
                        );
                      }).toList(),
              );
            },
          );
        },
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[200],
        title: const Text('Budget Summary'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    chartData.isEmpty
                        ? const Center(
                            child: Text(
                                'No transaction data available for summary.'))
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
                                        values: Defaults.colors10),
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
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: insightListTiles.isEmpty
                            ? [
                                const Center(
                                    child: Text('No spending details.'))
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
