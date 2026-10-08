import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/Database/Stock_db.dart';
import 'package:stock_market/model/Holding.dart';

class PortfolioController extends ControllerMVC {
  factory PortfolioController() => _this ??= PortfolioController._();
  PortfolioController._();
  static PortfolioController? _this;

  final StockDB _stockDb = StockDB();

  List<Holding> holdings = [];
  bool isLoading = true;
  String? error;

  Future<void> init(String? userId) async {
    try {
      error = null;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final rows = await _stockDb.getAllByUser(userId);
      holdings = rows
          .map((r) => Holding(
                id: r['id'] as String,
                symbol: r['symbol'] as String,
                price: (r['price'] as num).toDouble(),
                quantity: (r[StockDB.qtyColumn] as num).toInt(),
              ))
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      setState(() {});
    }
  }
}