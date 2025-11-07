import 'package:floodmonitoring/pages/dashboard.dart';
import 'package:floodmonitoring/pages/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/' : (context) => Dashboard(),
      '/map' : (context) => Map(),



    },
  ));
}
