import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_market/Widget/footer.dart';
import 'package:stock_market/controller/Portfolio_controller.dart';
import 'package:stock_market/model/Holding.dart';

class portfolioPage extends StatefulWidget {
  const portfolioPage({super.key});

  @override
  State createState() => _PortfolioViewState();
}

class _PortfolioViewState extends StateMVC<portfolioPage> {
  _PortfolioViewState() : super(PortfolioController()) {
    con = controller as PortfolioController;
  }

  late final PortfolioController con;

  static const _bg = Color(0xFFF2F2F2);
  static const _orange = Color(0xFFFF8C00);
  static const _orangeDark = Color(0xFFF57C00);
  static const _orangeLight = Color(0xFFFFF0DC);
  static const _text = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (!mounted) return;
    await con.init(userId);
  }

  double get _totalInvested => con.holdings.fold(0.0, (sum, h) => sum + (h.price));

  int get _totalShares => con.holdings.fold(0, (sum, h) => sum + h.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Portfolio',
          style: TextStyle(color: _text, fontWeight: FontWeight.w700),
        ),
      ),
      body: _body(),
      bottomNavigationBar: FooterBar(),
    );
  }

  Widget _body() {
    if (con.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (con.error != null) {
      return Center(
        child: Text(con.error!,
            style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (con.holdings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: _muted),
            SizedBox(height: 12),
            Text('You do not own any stocks yet',
                style: TextStyle(color: _muted, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _summary(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Stocks',
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: _load,
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...con.holdings.map(_holdingCard),
        ],
      ),
    );
  }

  Widget _summary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_orangeDark, _orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Invested',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '\$ ${_totalInvested.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill(Icons.business_center_outlined,
                  '${con.holdings.length} stocks'),
              const SizedBox(width: 10),
              _pill(Icons.layers_outlined, '$_totalShares shares'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _holdingCard(Holding h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _orangeLight,
            child: Text(
              h.symbol.isEmpty ? '?' : h.symbol[0],
              style: const TextStyle(
                color: _orange,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.symbol,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${h.quantity} shares @ \$${h.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${h.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}