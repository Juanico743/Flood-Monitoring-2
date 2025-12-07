import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'global.dart'; // contains mapboxAPI token

class PolylineService {
  /// Fetch a route that follows roads and avoids zones
  static Future<List<LatLng>> getSafeRoute(
      LatLng origin,
      LatLng destination,
      List<Map<String, Object>> avoidZones,
      {int maxAttempts = 15}) async {

    List<LatLng> currentRoute = await _fetchMapboxRoute(origin, destination);
    if (avoidZones.isEmpty) return currentRoute;

    int attempt = 0;
    double detourMultiplier = 1.0;

    while (_routeIntersectsZones(currentRoute, avoidZones) && attempt < maxAttempts) {
      // Find first zone intersecting
      final intersectZone = _firstIntersectedZone(currentRoute, avoidZones);
      if (intersectZone == null) break;

      // Generate a detour far enough from the zone
      final detour = _generateFarDetour(
        intersectZone['position'] as LatLng,
        intersectZone['radius'] as double,
        detourMultiplier,
      );

      // Request new route via waypoint
      currentRoute = await _fetchMapboxRoute(origin, destination, waypoint: detour);

      // Increase distance for next attempt if still blocked
      detourMultiplier += 1.5;
      attempt++;
    }

    return currentRoute;
  }

  static bool _routeIntersectsZones(List<LatLng> route, List<Map<String, Object>> zones) {
    for (var zone in zones) {
      final center = zone['position'] as LatLng;
      final radius = zone['radius'] as double;
      for (var point in route) {
        if (_distanceMeters(point, center) <= radius) return true;
      }
    }
    return false;
  }

  static Map<String, Object>? _firstIntersectedZone(List<LatLng> route, List<Map<String, Object>> zones) {
    for (var zone in zones) {
      final center = zone['position'] as LatLng;
      final radius = zone['radius'] as double;
      for (var point in route) {
        if (_distanceMeters(point, center) <= radius) return zone;
      }
    }
    return null;
  }

  /// Generate a detour that moves farther away from the zone based on multiplier
  static LatLng _generateFarDetour(LatLng center, double radius, double multiplier) {
    final offsetMeters = radius * 2 * multiplier; // increase distance each attempt
    final deltaLat = offsetMeters / 111320;
    final deltaLng = offsetMeters / (111320 * cos(center.latitude * pi / 180));

    // Randomize the direction to increase chance of finding a safe road
    final rand = Random();
    final latSign = rand.nextBool() ? 1 : -1;
    final lngSign = rand.nextBool() ? 1 : -1;

    return LatLng(center.latitude + deltaLat * latSign, center.longitude + deltaLng * lngSign);
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const R = 6371000;
    double dLat = (b.latitude - a.latitude) * pi / 180;
    double dLng = (b.longitude - a.longitude) * pi / 180;
    double h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static Future<List<LatLng>> _fetchMapboxRoute(LatLng origin, LatLng destination, {LatLng? waypoint}) async {
    String coords = "${origin.longitude},${origin.latitude};";
    if (waypoint != null) coords += "${waypoint.longitude},${waypoint.latitude};";
    coords += "${destination.longitude},${destination.latitude}";

    final url = Uri.parse(
        "https://api.mapbox.com/directions/v5/mapbox/driving/$coords"
            "?geometries=polyline&overview=full&access_token=$mapboxAPI"
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final encoded = data['routes']?[0]?['geometry'];
    return encoded == null ? [] : decodePolyline(encoded);
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
