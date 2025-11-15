import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'friend_detail_page.dart';

class FriendListPage extends StatefulWidget {
  @override
  _FriendListPageState createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage>
    with TickerProviderStateMixin {
  final box = Hive.box('friendsBox');
  final nameController = TextEditingController();
  final searchController = TextEditingController();
  List<String> displayedKeys = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    displayedKeys = box.keys.cast<String>().toList();
    searchController.addListener(_filterFriends);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedKeys =
          box.keys
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
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        )
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
      builder:
          (_) => AlertDialog(
            backgroundColor: Color(0xFF3D4C3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirm Deletion',
              style: TextStyle(color: Colors.white),
            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
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
    final Uri url = Uri.parse(
      'https://github.com/ahmedsiddiqua/hisaab',
    ); // replace
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch GitHub')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Color(0xFF00D084),
        elevation: 0,
        title: Text(
          '> hisaab',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Color(0xFF00D084),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.github,
              color: Color(0xFF58A6FF),
              size: 20,
            ),
            tooltip: 'GitHub',
            onPressed: _launchGitHub,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with terminal style
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontFamily: 'Courier New',
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF0D1117),
                labelText: 'Search user',
                labelStyle: TextStyle(
                  color: Color(0xFF8B949E),
                  fontFamily: 'Courier New',
                ),
                prefixIcon: Icon(Icons.search, color: Color(0xFF58A6FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00D084), width: 2),
                ),
              ),
            ),
          ),
          // Total pending with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF30363D), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'total_pending: ₹${getOverallTotal().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Courier New',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF58A6FF),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          // Friend List
          Expanded(
            child:
                displayedKeys.isEmpty
                    ? Center(
                      child: Text(
                        r'$ user_not_found()' +
                            '\n\ntype "+ icon" to create_user()',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6E7681),
                          fontSize: 14,
                          fontFamily: 'Courier New',
                          height: 1.6,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(bottom: 100),
                      physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: displayedKeys.length,
                      itemBuilder: (_, index) {
                        final key = displayedKeys.elementAt(index);
                        final transactions = box.get(key) as List;
                        final total = calculateTotal(transactions);
                        bool _pressed = false;

                        return StatefulBuilder(
                          builder: (context, setInnerState) {
                            return AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_fadeAnimation.value * 10, 0),
                                  child: Opacity(
                                    opacity: _fadeAnimation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTapDown:
                                    (_) => setInnerState(() => _pressed = true),
                                onTapUp:
                                    (_) =>
                                        setInnerState(() => _pressed = false),
                                onTapCancel:
                                    () => setInnerState(() => _pressed = false),
                                onTap:
                                    () => Navigator.of(context)
                                        .push(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                ) =>
                                                    FriendDetailPage(name: key),
                                            transitionsBuilder: (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve =
                                                  Curves.easeInOutCubic;
                                              final tween = Tween(
                                                begin: begin,
                                                end: end,
                                              ).chain(CurveTween(curve: curve));
                                              final offsetAnimation = animation
                                                  .drive(tween);
                                              return SlideTransition(
                                                position: offsetAnimation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration: Duration(
                                              milliseconds: 500,
                                            ),
                                          ),
                                        )
                                        .then(
                                          (_) => setState(() {
                                            displayedKeys =
                                                box.keys
                                                    .cast<String>()
                                                    .toList();
                                          }),
                                        ),
                                child: AnimatedScale(
                                  scale: _pressed ? 0.97 : 1.0,
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeInOutCubic,
                                  child: Container(
                                    constraints: BoxConstraints(minHeight: 70),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF161B22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            _pressed
                                                ? Color(0xFF00D084)
                                                : Color(0xFF30363D),
                                        width: _pressed ? 2 : 1,
                                      ),
                                      boxShadow:
                                          _pressed
                                              ? [
                                                BoxShadow(
                                                  color: Color(
                                                    0xFF00D084,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                              : [],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                key,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFE6EDF3),
                                                  fontFamily: 'Courier New',
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'balance: ₹${total.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontFamily: 'Courier New',
                                                  color:
                                                      total >= 0
                                                          ? Color(0xFF3FB950)
                                                          : Color(0xFFF85149),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF6E7681),
                                        ),
                                      ],
                                    ),
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
        backgroundColor: Color(0xFF00D084),
        foregroundColor: Color(0xFF0D1117),
        child: Icon(Icons.add, size: 28),
        elevation: 2,
        onPressed:
            () => showDialog(
              context: context,
              builder:
                  (_) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xFF161B22),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF30363D), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r'$ add_user()',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00D084),
                              fontFamily: 'Courier New',
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: Color(0xFFE6EDF3),
                              fontFamily: 'Courier New',
                            ),
                            decoration: InputDecoration(
                              hintText: 'name_',
                              hintStyle: TextStyle(
                                color: Color(0xFF6E7681),
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
                          SizedBox(height: 24),
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
                                  backgroundColor: Color(0xFF00D084),
                                  foregroundColor: Color(0xFF0D1117),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'create',
                                  style: TextStyle(
                                    fontFamily: 'Courier New',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed:
                                    () => addFriend(nameController.text.trim()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
      ),
    );
  }
}
