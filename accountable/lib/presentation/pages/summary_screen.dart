import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';
const basicData = [
  {'genre': 'Sports', 'sold': 275},
  {'genre': 'Strategy', 'sold': 115},
  {'genre': 'Action', 'sold': 120},
  {'genre': 'Shooter', 'sold': 350},
  {'genre': 'Other', 'sold': 150},
];
class BudgetSummaryScreen extends StatelessWidget {
  const BudgetSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    SizedBox(
                      height: 200,
                      child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 350,
                height: 300,
                child: Chart(
                  data: basicData,
                  variables: {
                    'genre': Variable(
                      accessor: (Map map) => map['genre'] as String,
                    ),
                    'sold': Variable(
                      accessor: (Map map) => map['sold'] as num,
                    ),
                  },
                  transforms: [
                    Proportion(
                      variable: 'sold',
                      as: 'percent',
                    )
                  ],
                  marks: [
                    IntervalMark(
                      position: Varset('percent') / Varset('genre'),
                      color: ColorEncode(
                          variable: 'genre', values: Defaults.colors10),
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
                    const ListTile(
                      leading: Icon(Icons.business),
                      title: Text('Item'),
                      trailing: Text('100/200'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.business),
                      title: Text('Item'),
                      trailing: Text('19/29'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.business),
                      title: Text('Item'),
                      trailing: Text(
                        '100/50!!!',
                        style: TextStyle(color: Colors.red),
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