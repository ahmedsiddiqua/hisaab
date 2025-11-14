import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FriendDetailPage extends StatefulWidget {
  final String name;
  FriendDetailPage({required this.name});

  @override
  _FriendDetailPageState createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final box = Hive.box('friendsBox');

  void addTransaction(String type) {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final transaction = {
      'type': type,
      'amount': amount,
      'note': noteController.text.trim(),
      'date': DateTime.now().toString(),
    };

    final list = box.get(widget.name) as List;
    list.add(transaction);
    box.put(widget.name, list);
    amountController.clear();
    noteController.clear();
    Navigator.pop(context);
    setState(() {});
  }

  double getTotal(List txns) {
    return txns.fold(
      0.0,
      (sum, item) =>
          item['type'] == 'add' ? sum + item['amount'] : sum - item['amount'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = (box.get(widget.name) as List).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total Balance: ₹${getTotal(transactions).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(),
          Expanded(
            child:
                transactions.isEmpty
                    ? Center(child: Text('No transactions yet.'))
                    : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (_, index) {
                        final tx = transactions[index];
                        final isAdd = tx['type'] == 'add';
                        return ListTile(
                          leading: Icon(
                            isAdd ? Icons.call_received : Icons.call_made,
                            color: isAdd ? Colors.green : Colors.red,
                          ),
                          title: Text('${isAdd ? "+" : "-"} ₹${tx['amount']}'),
                          subtitle: Text(
                            '${tx['note']} \n${tx['date'].split(".")[0]}',
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            label: Text('Add'),
            icon: Icon(Icons.add),
            onPressed: () => showTxnDialog('add'),
            heroTag: "addBtn",
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            label: Text('Remove'),
            icon: Icon(Icons.remove),
            onPressed: () => showTxnDialog('subtract'),
            backgroundColor: Colors.red,
            heroTag: "subtractBtn",
          ),
        ],
      ),
    );
  }

  void showTxnDialog(String type) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(type == 'add' ? 'Add Amount' : 'Remove Amount'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Save'),
                onPressed: () => addTransaction(type),
              ),
            ],
          ),
    );
  }
}
