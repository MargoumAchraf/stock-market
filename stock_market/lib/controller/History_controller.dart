import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:stock_market/Database/Stock_db.dart';
import 'package:stock_market/Database/User_db.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/model/Stock.dart';
import 'package:stock_market/service/candle_aggregation.dart';
import 'package:stock_market/service/mock_data.dart';

class HistoryController extends ControllerMVC {
  factory HistoryController() => _this ??= HistoryController._();
  static HistoryController? _this;
  HistoryController._() : super();

  List<CandleData> dailyData = [];
  List<CandleData> displayData = [];
  Timeframe timeframe = Timeframe.day;
  bool showAverage = false;
  bool loading = true;
  String? error;

  int tradeQuantity = 1;

  void incrementQuantity() {
    setState(() => tradeQuantity++);
  }

  void decrementQuantity() {
    if (tradeQuantity <= 1) return;
    setState(() => tradeQuantity--);
  }

  void resetQuantity() {
  tradeQuantity = 1; 
}

  double get estimatedCost => currentPrice * tradeQuantity;
Future<void> buy(String symbol) async {
  final double totalPrice = currentPrice * tradeQuantity;



  final String? userId = await SessionManager.getUserId();
  if (userId == null) {
    SessionManager.logout();
    return;
  }

  final userDB = UserDB();
  final rawUser = await UserDB.getUser();
  if (rawUser == null) {
    return;
  }

  final user = Map<String, dynamic>.from(rawUser);
  final double currentBalance = (user['balance'] as num).toDouble();

  if (currentBalance < totalPrice) {
    return;
  }

  final stockDB = StockDB();
  final existing = await stockDB.getUserStock(userId, symbol);

  if (existing != null) {
    final int oldQty = (existing['country'] as num).toInt();
    final double oldPrice = (existing['price'] as num).toDouble();
    final int newQty = oldQty + tradeQuantity;
    final double avgPrice = (oldPrice + totalPrice);

    await stockDB.updateStock(existing['id'] as String, {
      'country': newQty,
      'price': avgPrice,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  } else {
    final double currentPricetotla = currentPrice * tradeQuantity;
    final Stock stock = Stock(
      id: Uuid().generateV4(),
      userId: userId,
      symbol: symbol,
      price: currentPricetotla,
      country: tradeQuantity,
      changePercent: 0.0,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await stockDB.insert(stock.toMap());
  }

  user['balance'] = currentBalance - totalPrice;
  await userDB.update(user);


}






Future<void> sell(String symbol) async {
  final double totalPrice = currentPrice * tradeQuantity;

  final String? userId = await SessionManager.getUserId();
  if (userId == null) {
    SessionManager.logout();
    return;
  }

  final userDB = UserDB();
  final rawUser = await UserDB.getUser();
  if (rawUser == null) {
    return;
  }

  final user = Map<String, dynamic>.from(rawUser);
  final double currentBalance = (user['balance'] as num).toDouble();

  final stockDB = StockDB();
  final existing = await stockDB.getUserStock(userId, symbol);

  if (existing == null) {
    return;
  }

  final int ownedQty = (existing['country'] as num).toInt(); 

  if (tradeQuantity > ownedQty) {
    return;
  }

  final int remaining = ownedQty - tradeQuantity;

  if (remaining == 0) {
    await stockDB.deleteStock(existing['id'] as String);
  } else {
    await stockDB.updateStock(existing['id'] as String, {
      'country': remaining,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  user['balance'] = currentBalance + totalPrice;
  await userDB.update(user);


}


  Future<void> loadData(String symbol) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final candles = await fetchCandlesFromApi(symbol: symbol);
      candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {
        dailyData = candles;
        loading = false;
      });
      _applyTimeframe();
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void onTimeframeChanged(Timeframe tf) {
    if (tf == timeframe) return;
    timeframe = tf;
    _applyTimeframe();
  }

  void toggleAverage() {
    setState(() => showAverage = !showAverage);
    showAverage ? _computeTrendLines() : _removeTrendLines();
  }

  void _applyTimeframe() {
    setState(() {
      displayData = aggregateCandles(dailyData, timeframe);
      showAverage ? _computeTrendLines() : _removeTrendLines();
    });
  }

  void _computeTrendLines() {
    final ma7 = CandleData.computeMA(displayData, 7);
    final ma30 = CandleData.computeMA(displayData, 30);
    final ma90 = CandleData.computeMA(displayData, 90);
    for (int i = 0; i < displayData.length; i++) {
      displayData[i].trends = [ma7[i], ma30[i], ma90[i]];
    }
  }

  void _removeTrendLines() {
    for (final data in displayData) {
      data.trends = [];
    }
  }

  double get currentPrice =>
      displayData.isNotEmpty ? displayData.first.close ?? 0 : 0;
}
