import 'package:accountable/backend/app_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String detailsPath;

  const HomePage({super.key, required this.detailsPath});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
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

  @override
  void initState() {
    super.initState();
    // Initialize any data or state here if needed
    //context.read<AppState>().loadAll(); // load from DB
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.subtract(const Duration(days: 1));
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
                getFormattedDate(selectedDate),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '16,938.81',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              _buildDayExpense(
                day: 'Tue 17',
                totalExpense: '90,299',
                expenses: [
                  _buildExpenseItem(
                    icon: Icons.directions_bus,
                    title: 'Transport',
                    subtitle: 'Grab',
                    amount: '100',
                    context: context,
                  ),
                  _buildExpenseItem(
                    icon: Icons.directions_bus,
                    title: 'Transport',
                    subtitle: 'Bolt',
                    amount: '100',
                    context: context,
                  ),
                  _buildExpenseItem(
                    icon: Icons.restaurant,
                    title: 'Food',
                    subtitle: 'Robinhood',
                    amount: '99',
                    context: context,
                  ),
                  _buildExpenseItem(
                    icon: Icons.school,
                    title: 'Education',
                    subtitle:
                        'King Mongkut\'s Institute of Technology Ladkrabang',
                    amount: '90,000',
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDayExpense(
                day: 'Mon 16',
                totalExpense: '320',
                expenses: [
                  _buildExpenseItem(
                    icon: Icons.category,
                    title: 'Other',
                    subtitle: '...',
                    amount: '320',
                    context: context,
                  ),
                ],
              ),
            ],
          ),
        ),
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
        color: Colors.blue[800],
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
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                  Text(
                    'Expense $totalExpense',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(icon),
            onPressed: () => context.go(widget.detailsPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ],
            ),
          ),
          Text(amount,
              style: const TextStyle(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }
}
