import 'dart:convert';
import 'package:floodmonitoring/services/time.dart';
import 'package:http/http.dart' as http;

class BlynkService {
  final String blynkToken = "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc";

  /// Fetches the distance value from Blynk Cloud
  /// Returns a map like: {"distance": 168.0, "status": "Warning"}
  Future<Map<String, dynamic>> fetchDistance() async {
    try {
      final url = Uri.parse(
        'https://blynk.cloud/external/api/get?token=$blynkToken&pin=V0',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final newValue = double.tryParse(body);

        if (newValue != null) {
          final status = getStatusText(newValue);

          // Include current time
          final lastUpdate = getCurrentTime(); // from time.dart

          return {
            "distance": newValue,
            "status": status,
            "lastUpdate": lastUpdate,  // 👈 added here
          };
        } else {
          throw Exception("Invalid data format: $body");
        }
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching distance: $e");
      return {
        "distance": null,
        "status": "Error",
        "lastUpdate": getCurrentTime(), // fallback time
      };
    }
  }

  /// Determines the status based on distance value
  String getStatusText(double value) {
    if (value >= 175) {
      return 'Safe';
    } else if (value >= 125 && value <= 174) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }
}