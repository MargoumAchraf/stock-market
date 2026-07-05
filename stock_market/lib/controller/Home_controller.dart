import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/Database/User_db.dart';
import 'package:stock_market/model/SessionManager.dart';
import 'package:stock_market/model/User.dart';

class HomeController extends ControllerMVC {
  factory HomeController() => _this ??= HomeController._();
  HomeController._();
  static HomeController? _this;

}