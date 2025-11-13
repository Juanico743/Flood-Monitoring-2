import 'dart:convert';
import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/time.dart';
import 'package:http/http.dart' as http;




final List<Map<String, dynamic>> vehicleFloodThresholds = [
  {
    "vehicle": "Motorcycle",
    "safeRange_cm": [0.0, 20.0],       // safely passable
    "warningRange_cm": [20.1, 50.0],   // water may touch lower parts
    "dangerRange_cm": [50.1, double.infinity], // motorcycle can submerge
  },
  {
    "vehicle": "Car",
    "safeRange_cm": [0.0, 15.0],       // safely passable
    "warningRange_cm": [15.1, 30.0],   // water may touch engine
    "dangerRange_cm": [30.1, double.infinity], // car can be submerged
  },
  {
    "vehicle": "Truck",
    "safeRange_cm": [0.0, 40.0],       // safely passable
    "warningRange_cm": [40.1, 60.0],   // water may reach lower chassis
    "dangerRange_cm": [60.1, double.infinity], // truck can submerge
  },
];

class BlynkService {
  /// Fetches the distance value from Blynk Cloud for a given sensor token
  Future<Map<String, dynamic>> fetchDistance(String token) async {
    try {
      final url = Uri.parse(
        'https://blynk.cloud/external/api/get?token=$token&pin=V0',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trim();
        final newValue = double.tryParse(body);

        if (newValue != null) {
          final status = getStatusText(newValue);

          // Include current time
          final lastUpdate = getCurrentTime();

          return {
            "distance": newValue,
            "status": status,
            "lastUpdate": lastUpdate,
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
        "lastUpdate": getCurrentTime(),
      };
    }
  }


  /// Determines the status based on distance value
  String getStatusText(double distanceCm) {
    final vehicleThreshold = vehicleFloodThresholds.firstWhere(
          (v) => v["vehicle"] == selectedVehicle,
      orElse: () => vehicleFloodThresholds[0], // fallback
    );

    if (distanceCm <= vehicleThreshold["safeRange_cm"][1]) {
      return 'Safe';
    } else if (distanceCm <= vehicleThreshold["warningRange_cm"][1]) {
      return 'Warning';
    } else {
      return 'Danger';
    }
  }
}





