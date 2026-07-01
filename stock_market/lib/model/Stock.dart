class Stock {
  final String symbol;
  final String name;
  double currentPrice;
  DateTime lastUpdated;
  double? previousClose; // for computing daily % change

  Stock({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.lastUpdated,
    this.previousClose,
  });
}
