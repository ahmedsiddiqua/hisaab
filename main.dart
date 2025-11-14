import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/friend_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('friendsBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hisaab',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Moldern', // keep your font
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF3D4C3A), // deep olive green for premium feel
          secondary: Color(0xFFC2B280), // soft gold accent
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF3D4C3A), // same deep green
          foregroundColor: Color(0xFFF5F5F5), // off-white for contrast
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFC2B280), // gold accent
          foregroundColor: Colors.black87,
        ),
      ),
      home: FriendListPage(),
    );
  }
}
