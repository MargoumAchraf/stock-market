import 'package:flutter/material.dart';
import 'package:stock_market/views/Login.dart';
import 'package:stock_market/views/register.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Market App',
      initialRoute: '/login',
      routes: {
        // '/home': (context) => const HomePage(),
        // '/profile': (context) => const ProfilePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
