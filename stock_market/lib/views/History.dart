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

class HistoryView extends StateMVC<HistoryPage> {
  HistoryView() : super(HistoryController());
  HistoryController get con => controller as HistoryController;

  // --- Local UI-only trade state (no controller logic) ---


  @override
  void initState() {
    super.initState();
    con.loadData(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(scaffoldBackgroundColor: const Color(0xFF121212)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.symbol),
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
      candles: con.displayData.reversed.toList(),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white70),
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
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.white70),
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
                  onPressed: () async {
                    await con.buy(widget.symbol);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Acheter',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Vendre',
                      style: TextStyle(color: Colors.white)),
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
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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