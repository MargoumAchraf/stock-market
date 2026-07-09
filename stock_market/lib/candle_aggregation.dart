import 'package:interactive_chart/interactive_chart.dart';

enum Timeframe { day, week, month }

/// Aggregates a list of daily [CandleData] (assumed chronological, oldest->newest)
/// into weekly or monthly OHLC candles. Returns the input unchanged for [Timeframe.day].
List<CandleData> aggregateCandles(List<CandleData> daily, Timeframe timeframe) {
  if (timeframe == Timeframe.day || daily.isEmpty) return daily;

  final List<CandleData> result = [];
  String? currentBucketKey;
  double? open, high, low, close;
  double volume = 0;
  int? bucketTimestamp;

  for (final c in daily) {
    final date = DateTime.fromMillisecondsSinceEpoch(c.timestamp!, isUtc: true);
    final key = _bucketKey(date, timeframe);

    if (key != currentBucketKey) {
      if (currentBucketKey != null) {
        result.add(CandleData(
          timestamp: bucketTimestamp!,
          open: open!,
          high: high!,
          low: low!,
          close: close!,
          volume: volume,
        ));
      }
      currentBucketKey = key;
      bucketTimestamp = c.timestamp;
      open = c.open;
      high = c.high;
      low = c.low;
      close = c.close;
      volume = c.volume ?? 0;
    } else {
      high = high! > c.high! ? high : c.high;
      low = low! < c.low! ? low : c.low;
      close = c.close;
      volume += c.volume ?? 0;
    }
  }

  if (currentBucketKey != null) {
    result.add(CandleData(
      timestamp: bucketTimestamp!,
      open: open!,
      high: high!,
      low: low!,
      close: close!,
      volume: volume,
    ));
  }

  return result;
}

String _bucketKey(DateTime date, Timeframe timeframe) {
  switch (timeframe) {
    case Timeframe.day:
      return '${date.year}-${date.month}-${date.day}';
    case Timeframe.week:
      final woy = _weekOfYear(date);
      return '${date.year}-W$woy';
    case Timeframe.month:
      return '${date.year}-${date.month}';
  }
}

int _weekOfYear(DateTime date) {
  final startOfYear = DateTime.utc(date.year, 1, 1);
  final days = date.difference(startOfYear).inDays;
  return ((days + startOfYear.weekday - 1) / 7).floor() + 1;
}