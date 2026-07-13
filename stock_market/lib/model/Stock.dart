class Stock {
  final String id;
  final String userId;
  final String symbol;
  final double price;
  final int country;
  final double changePercent;
  final String updatedAt;

  Stock({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.price,
    required this.country,
    required this.changePercent,
    required this.updatedAt,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'symbol': symbol,
      'price': price,
      'country': country,
      'changePercent': changePercent,
      'updatedAt': updatedAt,
    };
}

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map['id'],
      userId: map['user_id'],
      symbol: map['symbol'],
      price: map['price'],
      country: map['country'],
      changePercent: map['changePercent'],
      updatedAt: map['updatedAt'],
    );
  }
}
