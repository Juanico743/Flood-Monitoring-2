import 'package:floodmonitoring/services/flood_level.dart';
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('sensor_01'),
          position: _center,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () async {
            // Wait for the latest data and store it
            final currentData = await fetchData();

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
          },
        ),
      );
    });
  }

  void _showSensorDetails(
      BuildContext context, {
        required String sensorId,
        required String distance,
        required String status,
        required Color statusColor,
        required String lastUpdate,
        required String location,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 15.0,
        ),
        markers: _markers,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
