import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(14.6255, 121.1245);
  final Set<Marker> _markers = {};

  // Example sensor data
  final String sensorId = "#01";
  final String status = "Safe"; // Safe / Warning / Danger
  final DateTime lastUpdate = DateTime(2025, 11, 8, 18, 30);

  Color getStatusColor(String status) {
    switch (status) {
      case "Safe":
        return Colors.green;
      case "Warning":
        return Colors.orange;
      case "Danger":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('sensor1'),
          position: _center,
          infoWindow: InfoWindow(
            title: 'Sensor ID: #01',
            snippet: 'Status: Safe\nLast Update: 6:30 PM 11/8/2025\nTap for more info',
            onTap: () {
              // You can open a dialog or new page here
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sensor #01 Details'),
                  content: const Text(
                    'Status: Safe\n'
                        'Last Update: 6:30 PM 11/8/2025\n'
                        'Location: 14.6255, 121.1245',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('More Info'),
                    ),
                  ],
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    });

  }

  void _showSensorDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        String formattedTime = DateFormat('h:mma MM/dd/yyyy').format(lastUpdate);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Flood Monitoring Sensor",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Sensor ID: $sensorId"),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text("Status: "),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("Last Update: $formattedTime"),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // You can navigate to another page for more info
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("More Info"),
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
        zoomControlsEnabled: true,
      ),
    );
  }
}
