import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/Database/User_db.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/model/User.dart';

class HomeController extends ControllerMVC {
  factory HomeController() => _this ??= HomeController._();
  HomeController._();
  static HomeController? _this;

  static const String baseUrl = "https://afraid-moments-divide.loca.lt";

  static const Duration refreshInterval = Duration(
    milliseconds: 5000,
  ); // 5x/sec

  List<Map<String, dynamic>> stocks = [];
  Map<String, dynamic>? user;
  bool isLoading = false;
  String? errorMessage;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initial load: get the list of symbols, then fetch each one's current price.
  Future<void> fetchStocks() async {
    if (!await SessionManager.isLoggedIn()) {
      print("User not logged in, skipping fetchStocks.");
      return;
    }

    isLoading = true;
    errorMessage = null;
    setState(() {});

    print("Fetching stocks from $baseUrl/stocks_list");
    try {
      final listRes = await http.get(Uri.parse("$baseUrl/stocks_list"));

      if (listRes.statusCode != 200) {
        throw Exception("Failed to fetch stocks_list: ${listRes.statusCode}");
      }

      final List<dynamic> allSymbols = jsonDecode(listRes.body);
      final symbols = allSymbols.cast<String>().take(20).toList();

      final List<Map<String, dynamic>> results = [];

      // Fetch each symbol's current price concurrently
      final futures = symbols.map((symbol) async {
        try {
          final rateRes = await http.get(
            Uri.parse("$baseUrl/exchange_rate/$symbol"),
          );

          if (rateRes.statusCode != 200) return null;

          final rateData = jsonDecode(rateRes.body);
          final double price = (rateData['rate'] as num).toDouble();

          return {'symbol': symbol, 'name': symbol, 'price': price};
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

  /// Lightweight refresh: hits /exchange_rate/<symbol> for every monitored
  /// stock in parallel and updates its price.
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

        return {...stock, 'price': price};
      } catch (_) {
        return stock;
      }
    });

    final updated = await Future.wait(futures);

    stocks = updated.cast<Map<String, dynamic>>();
    setState(() {});
  }

  Future<User?> getUser() async {
    if (!await SessionManager.isLoggedIn()) {
      print("User not logged in, skipping getUser.");
      return null;
    }

    user = await UserDB.getUser();
    if (user == null) {
      print("No user found in session, skipping getUser.");
      return null;
    }
    print("Fetched user: ${user!['username']} (${user!['email']})");
    return user != null ? User.fromJson(user!) : null;
  }
}
