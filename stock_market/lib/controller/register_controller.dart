import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_market/Database/User_db.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/model/User.dart';

class RegisterController extends ControllerMVC {
  factory RegisterController() => _this ??= RegisterController._();
  RegisterController._();
  static RegisterController? _this;

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  bool isLoading = false;

  User? currentUser;

  void updateName(String value) {
    name = value;
    if (nameError != null) nameError = _validateName(value);
    setState(() {});
  }

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

  void updateConfirmPassword(String value) {
    confirmPassword = value;
    if (confirmPasswordError != null)
      confirmPasswordError = _validateConfirmPassword(value);
    setState(() {});
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'Please enter your name';
    return null;
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

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  Future<bool> register() async {
    nameError = _validateName(name);
    emailError = _validateEmail(email);
    passwordError = _validatePassword(password);
    confirmPasswordError = _validateConfirmPassword(confirmPassword);
    final normalizedEmail = email.trim().toLowerCase();
    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      setState(() {});
      return false;
    }

    isLoading = true;
    setState(() {});

    try {
      final exists = await UserDB.emailExists(normalizedEmail);
      print('Email exists: $exists');
      if (exists) {
        isLoading = false;
        emailError = 'Trrrrrrrrrrrrrrrrrhis email is already registered';
        setState(() {});
        return false;
      }
      final userId = await UserDB.registerUser(
        name.trim(),
        normalizedEmail,
        password,
      );

      await SessionManager.saveSession(
        userId: userId.toString(),
        username: name,
        email: normalizedEmail,
      );

      isLoading = false;
      setState(() {});

      return true;
    } on DatabaseException catch (e) {
      // Fallback safety net: catches a duplicate-email race if it
      // somehow slips past the emailExists check above.
      isLoading = false;
      if (e.isUniqueConstraintError()) {
        emailError = 'This email is already registered vvvvvvvvvvvv' ;
      } else {
        print(e);
      }
      setState(() {});
      return false;
    } catch (e) {
      isLoading = false;
      setState(() {});
      print(e);
      return false;
    }
  }
}
