import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/views/Login.dart';       // ← e7ذف

class HomeController extends ControllerMVC {
  factory HomeController() => _this ??= HomeController._();
  HomeController._();
  static HomeController? _this;

  static const String baseUrl =
      "https://crusader-arming-riverboat.ngrok-free.dev";
  static const Duration refreshInterval = Duration(seconds: 5);

  List<Map<String, dynamic>> stocks = [];
  bool isLoading = false;
  String? errorMessage;

  Timer? _timer;

  String _dateStr(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initial load: get symbols + historical close (for % change baseline) + first price.
  Future<void> fetchStocks() async {
   if (!await SessionManager.isLoggedIn()) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
   
      // fallback: context mazal ma bnach, 3awd 3la fetchStocks() f frame jaya
      isLoading = false;
      errorMessage = "Session invalide, please re-open the app.";
      setState(() {});
    
  });
  return;
}
    print("Checking if user is logged in...");

    isLoading = true;
    errorMessage = null;
    setState(() {});

    print("Fetching stocks from $baseUrl/stocks_list");
    try {
      final listRes = await http.get(Uri.parse("$baseUrl/stocks_list"));

      print(
        "Response from stocks_list: ${listRes.statusCode}, body: ${listRes.body}",
      );

      if (listRes.statusCode != 200) {
        throw Exception("Failed to fetch stocks_list: ${listRes.statusCode}");
      }

      final List<dynamic> allSymbols = jsonDecode(listRes.body);
      final symbols = allSymbols.cast<String>().take(20).toList();

      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 7));

      final List<Map<String, dynamic>> results = [];

      // Fetch symbols concurrently instead of one by one
      final futures = symbols.map((symbol) async {
        try {
          final rateRes = await http.get(
            Uri.parse("$baseUrl/exchange_rate/$symbol"),
          );
          final histRes = await http.get(
            Uri.parse(
              "$baseUrl/hist/$symbol?start_date=${_dateStr(start)}&end_date=${_dateStr(end)}",
            ),
          );

          if (rateRes.statusCode != 200 || histRes.statusCode != 200)
            return null;

          final rateData = jsonDecode(rateRes.body);
          final histData = jsonDecode(histRes.body);

          final double price = (rateData['rate'] as num).toDouble();

          double prevClose = price;
          final List<dynamic> values = histData['values'] ?? [];
          if (values.isNotEmpty) {
            prevClose = (values.last['close'] as num).toDouble();
          }

          final double change = prevClose == 0
              ? 0
              : ((price - prevClose) / prevClose) * 100;

          return {
            'symbol': symbol,
            'name': symbol,
            'price': price,
            'prevClose':
                prevClose, // kept to recompute % change on every refresh
            'change': change,
            'positive': change >= 0,
          };
        } catch (_) {
          return null;
        }
      });

      final fetched = await Future.wait(futures);
      results.addAll(fetched.whereType<Map<String, dynamic>>());

      stocks = results;
      isLoading = false;
      setState(() {});

      // Start real-time polling once the initial list is loaded
      _startRealTimeUpdates();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      setState(() {});
    }
  }

  void _startRealTimeUpdates() {
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => _refreshPrices());
  }

  /// Lightweight refresh: only hits /exchange_rate/<symbol> for every
  /// monitored stock, in parallel, then updates prices + % change in place.
  Future<void> _refreshPrices() async {
    if (stocks.isEmpty) return;

    final futures = stocks.map((stock) async {
      final symbol = stock['symbol'] as String;
      try {
        final rateRes = await http.get(
          Uri.parse("$baseUrl/exchange_rate/$symbol"),
        );
        if (rateRes.statusCode != 200) return stock;

        final rateData = jsonDecode(rateRes.body);
        final double price = (rateData['rate'] as num).toDouble();
        final double prevClose = (stock['prevClose'] as num).toDouble();
        final double change = prevClose == 0
            ? 0
            : ((price - prevClose) / prevClose) * 100;

        return {
          ...stock,
          'price': price,
          'change': change,
          'positive': change >= 0,
        };
      } catch (_) {
        return stock;
      }
    });

    final updated = await Future.wait(futures);

    stocks = updated.cast<Map<String, dynamic>>();
    setState(() {});
  }
}
