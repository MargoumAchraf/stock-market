import 'package:flutter/material.dart';
import 'package:stock_market/Database/DatabaseHelper.dart';
import 'package:stock_market/views/Home.dart';
import 'package:stock_market/views/Login.dart';
import 'package:stock_market/views/register.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Market App',
      initialRoute: '/home',
      navigatorKey: navigatorKey,
      routes: {
        '/home': (context) => const HomePage(),
        // '/profile': (context) => const ProfilePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
