import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep the app in immersive mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize your connection here
  // Example: await initializeSensorConnection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Level Monitoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Dashboard(),
      routes: {
        '/dashboard': (context) => const Dashboard(),
        // Add more pages later if needed
      },
    );
  }
}
