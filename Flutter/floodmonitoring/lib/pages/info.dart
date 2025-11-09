import 'dart:async';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';

import 'package:floodmonitoring/services/flood_level.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {

  final blynk = BlynkService();
  Map<String, dynamic> data = {
    "distance": 0.0,
    "status": "Loading...",
    "lastUpdate": "00:00 AM"
  };

  Timer? _timer;


  @override
  void initState() {
    super.initState();
    fetchData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void fetchData() async {
    final result = await blynk.fetchDistance();

    setState(() {
      data = result;
    });

    // print("Distance: ${result['distance']}");
    // print("Status: ${result['status']}");
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
                  '${data!['distance']}cm',
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
                      '${data!['lastUpdate']}',
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
                      '${data!['status']}',
                      style: TextStyle(
                        color: data!['status'] == 'Safe'
                            ? color_safe
                            : data!['status'] == 'Warning'
                            ? color_warning
                            : data!['status'] == 'Danger'
                            ? color_danger
                            : Colors.black,
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
