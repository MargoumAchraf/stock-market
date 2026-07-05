import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/Database/User_db.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/model/User.dart';

class LoginController extends ControllerMVC {
  factory LoginController() => _this ??= LoginController._();
  LoginController._();
  static LoginController? _this;

  String email = '';
  String password = '';
  String? emailError;
  String? passwordError;

  bool isLoading = false;

  User? currentUser;

  void updateEmail(String value) {
    email = value;
    if (emailError != null) emailError = _validateEmail(value);
    setState(() {});
  }

  void updatePassword(String value) {
    password = value;
    if (passwordError != null) passwordError = _validatePassword(value);
    setState(() {});
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  Future<bool> login() async {
    emailError = _validateEmail(email);
    passwordError = _validatePassword(password);
    if (emailError != null || passwordError != null) {
      setState(() {});
      return false;
    }
    try {
      final user = await UserDB.loginUser(email, password);

      if (user == null) {
        isLoading = false;
        passwordError = 'Invalid email or password';
        setState(() {});
        return false;
      }

      await SessionManager.saveSession(
        userId: user['id'] as String, // change to `as String` if id is TEXT/UUID
        username: user['username'] as String,
        email: user['email'] as String,
      );

      isLoading = false;
      setState(() {});
      return true;
    } catch (e) {
      isLoading = false;
      print(e);
      setState(() {});
      return false;
    }
  }
}
