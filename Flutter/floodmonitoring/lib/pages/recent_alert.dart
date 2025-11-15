import 'package:flutter/material.dart';
import 'package:floodmonitoring/utils/style.dart';

class RecentAlert extends StatefulWidget {
  const RecentAlert({super.key});

  @override
  State<RecentAlert> createState() => _RecentAlertState();
}

class _RecentAlertState extends State<RecentAlert> {
  // Sample alert data
  final List<Map<String, String>> alerts = [
    {
      "location": "Ortigas Ave Sensor #1",
      "status": "Warning",
      "level": "Flood Level: 18 cm",
    },
    {
      "location": "Mandaluyong Sensor #2",
      "status": "Danger",
      "level": "Flood Level: 30 cm",
    },
    {
      "location": "Cainta Sensor #3",
      "status": "Safe",
      "level": "Flood Level: 5 cm",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter only Warning or Danger
    final activeAlerts = alerts
        .where((a) => a['status'] == 'Warning' || a['status'] == 'Danger')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Alerts"),
        backgroundColor: color1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: activeAlerts.isEmpty
            ? Center(
          child: Text(
            "No active alerts",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        )
            : Column(
          children: activeAlerts
              .map((alert) => _alertCard(alert))
              .toList(),
        ),
      ),
    );
  }

  Widget _alertCard(Map<String, String> alert) {
    Color statusColor;
    IconData statusIcon;

    switch (alert['status']) {
      case 'Warning':
        statusColor = color_warning;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'Danger':
        statusColor = color_danger;
        statusIcon = Icons.dangerous_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Left info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['location'] ?? "-",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(alert['level'] ?? "-",
                    style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),

          // Right status icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
        ],
      ),
    );
  }
}
