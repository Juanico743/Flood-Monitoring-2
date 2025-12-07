
import 'package:flexible_polyline_dart/flutter_flexible_polyline.dart';
import 'package:flexible_polyline_dart/latlngz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'global.dart';

class PolylineService {
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng destination) async {
    final url =
        "https://router.hereapi.com/v8/routes"
        "?transportMode=car"
        "&origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&return=polyline,summary"
        "&apikey=$hereAPIKey";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      print("HERE ERROR: ${res.body}");
      return [];
    }

    final body = jsonDecode(res.body);
    final poly = body['routes']?[0]?['sections']?[0]?['polyline'];
    if (poly == null) return [];

    final List<LatLngZ> decodedPoints = FlexiblePolyline.decode(poly);

    final points = decodedPoints
        .map((p) => LatLng(p.lat, p.lng)) // <-- use lat & lng
        .toList();

    return points;
  }
}
