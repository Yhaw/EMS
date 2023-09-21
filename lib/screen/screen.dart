import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceName;
  final String deviceID;

  DeviceDetailsScreen({
    required this.deviceName,
    required this.deviceID,
    required int voltage,
    required int current,
    required String deviceLocation,
  });

  @override
  _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool isDeviceOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Devices')
            .doc(widget.deviceName)
            .get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Device not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          isDeviceOn = data['DeviceStatus'] == 1;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: <Widget>[
                _buildDashboardItem('Device Name', data['DeviceName'] ?? "N/A"),
                _buildDashboardItem(
                    'Device Location', data['DeviceLocation'] ?? "N/A"),
                _buildToggleItem(),
                _buildDashboardItem('Current', '${data['Current'] ?? "N/A"} A'),
                _buildDashboardItem('Voltage', '${data['Voltage'] ?? "N/A"} V'),
                _buildDashboardItem('Power', '${data['Power'] ?? "N/A"} W'),
                _buildDashboardItem('Energy', '${data['Energy'] ?? "N/A"} J'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardItem(String label, String value) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40.0),
            Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Device Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40.0),
            Row(
              children: <Widget>[
                Icon(Icons.power_settings_new,
                    color: isDeviceOn ? Colors.green : Colors.red),
                SizedBox(width: 16.0),
                Text(
                  isDeviceOn ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 25,
                    color: isDeviceOn ? Colors.green : Colors.red,
                  ),
                ),
                Spacer(),
                Switch(
                  value: isDeviceOn,
                  onChanged: (newValue) {
                    // Update the device status in Firestore
                    FirebaseFirestore.instance
                        .collection('Devices')
                        .doc(widget.deviceName)
                        .update({'DeviceStatus': newValue ? 1 : 0}).then((_) {
                      setState(() {
                        isDeviceOn = newValue;
                      });
                    }).catchError((error) {
                      print("Error updating device status: $error");
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
