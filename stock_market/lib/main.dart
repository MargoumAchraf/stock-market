import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:stock_market/mock_data.dart';
import 'candle_aggregation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<CandleData> _dailyData = []; // raw data from API, always daily
  List<CandleData> _displayData = []; // what's actually shown (day/week/month)
  Timeframe _timeframe = Timeframe.day;
  bool _darkMode = true;
  bool _showAverage = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final candles = await fetchCandlesFromApi(symbol: 'AAME');
      setState(() {
        _dailyData = candles;
        _loading = false;
      });
      _applyTimeframe();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyTimeframe() {
    setState(() {
      _displayData = aggregateCandles(_dailyData, _timeframe);
      if (_showAverage) {
        _computeTrendLines();
      } else {
        _removeTrendLines();
      }
    });
  }

  void _onTimeframeChanged(Timeframe tf) {
    if (tf == _timeframe) return;
    _timeframe = tf;
    _applyTimeframe();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Interactive Chart Demo"),
          actions: [
            IconButton(
              icon: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _darkMode = !_darkMode),
            ),
            IconButton(
              icon: Icon(
                _showAverage ? Icons.show_chart : Icons.bar_chart_outlined,
              ),
              onPressed: () {
                setState(() => _showAverage = !_showAverage);
                if (_showAverage) {
                  _computeTrendLines();
                } else {
                  _removeTrendLines();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTimeframeSelector(),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Failed to load data:\n$_error',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _displayData.isEmpty
                            ? const Center(child: Text('No data'))
                            : InteractiveChart(
                                key: ValueKey(_timeframe),
                                candles: _displayData,
                                style: ChartStyle(
                                  priceGainColor: const Color(0xFF26A69A),
                                  priceLossColor: const Color(0xFFEF5350),
                                  volumeColor: Colors.transparent,
                                  priceGridLineColor:
                                      Colors.white.withOpacity(0.08),
                                  priceLabelStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  timeLabelStyle: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  selectionHighlightColor:
                                      Colors.white.withOpacity(0.08),
                                  overlayBackgroundColor:
                                      const Color(0xFF1E1E1E).withOpacity(0.95),
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
                              ),
              ),
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
      selected: {_timeframe},
      onSelectionChanged: (selection) => _onTimeframeChanged(selection.first),
    );
  }

  void _computeTrendLines() {
    final ma7 = CandleData.computeMA(_displayData, 7);
    final ma30 = CandleData.computeMA(_displayData, 30);
    final ma90 = CandleData.computeMA(_displayData, 90);

    for (int i = 0; i < _displayData.length; i++) {
      _displayData[i].trends = [ma7[i], ma30[i], ma90[i]];
    }
  }

  void _removeTrendLines() {
    for (final data in _displayData) {
      data.trends = [];
    }
  }
}