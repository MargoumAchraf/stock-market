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

  double get estimatedCost => currentPrice * tradeQuantity;
  Future<void> buy(String symbol) async {
    // Implement buy logic here
    print(
      'Buying $tradeQuantity shares at \$${currentPrice.toStringAsFixed(2)} each. Total: \$${estimatedCost.toStringAsFixed(2)}',
    );

    String? userId = await SessionManager.getUserId();

    if (userId == null) {
      print("User not logged in. Cannot proceed with the purchase.");
      SessionManager.logout();
      return;
    }

    final userDB = UserDB();
    final rawUser = await UserDB.getUser();
    if (rawUser == null) {
      print("User not found in the database.");
      return;
    }
    print("111111111111111111111111111111111111111111111111");
    // Copy into a mutable map — the row returned by sqflite is read-only.
    final user = Map<String, dynamic>.from(rawUser);

    double currentBalance = user['balance'] as double;
    if (currentBalance < estimatedCost) {
      print("Insufficient balance. Cannot complete the purchase.");
      return;
    }
    print("22222222222222222222222222222222222222222222222");
    final stockDB = StockDB();
    Stock stock = Stock(
      id: Uuid().generateV4(),
      userId: userId,
      symbol: symbol,
      price: currentPrice,
      country: tradeQuantity, // was: country: tradeQuantity
      changePercent:
          0.0, // Placeholder; you may want to compute this based on your logic
      updatedAt: DateTime.now().toIso8601String(),
    );
    print("33333333333333333333333333333333333333333333333");
    user['balance'] = currentBalance - estimatedCost;
    await userDB.update(user);
    print(
      'Purchase successful! New balance: \$${user['balance'].toStringAsFixed(2)}',
    );
    await stockDB.insert(stock.toMap());
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
      displayData.isNotEmpty ? displayData.last.close ?? 0 : 0;
}
