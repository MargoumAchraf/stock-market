import 'package:flutter/material.dart';
import 'package:stock_market/main.dart';

class FooterBar extends StatelessWidget {
  const FooterBar({super.key});

  static const List<String> _routes = [
    '/home',
    '/portfolio',
  ];

  int _currentIndex(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final index = _routes.indexOf(currentRoute ?? '/home');
    return index == -1 ? 0 : index;
  }

  void _onTap(BuildContext context, int index) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final targetRoute = _routes[index];

    if (currentRoute == targetRoute) return; 

    navigatorKey.currentState?.pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex(context),
      onTap: (index) => _onTap(context, index),
      selectedItemColor: Colors.orange.shade900,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart),
          label: 'Portfolio',
        ),
      ],
    );
  }
}