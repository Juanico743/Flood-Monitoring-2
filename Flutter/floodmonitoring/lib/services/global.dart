

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

String serverUri = "http://192.168.1.8:8000";


const String googleMapAPI = "AIzaSyAMamxCz-N-wiGSq4-DfVpD9zOpP_GZ_9o";

const hereAPIKey = "lDESSEtXqqRgEcvHK6IIvID7oKO5yR5AJh2Et7ADPAI";
const String mapboxAPI = "pk.eyJ1IjoidmluY2VudGplcnJ5anVhbmljbyIsImEiOiJjbWlyanl6MDMwMmRuM2NzZnAzZWRtMGRzIn0.8zbipe-6rXc1C5u0fP15aQ";


Position? currentPosition;

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



