import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double distance = 0.0;
  Timer? timer;

  // Replace with your actual Blynk Auth Token
  final String blynkToken = "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc";

  // Fetch distance value from Blynk Cloud
  Future<void> fetchDistance() async {
    try {
      final url = Uri.parse(
        'https://blynk.cloud/external/api/get?token=$blynkToken&pin=V0',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Try to parse the response body (which might be plain text or JSON)
        final body = response.body.trim();
        final newValue = double.tryParse(body);

        if (newValue != null) {
          setState(() {
            distance = newValue;
          });
        } else {
          print("Invalid data from Blynk: $body");
        }
      } else {
        print("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void startDistanceUpdater() {
    // Call fetchDistance every second
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchDistance();
    });
  }

  @override
  void initState() {
    super.initState();
    startDistanceUpdater();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Flood Level Monitor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                const Text(
                  'Distance Measurement:',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${distance.toStringAsFixed(2)} cm',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Location: '
                    ),

                    Text(
                      'Ortigas Ave Sensor #1',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Last Update: '
                    ),

                    Text(
                      '12:34 AM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Status: '
                    ),

                    Text(
                      'Safe', //Safe/Warning/Danger
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
