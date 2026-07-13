import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:interactive_chart/interactive_chart.dart';
import 'package:intl/intl.dart';

Future<List<CandleData>> fetchCandlesFromApi({
  required String symbol,
  String baseUrl = 'http://mttoka-ip-154-144-252-170.tunnelmole.net',
}) async {
  DateTime now = DateTime.now();
  DateTime lastYear = DateTime(now.year - 1, now.month, now.day);
  String endDate = DateFormat('yyyy-MM-dd').format(now);
  String startDate = DateFormat('yyyy-MM-dd').format(lastYear);
  final uri = Uri.parse(
    '$baseUrl/hist/$symbol?start_date=$startDate&end_date=$endDate',
  );
  print('Fetching candles for $symbol from $startDate to $endDate...');

  final response = await http.get(uri);
  print('Fetching candles for $symbol from $uri: ${response.statusCode}');
  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load candles for $symbol: ${response.statusCode} ${response.reasonPhrase}',
    );
  }

  return parseCandlesFromJson(response.body);
}

List<CandleData> parseCandlesFromJson(String jsonString) {
  final Map<String, dynamic> decoded = json.decode(jsonString);
  final List<dynamic> values = decoded['values'] as List<dynamic>;

  final chronological = values.reversed.toList();

  final List<CandleData> candles = [];
  double? prevClose;

  for (final item in chronological) {
    final double close = (item['close'] as num).toDouble();
    final DateTime date = _parseGmtDate(item['date'] as String);

    final double open = prevClose ?? close;
    final double high = open > close ? open : close;
    final double low = open < close ? open : close;

    candles.add(
      CandleData(
        timestamp: date.millisecondsSinceEpoch,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 0,
      ),
    );

    prevClose = close;
  }

  return candles;
}

DateTime _parseGmtDate(String rfc1123) {
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  final parts = rfc1123.split(' ');
  final day = int.parse(parts[1]);
  final month = months[parts[2]]!;
  final year = int.parse(parts[3]);
  final timeParts = parts[4].split(':').map(int.parse).toList();

  return DateTime.utc(year, month, day, timeParts[0], timeParts[1], timeParts[2]);
}