import 'package:accountable/presentation/pages/addTransaction.dart';
import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text('Transaction Detail', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tue 24 Dec 24',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.red),
                  SizedBox(width: 8),
                  Text('400',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(Icons.directions_bus, 'Transport', context),
            const SizedBox(height: 10),
            _buildInfoTile(Icons.edit, 'blahblah', context),
            const SizedBox(height: 20),
            _buildSlipInfo(),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                // go to add transaction page
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const AddTransaction())
                  
                  );

              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlipInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Slip Info',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  Text('นายประยุทธ์ น.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Tue 24 Dec 24 22:08',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade400,
                child: const Center(
                  child: Text('Slip',
                      style: TextStyle(color: Colors.black, fontSize: 14)),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
