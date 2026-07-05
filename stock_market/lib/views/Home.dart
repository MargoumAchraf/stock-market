

import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:stock_market/controller/Home_controller.dart';
import 'package:stock_market/controller/login_controller.dart';
import 'package:stock_market/views/register.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State createState() => _HomePageState(); // raw `State`, no generic
}

class _HomePageState extends StateMVC<HomePage> {
  _HomePageState() : super(HomeController()) {
    con = controller as HomeController;
  }

  late HomeController con;
}