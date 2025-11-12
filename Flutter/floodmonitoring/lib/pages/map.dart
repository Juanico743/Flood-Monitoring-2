import 'package:floodmonitoring/services/flood_level.dart';
import 'package:floodmonitoring/services/global.dart';
import 'package:floodmonitoring/utils/style.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  Map<String, dynamic> sensorData = {
    "distance": 0.0,
    "status": "Loading...",
    "lastUpdate": "00:00 AM"
  };

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<Map<String, dynamic>> fetchData() async {
    final result = await blynk.fetchDistance();
    setState(() {
      sensorData = result;
    });
    return result;
  }

  Set<Circle> _circles = {};


  bool showDirectionSheet = false;
  bool showSensorSheet = false;
  bool showSensorSettingsSheet = false;

  double directionSheetHeight = 300;
  double sensorSheetHeight = 350;
  double sensorSettingsSheetHeight = 500;

  double directionDragOffset = 0;
  double sensorDragOffset = 0;
  double sensorSettingsDragOffset = 0;


  bool showAllSensors = true;
  bool showSensorCoverage = false;
  bool showCriticalSensors = false;
  bool showSensorLabels = true;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('sensor_01'),
          position: _center,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () async {
            // Fetch latest data
            await fetchData();

            setState(() {
              showDirectionSheet = false;
              showSensorSettingsSheet = false;
              showSensorSheet = true;
            });

            // Add a circle around this marker
            setState(() {
              _circles.clear(); // remove previous circle if needed
              _circles.add(
                Circle(
                  circleId: const CircleId('sensor_01_circle'),
                  center: _center,
                  radius: 200, // radius in meters
                  strokeWidth: 2, // outline width
                  strokeColor: sensorData['status'] == 'Safe'
                      ? color_safe
                      : sensorData['status'] == 'Warning'
                      ? color_warning
                      : sensorData['status'] == 'Danger'
                      ? color_danger
                      : Colors.black, // outline color
                  fillColor: sensorData['status'] == 'Safe'
                      ? color_safe.withOpacity(0.3)
                      : sensorData['status'] == 'Warning'
                      ? color_warning.withOpacity(0.3)
                      : sensorData['status'] == 'Danger'
                      ? color_danger.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3), // semi-transparent fill
                ),
              );
            });
          },
        ),
      );
    });
  }


  /// Zoom and center to a specific location
  void _zoomToCenter() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _center,
          zoom: 15.0, // desired zoom level
        ),
      ),
    );
  }

  /// Reset map orientation (bearing & tilt)
  void _resetOrientation() async {
    final currentPos = await mapController.getLatLng(
      ScreenCoordinate(x: 200, y: 400),
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentPos,
          zoom: await mapController.getZoomLevel(),
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 🚫 Prevents map/buttons from shifting up
      body: Stack(
        children: [
          // 🗺️ MAP
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            markers: _markers,
            circles: _circles,
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


          Positioned(
            top: 0,
            bottom: 0,
            left: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _zoomToCenter,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15), // shadow color
                          spreadRadius: 1, // how much it spreads
                          blurRadius: 3,   // blur effect
                          offset: const Offset(0, 0), // x, y offset
                        ),
                      ],
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
                ),

                SizedBox(height: 10,),

                GestureDetector(
                  onTap: _resetOrientation,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: color1,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15), // shadow color
                          spreadRadius: 1, // how much it spreads
                          blurRadius: 3,   // blur effect
                          offset: const Offset(0, 0), // x, y offset
                        ),
                      ],
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
            bottom: showDirectionSheet ? directionDragOffset : -directionSheetHeight,
            height: directionSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  directionDragOffset -= details.delta.dy;
                  if (directionDragOffset > 0) directionDragOffset = 0; // cannot drag above screen
                  if (directionDragOffset < -directionSheetHeight) directionDragOffset = -directionSheetHeight; // cannot drag below hidden
                });
              },
              onVerticalDragEnd: (details) {
                // Snap logic: if dragged more than half, hide sheet
                if (directionDragOffset < -directionSheetHeight / 2) {
                  setState(() {
                    showDirectionSheet = false;
                    directionDragOffset = 0;
                  });
                } else {
                  setState(() {
                    directionDragOffset = 0; // snap back to visible
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Directions',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Container(
                        height: 100,
                        width: double.infinity,
                        padding: const EdgeInsets.all(10), // optional padding inside container
                        decoration: BoxDecoration(
                          color: color1_3,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // space between rows
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current Location Row
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icons/current.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8), // spacing between icon and text
                                Expanded(
                                  child: Text(
                                    'Current Location',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                SizedBox(width: 30), // same as icon width + spacing
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),

                            // Select Destination Row
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/icons/destination.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Select Destination',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                selectVehicle(
                                  name: 'Motorcycle',
                                  imagePath: 'assets/images/icons/motorcycle.png',
                                  onTap: () {
                                    setState(() {
                                      selectedVehicle = 'Motorcycle';
                                    });
                                  },
                                ),
                                const SizedBox(width: 5),
                                selectVehicle(
                                  name: 'Car',
                                  imagePath: 'assets/images/icons/car.png',
                                  onTap: () {
                                    setState(() {
                                      selectedVehicle = 'Car';
                                    });
                                  },
                                ),
                                const SizedBox(width: 5),
                                selectVehicle(
                                  name: 'Truck',
                                  imagePath: 'assets/images/icons/truck.png',
                                  onTap: () {
                                    setState(() {
                                      selectedVehicle = 'Truck';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
            height: sensorSettingsSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorSettingsDragOffset -= details.delta.dy;
                  if (sensorSettingsDragOffset > 0) sensorSettingsDragOffset = 0; // cannot drag above screen
                  if (sensorSettingsDragOffset < -sensorSettingsSheetHeight) sensorSettingsDragOffset = -sensorSettingsSheetHeight; // cannot drag below hidden
                });
              },
              onVerticalDragEnd: (details) {
                if (sensorSettingsDragOffset < -sensorSettingsSheetHeight / 2) {
                  setState(() {
                    showSensorSettingsSheet = false;
                    sensorSettingsDragOffset = 0;
                    _circles.clear();
                  });
                } else {
                  setState(() {
                    sensorSettingsDragOffset = 0; // snap back to shown
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Settings',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          // Helper function to create a row with toggle
                          _sensorToggle(
                            title: 'Show All Sensors',
                            description: 'Display all sensors on the map',
                            value: showAllSensors,
                            onChanged: (val) {
                              setState(() {

                                showAllSensors = val;
                                print('showAllSensors:$showAllSensors');
                              });
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
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          ///Sensor Details
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showSensorSheet ? sensorDragOffset : -sensorSheetHeight,
            height: sensorSheetHeight,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  sensorDragOffset -= details.delta.dy;
                  if (sensorDragOffset > 0) sensorDragOffset = 0; // cannot drag above screen
                  if (sensorDragOffset < -sensorSheetHeight) sensorDragOffset = -sensorSheetHeight; // cannot drag below hidden
                });
              },
              onVerticalDragEnd: (details) {
                if (sensorDragOffset < -sensorSheetHeight / 2) {
                  setState(() {
                    showSensorSheet = false;
                    sensorDragOffset = 0;
                    _circles.clear();
                  });
                } else {
                  setState(() {
                    sensorDragOffset = 0; // snap back to shown
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensor Details',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text('Sensor ID: #01', style: TextStyle(fontSize: 16)),
                          Text('Distance: ${sensorData['distance']}cm', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('Status: ', style: TextStyle(fontSize: 16)),
                              Text(
                                sensorData['status'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: sensorData['status'] == 'Safe'
                                      ? color_safe
                                      : sensorData['status'] == 'Warning'
                                      ? color_warning
                                      : sensorData['status'] == 'Danger'
                                      ? color_danger
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text('Last Update: ${sensorData['lastUpdate']}', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 5),
                          Text('Location: Ortigas Ave', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 15),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/info');
                              },
                              child: const Text('More Info'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

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
                      showDirectionSheet = !showDirectionSheet;
                    });
                    //_showDirectionDetails();
                    _circles.clear();
                  },
                  imagePath: 'assets/images/icons/pin.png',
                  iconColor: (showDirectionSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () {
                    setState(() {
                      showSensorSheet = false;
                      showDirectionSheet = false;
                      showSensorSettingsSheet = !showSensorSettingsSheet;
                    });
                  },
                  imagePath: 'assets/images/icons/sensor.png',
                  iconColor: (showSensorSettingsSheet) ? color1 : color2,
                ),
                bottomButton(
                  onTap: () => print("👤 Account pressed"),
                  imagePath: 'assets/images/icons/exclamation.png',
                ),
              ],
            ),
          ),

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
    required String imagePath, // changed from IconData to image path
    Color iconColor = color2, // optional
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(60), // button height
          shape: const RoundedRectangleBorder(), // no rounded corners
        ),
        child: Image.asset(
          imagePath,
          width: 25,
          height: 25,
          fit: BoxFit.contain,
          color: iconColor,
          colorBlendMode: BlendMode.srcIn,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color1, // use your color1 when on
              ),
            ],
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

