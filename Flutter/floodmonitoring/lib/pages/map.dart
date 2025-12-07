import 'dart:async';
import 'dart:math';

import 'package:floodmonitoring/services/flood_level.dart';
import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/services/location.dart';
import 'package:floodmonitoring/services/polyline.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';

import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Example location (Antipolo)
  final LatLng _center = const LatLng(14.6255, 121.1245);

  final Set<Marker> _markers = {};

  final blynk = BlynkService();

  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  CameraPosition? _lastPosition;

  bool showDirectionSheet = false;
  bool showSensorSheet = false;
  bool showSensorSettingsSheet = false;
  bool showPinConfirmationSheet = false;

  double directionSheetHeight = 0;
  double sensorSheetHeight = 0;
  double sensorSettingsSheetHeight = 0;
  double pinConfirmationSheetHeight = 0;

  double directionDragOffset = 0;
  double sensorDragOffset = 0;
  double sensorSettingsDragOffset = 0;
  double pinConfirmationDragOffset = 0;

  final GlobalKey directionKey = GlobalKey();
  final GlobalKey sensorKey = GlobalKey();
  final GlobalKey sensorSettingsKey = GlobalKey();
  final GlobalKey pinConfirmKey = GlobalKey();


  bool showAllSensors = true;
  bool showSensorCoverage = true;
  bool showCriticalSensors = false;
  bool showSensorLabels = false;


  bool insideAlertZone = false;
  bool nearAlertZone = false;

  @override
  void initState() {
    super.initState();

      setState(() {
        selectedVehicle = "";
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showVehicleModal();
      });

      fetchDataForAllSensors();
      _loadCurrentLocation();
      _drawAvoidZones();
      //startLocationUpdates();
    }

  Position? _lastUpdatedPosition;
  StreamSubscription<Position>? _positionStream;

  Future<void> _loadCurrentLocation() async {
    Position? position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        currentPosition = position;
      });
      _addUserMarker();
    } else {
      print('Could not get location.');
    }
  }

  void startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // minimum distance in meters to trigger update
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (_lastUpdatedPosition == null) {
        _updatePosition(position);
      } else {
        double distance = Geolocator.distanceBetween(
          _lastUpdatedPosition!.latitude,
          _lastUpdatedPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance >= 5) { // update every 5 meters
          _updatePosition(position);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _updatePosition(Position position) {
    setState(() {
      currentPosition = position;
      _lastUpdatedPosition = position;
    });

    _addUserMarker();

    LatLng userLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    bool inside = isInsideAvoidZone(userLatLng, avoidZones);

    if (inside) {
      print("Position inside restricted area!");
    } else {
      print("Safe: Position outside avoid zones.");
    }

    bool near = isNearAvoidZone(userLatLng, avoidZones);

    if (near) {
      print("Position near restricted area!");
      setState(() {
        nearAlertZone = true;
      });
    } else {
      print("Safe: Position far avoid zones.");
      setState(() {
        nearAlertZone = false;
      });
    }
  }




  Map<String, Map<String, dynamic>> sensors = {
    "sensor_01": {
      "position": const LatLng(14.586897322564798, 121.16926720422056),
      "token": "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc",
      "sensorData": {
        "distance": 0.0,
        "status": "Loading...",
        "lastUpdate": "00:00 AM"
      },
      "weatherData": {
        "temperature": 0.0,
        "description": "Loading...",
        "pressure": 0,
      }
    },
  };

  String? selectedSensorId;

  ///Get Update For Specific Sensor
  Future<void> fetchDataForSensor(String sensorId) async {
    final sensor = sensors[sensorId];
    if (sensor == null) return;

    final token = sensor['token'];
    final data = await BlynkService().fetchDistance(token);

    // Update the sensor's data
    setState(() {
      sensors[sensorId]!['sensorData'] = data;
    });
  }

  ///Get Update For All Sensors
  Future<void> fetchDataForAllSensors() async {
    print("fetchDataForAllSensors");
    // Create a list of futures for all sensors
    List<Future<void>> futures = [];

    sensors.forEach((sensorId, sensor) {
      final token = sensor['token'];

      // Add a future that fetches and updates this sensor
      futures.add(BlynkService().fetchDistance(token).then((data) {
        setState(() {
          sensors[sensorId]!['sensorData'] = data;
        });
      }));
    });

    await Future.wait(futures);
  }



  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    setState(() async {
      _markers.clear(); // Optional: clear previous markers

      // Load custom sensor marker image once
      final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), // size of your sensor image
        'assets/images/sensor_location.png',
      );

      sensors.forEach((id, sensor) {
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: sensor['position'],
            icon: sensorIcon, // <-- use custom sensor image
            infoWindow: showSensorLabels ? InfoWindow(title: id) : InfoWindow.noText,
            anchor: const Offset(0.5, 0.5),
              onTap: () => _onSensorTap(id, sensor),
          ),
        );
      });
    });
  }



  LatLng _offsetPosition(LatLng original, double offsetInDegrees) {
    return LatLng(original.latitude - offsetInDegrees, original.longitude);
  }

  ///Sensor Gets Tapped
  Future<void> _onSensorTap(String id, Map<String, dynamic> sensor) async {
    final LatLng sensorPos = sensor['position'];
    final LatLng offsetTarget = _offsetPosition(sensorPos, 0.0090);

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: offsetTarget,
          zoom: 15,
        ),
      ),
    );

    await fetchDataForSensor(id);

    setState(() {
      selectedSensorId = id;
      showDirectionSheet = false;
      showSensorSettingsSheet = false;

      cancelPinSelection();

      showSensorSheet = true;
    });

    // Update circle for the selected sensor
    if (showSensorCoverage) {
      _circles.removeWhere((c) => c.circleId.value.startsWith(id));
      _circles.add(
        Circle(
          circleId: CircleId('${id}_circle'),
          center: sensor['position'],
          radius: 200,
          strokeWidth: 2,
          strokeColor: _getStatusColor(sensor['sensorData']['status']),
          fillColor: _getStatusColor(sensor['sensorData']['status']).withOpacity(0.3),
        ),
      );
    }

  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Safe":
        return color_safe;
      case "Warning":
        return color_warning;
      case "Danger":
        return color_danger;
      default:
        return Colors.black;
    }
  }

  /// Add Users Marker
  void _addUserMarker() async {
    if (currentPosition == null) return;

    final userLatLng = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    // Load custom image as marker
    final BitmapDescriptor userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)), // size of your pin
      'assets/images/user_location.png',
    );

    setState(() {
      // Remove old user marker
      _markers.removeWhere((m) => m.markerId.value == 'user');

      // Remove old circles (optional)
      _circles.removeWhere((c) =>
      c.circleId.value == 'user_small' || c.circleId.value == 'user_medium');

      // Add user marker with custom image
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          icon: userIcon, // <-- custom image
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }



  void _refreshSensorMarkers() async {
    final BitmapDescriptor sensorIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/sensor_location.png',
    );

    setState(() {
      // Remove all sensors first
      _markers.removeWhere((m) => sensors.containsKey(m.markerId.value));

      // If showAllSensors == false → stop here (no markers added)
      if (!showAllSensors) return;

      // Otherwise add all sensors again
      sensors.forEach((id, sensor) {
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: sensor['position'],
            icon: sensorIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: showSensorLabels ? InfoWindow(title: id) : InfoWindow.noText,
            onTap: () => _onSensorTap(id, sensor),
          ),
        );
      });
    });
  }


  /// Locate user
  void _goToUser() async {
    if (currentPosition == null) return;

    final userLatLng = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userLatLng,
          zoom: 17, // set desired zoom level
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  bool _isZoomedTilted = false;

  /// Reset map orientation (bearing & tilt)
  void _onCameraMove(CameraPosition position) {
    _lastPosition = position;
  }

  void _resetOrientation() async {
    if (_lastPosition == null) return;

    // Step 1: Reset bearing to 0
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _lastPosition!.target,
          zoom: _lastPosition!.zoom, // keep current zoom
          tilt: 0, // reset tilt
          bearing: 0, // reset orientation
        ),
      ),
    );

    // Step 2: Apply zoom & tilt if toggled
    if (!_isZoomedTilted) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _lastPosition!.target,
            zoom: 18,
            tilt: 80,
            bearing: 0,
          ),
        ),
      );
    } else {
      // Optional: Reset zoom back to normal
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _lastPosition!.target,
            zoom: 17,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }

    _isZoomedTilted = !_isZoomedTilted;
  }


  void showAppToast(BuildContext context, {required String message, required String status, double? distance,}) {Color bgColor; IconData icon;

    switch (status.toLowerCase()) {
      case 'safe':
        bgColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'warning':
        bgColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case 'danger':
        bgColor = Colors.red;
        icon = Icons.dangerous_rounded;
        break;
      default:
        bgColor = Colors.grey;
        icon = Icons.info_outline;
    }

    final displayMessage = distance != null
        ? "$message (Distance: ${distance.toStringAsFixed(1)} cm)"
        : message;

    DelightToastBar(
      builder: (context) => ToastCard(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(
          displayMessage,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        color: bgColor,
      ),
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }

  LatLng? savedPinPosition;        // the CURRENT official pin
  Marker? savedPinMarker;          // marker for the official pin

  LatLng? tappedPosition;          // temporary pin when user taps on map
  Marker? tappedMarker;

  void _onMapTap(LatLng position) async {
    //print("Tapped: ${position.latitude}, ${position.longitude}");
    print("Tapped: ${savedPinPosition?.latitude}, ${savedPinPosition?.longitude}");
    print("User: ${currentPosition!.latitude}, ${currentPosition!.longitude}");

    final BitmapDescriptor pinIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/selected_location.png',
    );

    setState(() {
      // Remove previous tapped marker
      if (tappedMarker != null) _markers.remove(tappedMarker);

      // Add new tapped marker
      tappedMarker = Marker(
        markerId: const MarkerId('tapped_pin'),
        position: position,
        icon: pinIcon,
        anchor: const Offset(0.5, 1.0),
      );
      _markers.add(tappedMarker!);
      tappedPosition = position;

      // Show confirmation sheet
      showPinConfirmationSheet = true;
      showDirectionSheet = false;
      showSensorSheet = false;
      showSensorSettingsSheet = false;
    });

    // Draw polyline from user to tapped pin
    if (currentPosition != null) {
      _drawRoute(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        //position,
        savedPinPosition!,
      );
    }

    // LatLng tap = tappedPosition!;
    // bool inside = isInsideAvoidZone(tap, avoidZones);
    //
    // if (inside) {
    //   print("Tapped inside restricted area!");
    //   setState(() {
    //     insideAlertZone = true;
    //   });
    // } else {
    //   print("Safe: tapped outside avoid zones.");
    //   setState(() {
    //     insideAlertZone = false;
    //   });
    // }


    Position fakePosition = Position(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );

    _updatePosition(fakePosition);




  }

  void cancelPinSelection() {
    setState(() {
      // Remove temporary tapped pin
      if (tappedMarker != null) {
        _markers.remove(tappedMarker);
      }
      tappedMarker = null;
      tappedPosition = null;
    });

    // Restore saved pin → draw route again
    if (savedPinMarker != null && currentPosition != null) {
      _drawRoute(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
        savedPinMarker!.position,
      );
    } else {
      setState(() {
        _polylines.clear();
      });
    }

    // Hide sheet
    setState(() {
      showPinConfirmationSheet = false;

      // Optional: remove sensor circles
      _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
    });
  }


  Set<Polygon> _polygons = {};
  void _drawAvoidZones() {
    Set<Polygon> polygons = {};

    for (int i = 0; i < avoidZones.length; i++) {
      final zone = avoidZones[i];

      final center = zone["position"] as LatLng;
      final radius = zone["radius"] as double;

      // Convert radius in meters to approximate degrees
      final delta = radius / 111000;

      // Square corners (clockwise)
      final topLeft = LatLng(center.latitude + delta, center.longitude - delta); // A
      final topRight = LatLng(center.latitude + delta, center.longitude + delta); // B
      final bottomRight = LatLng(center.latitude - delta, center.longitude + delta); // C
      final bottomLeft = LatLng(center.latitude - delta, center.longitude - delta); // D

      final points = [topLeft, topRight, bottomRight, bottomLeft, topLeft]; // close the polygon

      polygons.add(Polygon(
        polygonId: PolygonId("avoid_zone_$i"),
        points: points,
        fillColor: Colors.red.withOpacity(0.3),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ));
    }

    setState(() {
      _polygons = polygons;
    });
  }

  bool isInsideAvoidZone(LatLng usersPosition, List<Map<String, dynamic>> avoidZones) {
    for (var zone in avoidZones) {
      LatLng zoneCenter = zone["position"];
      double radius = zone["radius"]; // in meters

      double distance = Geolocator.distanceBetween(
        usersPosition.latitude,
        usersPosition.longitude,
        zoneCenter.latitude,
        zoneCenter.longitude,
      );

      if (distance <= radius) {
        return true; // inside this zone
      }
    }
    return false; // not inside any zone
  }

  bool isNearAvoidZone(LatLng usersPosition, List<Map<String, dynamic>> avoidZones) {
    for (var zone in avoidZones) {
      LatLng zoneCenter = zone["position"];
      double radius = zone["radius"]; // in meters

      double distance = Geolocator.distanceBetween(
        usersPosition.latitude,
        usersPosition.longitude,
        zoneCenter.latitude,
        zoneCenter.longitude,
      );

      if (distance <= radius + 500) {
        return true; // near this zone
      }
    }
    return false; // far any zone
  }

  List<LatLng> _generateCirclePolygon(LatLng center, double radius, int points) {
    List<LatLng> polygonPoints = [];
    final R = 6371000; // Earth radius in meters
    final dRad = radius / R;

    for (int i = 0; i < points; i++) {
      final theta = 2 * pi * i / points;
      final lat = asin(sin(center.latitude * pi / 180) * cos(dRad) +
          cos(center.latitude * pi / 180) * sin(dRad) * cos(theta)) *
          180 /
          pi;
      final lng = center.longitude +
          atan2(sin(theta) * sin(dRad) * cos(center.latitude * pi / 180),
              cos(dRad) - sin(center.latitude * pi / 180) * sin(lat * pi / 180)) *
              180 /
              pi;
      polygonPoints.add(LatLng(lat, lng));
    }

    return polygonPoints;
  }



  final avoidZones = [
    {
      "position": LatLng(14.584075886106824, 121.17304186860613),
      "radius": 100.0,
    }
  ];

  void _drawRoute(LatLng start, LatLng end) async {
    final route = await PolylineService.getRoute(start, end, avoidZones);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: route,
          color: Colors.blue,
          width: 5,
        ),
      );
    });
  }





  void showVehicleModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Question + Description
                    const Text(
                      "Which vehicle will you use?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Select a vehicle from the options below before continuing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Vehicle options
                    vehicleTile("Motorcycle", "assets/images/icons/motorcycle.png", setState),
                    const SizedBox(height: 10),
                    vehicleTile("Car", "assets/images/icons/car.png", setState),
                    const SizedBox(height: 10),
                    vehicleTile("Truck", "assets/images/icons/truck.png", setState),

                    const SizedBox(height: 20),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color1 ,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (selectedVehicle.isEmpty) {
                            showVehicleErrorToast(context);
                            return;
                          }
                          print("Selected Vehicle: $selectedVehicle");
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "CONFIRM",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

// Vehicle tile widget with selection effect
  Widget vehicleTile(String name, String iconPath, void Function(void Function()) setState) {
    bool isSelected = selectedVehicle == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? color1_2 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 28, height: 28),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showVehicleErrorToast(BuildContext context) {
    DelightToastBar(
      builder: (context) => ToastCard(
        leading: const Icon(Icons.error_outline, color: Colors.red, size: 28),
        title: const Text(
          "Please select a vehicle to continue",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        color: Colors.white, // background white
      ),
      autoDismiss: true,
      snackbarDuration: Durations.extralong4,
    ).show(context);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🚫 Prevents map/buttons from shifting up
      body: Stack(
        children: [
          // 🗺️ MAP
          GoogleMap(
            onMapCreated: (controller) {
              _onMapCreated(controller);

              // Animate zoom after map is ready
              if (currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                      zoom: 17.0, // zoom to 17
                    ),
                  ),
                );
              }
            },
            onTap: _onMapTap,
            onCameraMove: _onCameraMove,
            initialCameraPosition: CameraPosition(
              target: currentPosition != null
                  ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                  : _center,
              zoom: 15.0, // start at 15
            ),
            mapType: MapType.normal,
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
            polygons: _polygons,
            compassEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 🔍 Floating Search Bar (Top)
          // Positioned(
          //   top: 50,
          //   left: 20,
          //   right: 20,
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(30),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.1),
          //           blurRadius: 6,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: TextField(
          //       decoration: InputDecoration(
          //         hintText: 'Search location...',
          //         hintStyle: const TextStyle(color: Colors.grey),
          //         prefixIcon: const Icon(Icons.search, color: Colors.grey),
          //         border: InputBorder.none,
          //         contentPadding: const EdgeInsets.symmetric(vertical: 15),
          //       ),
          //       onSubmitted: (value) {
          //         // TODO: Add search functionality
          //         print("Search: $value");
          //       },
          //     ),
          //   ),
          // ),

          // 📍 Bottom Button Bar

          ///Side Buttons
          Positioned(
            top: 0,
            bottom: 0,
            left: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _goToUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/crosshair.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),


                ElevatedButton(
                  onPressed: _resetOrientation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 3, // shadow
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40), // button size
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/compass.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),



                ElevatedButton(
                  onPressed: () {
                    /// TODO: Add function opening selecting direction

                    showAppToast(
                      context,
                      message: "Sensor #1 — Water level rising!",
                      status: 'danger',
                      distance: 30,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color1,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.15),
                    minimumSize: const Size(40, 40),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/icons/direction.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ///Direction Details
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,

            /// Slide up / Slide down
            bottom: showDirectionSheet ? directionDragOffset : -directionSheetHeight,

            /// AUTO HEIGHT (null at first, then assigned after measurement)
            height: directionSheetHeight == 0 ? null : directionSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  directionDragOffset -= details.delta.dy;

                  if (directionDragOffset > 0) directionDragOffset = 0; // cannot drag above
                  if (directionDragOffset < -directionSheetHeight) {
                    directionDragOffset = -directionSheetHeight; // cannot drag below hidden
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (directionDragOffset < -directionSheetHeight / 2) {
                  setState(() {
                    showDirectionSheet = false;
                    directionDragOffset = 0;
                  });
                } else {
                  setState(() {
                    directionDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: directionKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      /// AUTO-DETECT HEIGHT after widget builds
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox = directionKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (directionSheetHeight != newHeight) {
                            setState(() {
                              directionSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          // Title
                          Row(
                            children: [
                              Icon(Icons.polyline_rounded, size: 32, color: color1_2),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Directions",
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Select a vehicle and destination",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Current & Destination Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color1_3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// Current Location
                                InkWell(
                                  onTap: () {
                                    print("Current Location clicked");
                                  },
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      children: [
                                        Image.asset('assets/images/icons/current.png', width: 22, height: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Current Location",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),

                                const Divider(height: 1, color: Colors.grey),

                                /// Destination
                                InkWell(
                                  onTap: () {
                                    print("Select Destination clicked");
                                  },
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      children: [
                                        Image.asset('assets/images/icons/destination.png', width: 22, height: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Select Destination",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Vehicle selection row
                          Container(
                            width: double.infinity,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    selectVehicle(
                                      name: 'Motorcycle',
                                      imagePath: 'assets/images/icons/motorcycle.png',
                                      onTap: () {
                                        setState(() => selectedVehicle = 'Motorcycle');
                                      },
                                    ),
                                    const SizedBox(width: 5),
                                    selectVehicle(
                                      name: 'Car',
                                      imagePath: 'assets/images/icons/car.png',
                                      onTap: () {
                                        setState(() => selectedVehicle = 'Car');
                                      },
                                    ),
                                    const SizedBox(width: 5),
                                    selectVehicle(
                                      name: 'Truck',
                                      imagePath: 'assets/images/icons/truck.png',
                                      onTap: () {
                                        setState(() => selectedVehicle = 'Truck');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 50), // extra spacing same as your Sensor sheet
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Sensor Settings
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showSensorSettingsSheet ? sensorSettingsDragOffset : -sensorSettingsSheetHeight,
            // AUTO HEIGHT
            height: sensorSettingsSheetHeight == 0 ? null : sensorSettingsSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorSettingsDragOffset -= details.delta.dy;

                  if (sensorSettingsDragOffset > 0) sensorSettingsDragOffset = 0;

                  if (sensorSettingsDragOffset < -sensorSettingsSheetHeight) {
                    sensorSettingsDragOffset = -sensorSettingsSheetHeight;
                  }
                });
              },
              onVerticalDragEnd: (details) {
                if (sensorSettingsDragOffset < -sensorSettingsSheetHeight / 2) {
                  setState(() {
                    showSensorSettingsSheet = false;
                    sensorSettingsDragOffset = 0;
                  });
                } else {
                  setState(() {
                    sensorSettingsDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: sensorSettingsKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // AUTO-DETECT THE HEIGHT AFTER FIRST BUILD
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox = sensorSettingsKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;
                          if (sensorSettingsSheetHeight != newHeight) {
                            setState(() {
                              sensorSettingsSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          Row(
                            children: [
                              Icon(Icons.settings, size: 32, color: color1_2),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sensor Settings",
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Control sensor display options",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          _sensorToggle(
                            title: 'Show All Sensors',
                            description: 'Display all sensors on the map',
                            value: showAllSensors,
                            onChanged: (val) {
                              setState(() {
                                showAllSensors = val;
                              });
                              _refreshSensorMarkers();
                            },
                          ),

                          _sensorToggle(
                            title: 'Show Sensor Range / Coverage',
                            description: 'Display sensor coverage area',
                            value: showSensorCoverage,
                            onChanged: (val) {
                              setState(() {
                                showSensorCoverage = val;
                              });
                            },
                          ),

                          _sensorToggle(
                            title: 'Alerted / Critical Sensors Only',
                            description: 'Show only sensors with alerts',
                            value: showCriticalSensors,
                            onChanged: (val) {
                              setState(() {
                                showCriticalSensors = val;
                              });
                            },
                          ),

                          _sensorToggle(
                            title: 'Sensor Labels',
                            description: 'Show sensor names or IDs on the map',
                            value: showSensorLabels,
                            onChanged: (val) {
                              setState(() {
                                showSensorLabels = val;
                              });
                              _refreshSensorMarkers();
                            },
                          ),
                          SizedBox(height: 50,)
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Sensor Details
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showSensorSheet ? sensorDragOffset : -sensorSheetHeight,

            // AUTO HEIGHT (same logic as Settings)
            height: sensorSheetHeight == 0 ? null : sensorSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorDragOffset -= details.delta.dy;

                  if (sensorDragOffset > 0) sensorDragOffset = 0;

                  if (sensorDragOffset < -sensorSheetHeight) {
                    sensorDragOffset = -sensorSheetHeight;
                  }
                });
              },

              onVerticalDragEnd: (details) {
                if (sensorDragOffset < -sensorSheetHeight / 2) {
                  setState(() {
                    showSensorSheet = false;
                    sensorDragOffset = 0;

                    // Remove sensor circles when closing
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  });
                } else {
                  setState(() {
                    sensorDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: sensorKey,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // AUTO-DETECT HEIGHT
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                        sensorKey.currentContext?.findRenderObject() as RenderBox?;

                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;

                          if (sensorSheetHeight != newHeight) {
                            setState(() {
                              sensorSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      final sensor = selectedSensorId != null
                          ? sensors[selectedSensorId]!
                          : null;
                      final data = sensor?['sensorData'];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DRAG HANDLE
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // HEADER
                          Row(
                            children: [
                              const Icon(Icons.sensors,
                                  size: 32, color: color1_2),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sensor Details",
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Tap for more information",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // INFO CARD
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _infoRow("Sensor ID", selectedSensorId ?? "-"),
                                _infoRow("Location", "Ortigas Ave"),
                                _infoRow("Distance", "${data?['distance'] ?? "-"} cm"),
                                _statusRow(
                                  "Status",
                                  data?['status'] ?? "-",
                                  _getStatusColor(data?['status'] ?? ""),
                                ),
                                _infoRow("Last Update", data?['lastUpdate'] ?? "-"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // BUTTON
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color1,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/info');
                                },
                                child: const Text(
                                  "View Full Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40), // padding for safe bottom
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Pin Confirmation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showPinConfirmationSheet ? pinConfirmationDragOffset : -pinConfirmationSheetHeight,

            // AUTO HEIGHT
            height: pinConfirmationSheetHeight == 0 ? null : pinConfirmationSheetHeight,

            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  pinConfirmationDragOffset -= details.delta.dy;

                  if (pinConfirmationDragOffset > 0) pinConfirmationDragOffset = 0;

                  if (pinConfirmationDragOffset < -pinConfirmationSheetHeight) {
                    pinConfirmationDragOffset = -pinConfirmationSheetHeight;
                  }
                });
              },

              onVerticalDragEnd: (details) {
                if (pinConfirmationDragOffset < -pinConfirmationSheetHeight / 2) {
                  setState(() {
                    cancelPinSelection();
                    pinConfirmationDragOffset = 0;
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  });
                } else {
                  setState(() {
                    pinConfirmationDragOffset = 0;
                  });
                }
              },

              child: Container(
                key: pinConfirmKey,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // AUTO-DETECT HEIGHT
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final renderBox =
                        pinConfirmKey.currentContext?.findRenderObject() as RenderBox?;

                        if (renderBox != null) {
                          final newHeight = renderBox.size.height;

                          if (pinConfirmationSheetHeight != newHeight) {
                            setState(() {
                              pinConfirmationSheetHeight = newHeight;
                            });
                          }
                        }
                      });

                      final sensor = selectedSensorId != null
                          ? sensors[selectedSensorId]!
                          : null;
                      final data = sensor?['sensorData'];

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DRAG HANDLE
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // HEADER
                          Row(
                            children: [
                              const Icon(Icons.location_pin,
                                  size: 32, color: color1_2),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Set Pin Location",
                                      style: TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Tap Confirm to set new pin location",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // CANCEL & CONFIRM BUTTONS
                          Row(
                            children: [
                              // CANCEL BUTTON
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: color1, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      cancelPinSelection();
                                    },
                                    child: const Text(
                                      "CANCEL",
                                      style: TextStyle(
                                        color: color1,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // CONFIRM BUTTON
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // Remove old saved pin if exists
                                        if (savedPinMarker != null) {
                                          _markers.remove(savedPinMarker);
                                        }

                                        // Promote temporary pin → official saved pin
                                        savedPinMarker = tappedMarker;
                                        savedPinPosition = tappedPosition;

                                        // Clear temp variables
                                        tappedMarker = null;
                                        tappedPosition = null;

                                        cancelPinSelection();
                                      });
                                    },
                                    child: const Text(
                                      "CONFIRM",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40), // bottom padding
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          ///Bottom Button
          Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            child: Row(
              children: [
                bottomButton(
                  onTap: () {
                    setState(() {
                      showSensorSheet = false;
                      showSensorSettingsSheet = false;
                      cancelPinSelection();
                      showDirectionSheet = !showDirectionSheet;
                    });
                    //_showDirectionDetails();
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  },
                  label: 'Directions',
                  imagePath: 'assets/images/icons/pin.png',
                  iconColor: (showDirectionSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () {
                    setState(() {
                      showSensorSheet = false;
                      showDirectionSheet = false;
                      cancelPinSelection();
                      showSensorSettingsSheet = !showSensorSettingsSheet;
                    });
                    _circles.removeWhere((c) => c.circleId.value.startsWith('sensor'));
                  },
                  label: 'Sensor',
                  imagePath: 'assets/images/icons/sensor.png',
                  iconColor: (showSensorSettingsSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () => print("👤 Account pressed"),
                  label: 'Alerts',
                  imagePath: 'assets/images/icons/exclamation.png',
                  iconColor: (nearAlertZone) ? Colors.red : color2,
                ),
              ],
            ),
          ),

          ///Back Button
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: (){
                Navigator.pop(context);
                //Navigator.pushReplacementNamed(context, '/');

              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: BorderRadius.circular(50), // perfect circle
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/icons/back.png',
                    width: 25,
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }


  Widget bottomButton({
    required VoidCallback onTap,
    required String imagePath,
    required String label,
    Color iconColor = color2,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(60),
          shape: const RoundedRectangleBorder(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 25,
              height: 25,
              fit: BoxFit.contain,
              color: iconColor,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 2), // spacing between icon and text
            Text(
              label,
              style: TextStyle( // remove const here
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: iconColor, // now works
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget selectVehicle({
    required String name,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: (selectedVehicle == name) ? color1 : Colors.white,
          borderRadius: BorderRadius.circular(40 / 2), // perfect circle
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 25, // image slightly smaller than container
            height: 25,
            fit: BoxFit.contain,
            color: (selectedVehicle == name) ? Colors.white : color2, // apply green tint
            colorBlendMode: BlendMode.srcIn, // ensures the color replaces the original
          ),
        ),
      ),
    );
  }




// Reusable widget
  Widget _sensorToggle({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color1,  // your main app primary color
          ),
        ],
      ),
    );
  }



  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

