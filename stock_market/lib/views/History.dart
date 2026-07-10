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

  @override
  void initState() {
    super.initState();
    con.loadData(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: con.darkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Interactive Chart Demo"),
          actions: [
            IconButton(
              icon: Icon(con.darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: con.toggleDarkMode,
            ),
            IconButton(
              icon: Icon(
                con.showAverage ? Icons.show_chart : Icons.bar_chart_outlined,
              ),
              onPressed: con.toggleAverage,
            ),
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTimeframeSelector(),
              const SizedBox(height: 12),
              Expanded(child: _buildChartArea()),
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
            ElevatedButton(onPressed: () => con.loadData(widget.symbol), child: const Text('Retry')),
          ],
        ),
      );
    }
    if (con.displayData.isEmpty) return const Center(child: Text('No data'));

    return InteractiveChart(
      key: ValueKey(con.timeframe),
      candles: con.displayData,
      style: ChartStyle(
        priceGainColor: const Color(0xFF26A69A),
        priceLossColor: const Color(0xFFEF5350),
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
}
