import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FriendDetailPage extends StatefulWidget {
  final String name;
  FriendDetailPage({required this.name});

  @override
  _FriendDetailPageState createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage>
    with TickerProviderStateMixin {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final box = Hive.box('friendsBox');
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

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
    final total = getTotal(transactions);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFF00D084),
        elevation: 0,
        title: Text(
          '> ${widget.name}',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Color(0xFF00D084),
          ),
        ),
      ),
      body: Column(
        children: [
          // Total Balance
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF30363D), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'total_balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B949E),
                      fontFamily: 'Courier New',
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
                      color: total >= 0 ? Color(0xFF3FB950) : Color(0xFFF85149),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: Color(0xFF30363D), height: 0),
          // Transactions List
          Expanded(
            child:
                transactions.isEmpty
                    ? Center(
                      child: Text(
                        'transactions_empty()',
                        style: TextStyle(
                          color: Color(0xFF6E7681),
                          fontSize: 14,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    )
                    : ListView.builder(
                      physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: transactions.length,
                      itemBuilder: (_, index) {
                        final tx = transactions[index];
                        final isAdd = tx['type'] == 'add';
                        final dateStr = tx['date'].toString().split('.')[0];

                        return AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF30363D),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950).withOpacity(0.2)
                                          : Color(0xFFF85149).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isAdd ? Icons.add : Icons.remove,
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950)
                                          : Color(0xFFF85149),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${isAdd ? "+" : "-"} ₹${tx['amount']}',
                                style: TextStyle(
                                  fontFamily: 'Courier New',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE6EDF3),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  if (tx['note'].isNotEmpty)
                                    Text(
                                      tx['note'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B949E),
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                  SizedBox(
                                    height: tx['note'].isNotEmpty ? 4 : 0,
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6E7681),
                                      fontFamily: 'Courier New',
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isAdd
                                          ? Color(0xFF3FB950).withOpacity(0.15)
                                          : Color(0xFFF85149).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isAdd ? 'add' : 'remove',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isAdd
                                            ? Color(0xFF3FB950)
                                            : Color(0xFFF85149),
                                    fontFamily: 'Courier New',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
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
            label: Text(
              'add',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.add),
            onPressed: () => showTxnDialog('add'),
            heroTag: "addBtn",
            backgroundColor: Color(0xFF3FB950),
            foregroundColor: Color(0xFF0D1117),
          ),
          SizedBox(height: 12),
          FloatingActionButton.extended(
            label: Text(
              'remove',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            icon: Icon(Icons.remove),
            onPressed: () => showTxnDialog('subtract'),
            backgroundColor: Color(0xFFF85149),
            foregroundColor: Color(0xFF0D1117),
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
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Color(0xFF161B22),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF30363D), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type == 'add' ? r'$ add_amount()' : r'$ remove_amount()',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D084),
                      fontFamily: 'Courier New',
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: InputDecoration(
                      labelText: 'amount',
                      labelStyle: TextStyle(
                        color: Color(0xFF8B949E),
                        fontFamily: 'Courier New',
                      ),
                      filled: true,
                      fillColor: Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF00D084),
                          width: 2,
                        ),
                      ),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontFamily: 'Courier New',
                    ),
                    decoration: InputDecoration(
                      labelText: 'note (optional)',
                      labelStyle: TextStyle(
                        color: Color(0xFF8B949E),
                        fontFamily: 'Courier New',
                      ),
                      filled: true,
                      fillColor: Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF00D084),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(
                          'cancel',
                          style: TextStyle(
                            color: Color(0xFF8B949E),
                            fontFamily: 'Courier New',
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              type == 'add'
                                  ? Color(0xFF3FB950)
                                  : Color(0xFFF85149),
                          foregroundColor: Color(0xFF0D1117),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'save',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => addTransaction(type),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
