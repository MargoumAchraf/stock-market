class User {
  final String id;
  final String username;
  final String email;
  final double balance;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.balance,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'balance': balance,
    'createdAt': createdAt,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      balance: json['balance'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

}
