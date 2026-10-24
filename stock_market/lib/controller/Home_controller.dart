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

  static const String baseUrl = "http://10.0.2.2:5001";

  List<Map<String, dynamic>> stocks = [];
  Map<String, dynamic>? user;
  bool isLoading = false;
  String? errorMessage;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    stocks.clear();
    user = null;
    errorMessage = null;
    super.dispose();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    user = null;
    stocks = [];
    isLoading = false;
    errorMessage = null;
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

      stocks = symbols.map((symbol) => {'symbol': symbol}).toList();
      isLoading = false;
      setState(() {});
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      setState(() {});
    }
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
