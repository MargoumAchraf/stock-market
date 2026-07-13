



import 'package:flutter/material.dart';
import 'package:stock_market/Widget/footer.dart';

class portfolioPage extends StatelessWidget {
  const portfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: const Center(
        child: Text('This is the Portfolio Page'),
      ),
      bottomNavigationBar: FooterBar(),
    );
  }
}