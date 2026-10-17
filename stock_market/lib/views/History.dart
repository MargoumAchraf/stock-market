import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:stock_market/controller/History_controller.dart';
import 'package:stock_market/service/candle_aggregation.dart';

class HistoryPage extends StatefulWidget {
  final String symbol;
  const HistoryPage({Key? key, required this.symbol}) : super(key: key);
  @override
  State createState() => HistoryView();
}

class _TradeInfo {
  final int quantity;
  final double unitPrice;
  final double total;
  const _TradeInfo({
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class HistoryView extends StateMVC<HistoryPage> {
  HistoryView() : super(HistoryController());
  HistoryController get con => controller as HistoryController;

  // Cache the reversed list so the chart is not rebuilt with a new list
  // on every price update.
  List<CandleData>? _sourceData;
  List<CandleData> _chartCandles = [];

  @override
  void initState() {
    super.initState();
    con.loadData(widget.symbol); // also starts live polling
  }

  @override
  void dispose() {
    con.stopPolling(); // controller is a singleton, so stop it here
    super.dispose();
  }

  List<CandleData> _candlesForChart() {
    if (!identical(_sourceData, con.displayData)) {
      _sourceData = con.displayData;
      _chartCandles = con.displayData.reversed.toList();
    }
    return _chartCandles;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(scaffoldBackgroundColor: const Color(0xFF121212)),
      child: Scaffold(
        appBar: AppBar(
          title: _buildAppBarTitle(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTimeframeSelector(),
              const SizedBox(height: 12),
              Expanded(child: _buildChartArea()),
              const SizedBox(height: 16),
              _buildTradingPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    final price = con.livePrice;
    final up = con.priceUp;
    final Color priceColor = up == null
        ? Colors.black87
        : (up ? const Color(0xFF26A69A) : const Color(0xFFEF5350));

    Widget rateWidget;
    if (price != null) {
      rateWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: up == null
                ? null
                : Icon(
                    up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: priceColor,
                    size: 28,
                  ),
          ),
          SizedBox(
            width: 90, // fixed width so the title never jumps
            child: Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(
                color: priceColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      );
    } else if (con.liveError != null) {
      rateWidget = Expanded(
        child: Text(
          'rate: ${con.liveError}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 11,
          ),
        ),
      );
    } else {
      rateWidget = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      children: [
        Text(widget.symbol),
        const SizedBox(width: 12),
        rateWidget,
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    return SegmentedButton<Timeframe>(
      segments: const [
        ButtonSegment(value: Timeframe.day, label: Text('Day')),
        ButtonSegment(value: Timeframe.week, label: Text('Week')),
        ButtonSegment(value: Timeframe.month, label: Text('Month')),
      ],
      selected: {con.timeframe},
      onSelectionChanged: (selection) =>
          con.onTimeframeChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange.shade800,
        selectedBackgroundColor: Colors.orange.shade800,
        selectedForegroundColor: Colors.white,
        side: BorderSide(color: Colors.orange.shade800),
      ),
    );
  }

  Widget _buildChartArea() {
    if (con.loading) return const Center(child: CircularProgressIndicator());
    if (con.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load data:\n${con.error}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => con.loadData(widget.symbol),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (con.displayData.isEmpty) return const Center(child: Text('No data'));

    return InteractiveChart(
      key: ValueKey(con.timeframe),
      candles: _candlesForChart(),
      style: ChartStyle(
        priceLossColor: const Color(0xFFEF5350),
        priceGainColor: const Color(0xFF26A69A),
        volumeColor: Colors.transparent,
        priceGridLineColor: Colors.white.withOpacity(0.08),
        priceLabelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        timeLabelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
        selectionHighlightColor: Colors.white.withOpacity(0.08),
        overlayBackgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
        trendLineStyles: [
          Paint()
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = Colors.amber,
          Paint()
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = Colors.blueAccent,
          Paint()
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = Colors.purpleAccent,
        ],
      ),
    );
  }

  _TradeInfo _readTradeInfo() {
    return _TradeInfo(
      quantity: con.tradeQuantity,
      unitPrice: con.currentPrice,
      total: con.estimatedCost,
    );
  }

  Future<void> _handleTrade({required bool isBuy}) async {
    // Freeze the price while the dialog is open, so the dialog and
    // buy()/sell() use exactly the same price.
    con.stopPolling();

    final confirmed = await _confirmTrade(isBuy: isBuy);

    if (!mounted) return;

    if (confirmed) {
      if (isBuy) {
        await con.buy(widget.symbol);
      } else {
        await con.sell(widget.symbol);
      }
      if (!mounted) return;
      con.resetQuantity();
    }

    con.startPolling(widget.symbol);
    setState(() {});
  }

  Future<bool> _confirmTrade({required bool isBuy}) async {
    final info = _readTradeInfo();
    final actionLabel = isBuy ? 'Acheter' : 'Vendre';
    final actionColor =
        isBuy ? const Color(0xFF26A69A) : const Color(0xFFEF5350);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirmer : $actionLabel',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('Symbole', widget.symbol),
            _dialogRow('Quantité', '${info.quantity}'),
            _dialogRow(
              'Prix unitaire',
              '\$${info.unitPrice.toStringAsFixed(2)}',
            ),
            const Divider(color: Colors.white24, height: 24),
            _dialogRow(
              'Total',
              '\$${info.total.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _dialogRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingPanel() {
    if (con.loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn(
                'Prix actuel',
                '\$${con.currentPrice.toStringAsFixed(2)}',
              ),
              if (con.livePrice != null)
                Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: Color(0xFF26A69A)),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF26A69A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white70,
                ),
                onPressed: con.decrementQuantity,
              ),
              Text(
                '${con.tradeQuantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                ),
                onPressed: con.incrementQuantity,
              ),
              const SizedBox(width: 12),
              Text(
                'Total: \$${con.estimatedCost.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleTrade(isBuy: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Acheter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleTrade(isBuy: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Vendre',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}