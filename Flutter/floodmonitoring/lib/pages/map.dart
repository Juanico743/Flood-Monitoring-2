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
  Map<String, dynamic> data = {
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
      data = result;
    });
    return result;
  }

  Set<Circle> _circles = {};

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
            final currentData = await fetchData();

            // Show details
            _showSensorDetails(
              context,
              sensorId: '#01',
              distance: '${currentData['distance']}',
              status: currentData['status'],
              lastUpdate: currentData['lastUpdate'],
              location: 'Ortigas Ave',
              statusColor: currentData['status'] == 'Safe'
                  ? color_safe
                  : currentData['status'] == 'Warning'
                  ? color_warning
                  : currentData['status'] == 'Danger'
                  ? color_danger
                  : Colors.black,
            );

            // Add a circle around this marker
            setState(() {
              _circles.clear(); // remove previous circle if needed
              _circles.add(
                Circle(
                  circleId: const CircleId('sensor_01_circle'),
                  center: _center,
                  radius: 200, // radius in meters
                  strokeWidth: 2, // outline width
                  strokeColor: currentData['status'] == 'Safe'
                      ? color_safe
                      : currentData['status'] == 'Warning'
                      ? color_warning
                      : currentData['status'] == 'Danger'
                      ? color_danger
                      : Colors.black, // outline color
                  fillColor: currentData['status'] == 'Safe'
                      ? color_safe.withOpacity(0.3)
                      : currentData['status'] == 'Warning'
                      ? color_warning.withOpacity(0.3)
                      : currentData['status'] == 'Danger'
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

  void _showDirectionDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.18,
          minChildSize: 0.1,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, modalSetState) {  // <-- use modalSetState
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const Text(
                          'Directions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5,),

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
                                    color: Colors.black.withOpacity(0.15), // shadow color
                                    spreadRadius: 1, // how much it spreads
                                    blurRadius: 3,   // blur effect
                                    offset: const Offset(0, 0), // x, y offset
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
                                      modalSetState(() {   // <-- update modal
                                        selectedVehicle = 'Motorcycle';
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  selectVehicle(
                                    name: 'Car',
                                    imagePath: 'assets/images/icons/car.png',
                                    onTap: () {
                                      modalSetState(() {
                                        selectedVehicle = 'Car';
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  selectVehicle(
                                    name: 'Truck',
                                    imagePath: 'assets/images/icons/truck.png',
                                    onTap: () {
                                      modalSetState(() {
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
                );
              },
            );
          },
        );
      },
    );
  }




  Future<void> _showSensorDetails(
      BuildContext context, {
        required String sensorId,
        required String distance,
        required String status,
        required Color statusColor,
        required String lastUpdate,
        required String location,
      }) async {
    // Await the bottom sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.transparent,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Sensor Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Sensor ID: $sensorId', style: TextStyle(fontSize: 16)),
              Text('Distance: ${distance}cm', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 16)),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text('Last Update: $lastUpdate', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 5),
              Text('Location: $location', style: TextStyle(fontSize: 16)),
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
        );
      },
    );

    setState(() {
      _circles.clear();
    });
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
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 🔍 Floating Search Bar (Top)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search location...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) {
                  // TODO: Add search functionality
                  print("Search: $value");
                },
              ),
            ),
          ),

          // 📍 Bottom Button Bar
          Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            child: Row(
              children: [
                bottomButton(
                  onTap: () {
                    _showDirectionDetails();
                    _circles.clear();
                  },
                  icon: Icons.location_pin,
                ),
                bottomButton(
                  onTap: () {
                    setState(() {
                      _circles.clear();
                    });
                  },
                  icon: Icons.save,
                ),
                bottomButton(
                  onTap: () => print("👤 Account pressed"),
                  icon: Icons.person,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget bottomButton({
    required VoidCallback onTap,
    required IconData icon,
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
        child: Icon(icon, size: 30),
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
}
