import 'package:flutter/foundation.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:stock_market/service/candle_aggregation.dart';
import 'package:stock_market/service/mock_data.dart';
// import 'package:stock_market/service/portfolio_service.dart'; // ajuste l'import selon ton nom réel

class HistoryController extends ControllerMVC {
  factory HistoryController() => _this ??= HistoryController._();
  static HistoryController? _this;
  HistoryController._() : super();

  // final PortfolioService _portfolioService = PortfolioService();

  List<CandleData> dailyData = [];
  List<CandleData> displayData = [];
  Timeframe timeframe = Timeframe.day;
  bool showAverage = false;
  bool loading = true;
  String? error;

  // --- Trading state ---
  double balance = 0;
  int ownedQuantity = 0;
  int tradeQuantity = 1;
  bool tradeInProgress = false;
  String? tradeError;
  String? tradeSuccess;

  Future<void> loadData(String symbol) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final candles = await fetchCandlesFromApi(symbol: symbol);
      setState(() {
        dailyData = candles;
        loading = false;
      });
      _applyTimeframe();
      await _loadTradingInfo(symbol);
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadTradingInfo(String symbol) async {
    try {
      // final b = await _portfolioService.getBalance();
      // final qty = await _portfolioService.getHoldingQuantity(symbol);
      setState(() {
        // balance = b;
        // ownedQuantity = qty;
      });
    } catch (e) {
      // silencieux ici, pas besoin de bloquer le chart si ça échoue
      debugPrint('Failed to load trading info: $e');
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

  // --- Quantity controls ---
  void incrementQuantity() {
    setState(() => tradeQuantity++);
  }

  void decrementQuantity() {
    if (tradeQuantity <= 1) return;
    setState(() => tradeQuantity--);
  }

  void setQuantity(int qty) {
    if (qty < 1) return;
    setState(() => tradeQuantity = qty);
  }

  double get currentPrice =>
      displayData.isNotEmpty ? displayData.last.close ?? 0 : 0;

  double get estimatedCost => currentPrice * tradeQuantity;

  // --- Buy / Sell ---
  Future<void> buy(String symbol) async {
    if (tradeInProgress) return;
    setState(() {
      tradeInProgress = true;
      tradeError = null;
      tradeSuccess = null;
    });
    try {
      final cost = estimatedCost;
      if (cost > balance) {
        setState(() {
          tradeError = 'Solde insuffisant';
          tradeInProgress = false;
        });
        return;
      }
      // await _portfolioService.buyStock(symbol, tradeQuantity);
      await _loadTradingInfo(symbol);
      setState(() {
        tradeSuccess = 'Achat réussi : $tradeQuantity x $symbol';
        tradeInProgress = false;
      });
    } catch (e) {
      setState(() {
        tradeError = 'Erreur lors de l\'achat: $e';
        tradeInProgress = false;
      });
    }
  }

  Future<void> sell(String symbol) async {
    if (tradeInProgress) return;
    setState(() {
      tradeInProgress = true;
      tradeError = null;
      tradeSuccess = null;
    });
    try {
      if (tradeQuantity > ownedQuantity) {
        setState(() {
          tradeError = 'Quantité insuffisante en portefeuille';
          tradeInProgress = false;
        });
        return;
      }
      // await _portfolioService.sellStock(symbol, tradeQuantity);
      await _loadTradingInfo(symbol);
      setState(() {
        tradeSuccess = 'Vente réussie : $tradeQuantity x $symbol';
        tradeInProgress = false;
      });
    } catch (e) {
      setState(() {
        tradeError = 'Erreur lors de la vente: $e';
        tradeInProgress = false;
      });
    }
  }
}