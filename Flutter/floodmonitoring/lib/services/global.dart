

import 'package:flutter/material.dart';

String serverUri = "http://192.168.1.8:8000";


const String googleMapAPI = "AIzaSyC4O5JIbDyCnarQiUc0eQmhbQwel186NHw";


String selectedVehicle = "Motorcycle";


final List<Map<String, dynamic>> floodStatuses = [
  {
    "text": "Safe",
    "color": const Color(0xFF4CAF50), // Green
    "icon": Icons.check_circle,
    "message": "No flooding detected."
  },
  {
    "text": "Warning",
    "color": const Color(0xFFFFC107), // Yellow
    "icon": Icons.warning_amber_rounded,
    "message": "Rising water level, stay alert."
  },
  {
    "text": "Danger",
    "color": const Color(0xFFF44336), // Red
    "icon": Icons.error,
    "message": "Flooding likely, move to higher ground."
  },
];



