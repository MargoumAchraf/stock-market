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

  static const String baseUrl = "https://crusader-arming-riverboat.ngrok-free.dev";



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

  Future<void> fetchStocks() async {
    if (!await SessionManager.isLoggedIn()) {
      isLoading = false;
      setState(() {});
      SessionManager.logout(); 
     
      return;
    }

    isLoading = true;
    errorMessage = null;
    setState(() {});

    try {
      final listRes = await http.get(Uri.parse("$baseUrl/stocks_list"));

      if (listRes.statusCode != 200) {
        throw Exception("Failed to fetch stocks_list: ${listRes.statusCode}");
      }

      final List<dynamic> allSymbols = jsonDecode(listRes.body);
      final symbols = allSymbols.cast<String>().take(20).toList();

      final List<Map<String, dynamic>> results = [];

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

      _refreshPrices();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      setState(() {});
    }
  }

  

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
      return null;
    }

    user = await UserDB.getUser();
    if (user == null) {
      await SessionManager.logout();
      
      return null;
    }
    return user != null ? User.fromJson(user!) : null;
  }
}
