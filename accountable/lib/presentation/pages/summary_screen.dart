import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
import 'package:provider/provider.dart';
import '../../backend/app_state.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

// Updated Mafuyu Theme Colors
const Color _primaryColor = Color(0xFF7A6B8D);
const Color _secondaryColor = Color(0xFF9B8EB8);
const Color _accentColor = Color(0xFFAEA0CC);
const Color _textColor = Color(0xFFF0F0F0);
const Color _backgroundDark = Color(0xFF2A2832);
const Color _cardDark = Color(0xFF3A364A);

// Enhanced chart colors in Mafuyu theme
final List<Color> _chartColors = [
  Color(0xFF7A6B8D), // Primary
  Color(0xFF9B8EB8), // Secondary
  Color(0xFFAEA0CC), // Accent
  Color(0xFF63566E), // Darker Primary
  Color(0xFF7A8CA3), // Desaturated Light Blue
  Color(0xFF807794), // Lighter Primary
  Color(0xFFB5A9CC), // Lighter Accent
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

  // Method to build Top 3 spending widgets
  List<Widget> _buildTop3SpendingWidgets(
      Map<TransactionType, double> insights) {
    // Sort categories by spending amount in descending order
    final sortedEntries = insights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 (or less if fewer categories exist)
    final top3 = sortedEntries.take(3).toList();

    if (top3.isEmpty) {
      return [
        Center(
          child: Text(
            'No spending data available',
            style: TextStyle(color: _textColor.withOpacity(0.7)),
          ),
        )
      ];
    }

    return top3.map((entry) {
      final percent = insights.values.isNotEmpty
          ? (entry.value / insights.values.reduce((a, b) => a + b) * 100)
              .toStringAsFixed(1)
          : '0.0';

      return Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForTransactionType(entry.key),
                color: _accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transTypeToString(entry.key),
                    style: const TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percent% of total',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

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

      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _cardDark,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForTransactionType(categoryType),
              color: _accentColor,
              size: 24,
            ),
          ),
          title: Text(
            transTypeToString(categoryType),
            style: const TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            // Show dialog on tap
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: _cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIconForTransactionType(categoryType),
                              color: _accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${transTypeToString(categoryType)} Transactions',
                              style: const TextStyle(
                                color: _textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF4A4758)),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          child: categoryTransactions.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No transactions found.',
                                      style: TextStyle(color: _textColor),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: categoryTransactions.length,
                                  itemBuilder: (context, index) {
                                    final trans = categoryTransactions[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trans.transName,
                                                  style: const TextStyle(
                                                    color: _textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('MMM dd, yyyy')
                                                      .format(trans
                                                          .transactionDate),
                                                  style: TextStyle(
                                                    color: _textColor
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${trans.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: _textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _accentColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Budget Summary',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            )),
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.insert_chart,
                            color: _textColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Spending Insights',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: chartData.isEmpty
                            ? const Center(
                                child: Text(
                                  'No spending data available',
                                  style: TextStyle(color: _textColor),
                                ),
                              )
                            : Chart(
                                data: chartData,
                                variables: {
                                  'category': Variable(
                                    accessor: (Map map) =>
                                        map['category'] as String,
                                  ),
                                  'amount': Variable(
                                    accessor: (Map map) =>
                                        map['amount'] as double,
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
                                    color: ColorEncode(
                                      variable: 'category',
                                      values: _chartColors,
                                    ),
                                    modifiers: [StackModifier()],
                                    label: LabelEncode(
                                      encoder: (tuple) {
                                        final category =
                                            tuple['category'].toString();
                                        final percent =
                                            (tuple['percent'] as num)
                                                .toStringAsFixed(1);
                                        return Label(
                                          '$category\n$percent%',
                                          LabelStyle(
                                            textStyle: const TextStyle(
                                              color: _textColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            align: Alignment.center,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                ],
                                coord: PolarCoord(
                                  transposed: true,
                                  dimCount: 1,
                                  startRadius: 0.2,
                                  endRadius: 0.9,
                                ),
                                selections: {
                                  'tap': PointSelection(
                                    on: {GestureType.tap},
                                    variable: 'category',
                                  )
                                },
                                tooltip: TooltipGuide(
                                  followPointer: [false, true],
                                  align: Alignment.topLeft,
                                  offset: const Offset(-20, -20),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Add Top 3 Spending Widget
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: _cardDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: _accentColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Top 3 Spending',
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...insights.isEmpty
                          ? [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No spending data available',
                                    style: TextStyle(
                                        color: _textColor.withOpacity(0.7)),
                                  ),
                                ),
                              )
                            ]
                          : _buildTop3SpendingWidgets(insights),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Spending Categories',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: insightListTiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                size: 64,
                                color: _accentColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No spending data available',
                                style: TextStyle(
                                  color: _textColor.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: insightListTiles,
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
