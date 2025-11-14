import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'friend_detail_page.dart';

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final box = Hive.box('friendsBox');
  final nameController = TextEditingController();
  final searchController = TextEditingController();
  List<String> displayedKeys = [];

  @override
  void initState() {
    super.initState();
    displayedKeys = box.keys.cast<String>().toList();
    searchController.addListener(_filterFriends);
  }

  void _filterFriends() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedKeys = box.keys
          .cast<String>()
          .where((key) => key.toLowerCase().contains(query))
          .toList();
    });
  }

  void addFriend(String name) {
    if (name.isEmpty) return;

    String formattedName = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');

    if (formattedName.isEmpty || box.containsKey(formattedName)) return;

    box.put(formattedName, []);
    nameController.clear();
    Navigator.pop(context);
    setState(() {
      displayedKeys = box.keys.cast<String>().toList();
    });
  }

  void deleteFriend(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF3D4C3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name" and all their transactions? This action is non-reversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              box.delete(name);
              setState(() {
                displayedKeys = box.keys.cast<String>().toList();
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  double calculateTotal(List transactions) {
    return transactions.fold(0.0, (sum, item) {
      return item['type'] == 'add'
          ? sum + item['amount']
          : sum - item['amount'];
    });
  }

  double getOverallTotal() {
    double total = 0.0;
    for (var key in box.keys) {
      final transactions = box.get(key) as List;
      total += calculateTotal(transactions);
    }
    return total;
  }

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/YOUR_GITHUB_USERNAME'); // replace
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch GitHub')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3D4C3A),
        foregroundColor: Colors.white,
        elevation: 4,
        title: Text(
          'Hisaap',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 40,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.github,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'GitHub',
            onPressed: _launchGitHub,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF4B5D50),
                labelText: 'Search friend',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Total pending
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Total pending: ₹${getOverallTotal().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          // Friend List
          Expanded(
            child: displayedKeys.isEmpty
                ? Center(
                    child: Text(
                      '404, User not found\nClick the + icon to create a new user',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 100), // space for FAB
                    itemCount: displayedKeys.length,
                    itemBuilder: (_, index) {
                      final key = displayedKeys.elementAt(index);
                      final transactions = box.get(key) as List;
                      final total = calculateTotal(transactions);

                      bool _pressed = false;

                      return StatefulBuilder(
                        builder: (context, setInnerState) {
                          return AnimatedScale(
                            scale: _pressed ? 0.97 : 1.0,
                            duration: Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTapDown: (_) => setInnerState(() => _pressed = true),
                              onTapUp: (_) => setInnerState(() => _pressed = false),
                              onTapCancel: () => setInnerState(() => _pressed = false),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FriendDetailPage(name: key),
                                ),
                              ).then((_) => setState(() {
                                    displayedKeys = box.keys.cast<String>().toList();
                                  })),
                              child: Container(
                                constraints: BoxConstraints(minHeight: 80),
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4B5D50),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Balance: ₹${total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: total >= 0
                                            ? Color(0xFF9FE6A0)
                                            : Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      // FAB + Add User Dialog
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFC2B280),
        foregroundColor: Colors.black87,
        child: Icon(Icons.person_add),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF3D4C3A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add User',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Color(0xFF4B5D50),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text('Cancel', style: TextStyle(color: Colors.white70)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC2B280),
                        ),
                        child: Text('Add', style: TextStyle(color: Colors.black87)),
                        onPressed: () => addFriend(nameController.text.trim()),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
