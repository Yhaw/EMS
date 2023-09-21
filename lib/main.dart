import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screen/screen.dart'; // Import the DeviceDetailsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firestore Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves),
            SizedBox(width: 8),
            Text(
              'Appliance Energy Meter',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.waves),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Devices').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final deviceCards = snapshot.data!.docs.map((document) {
                  final data = document.data() as Map<String, dynamic>;
                  return DeviceCard(
                    deviceName: document.id,
                    deviceLocation: data['DeviceLocation'],
                    deviceID: data['DeviceID'],
                    current: data['Current'],
                    voltage: data['Voltage'],
                    onDelete: () {
                      FirebaseFirestore.instance
                          .collection('Devices')
                          .doc(document.id)
                          .delete();
                    },
                  );
                }).toList();

                return ListView.builder(
                  itemCount: deviceCards.length,
                  itemBuilder: (context, index) {
                    return deviceCards[index];
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CreateDeviceCardDialog();
            },
          );
        },
        tooltip: 'Create Card',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String? deviceName;
  final String? deviceLocation;
  final String? deviceID;
  final int? current;
  final int? voltage;
  final Function onDelete;

  DeviceCard({
    this.deviceName,
    this.deviceLocation,
    this.deviceID,
    this.current,
    this.voltage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeviceDetailsScreen(
                deviceName: deviceName ?? "N/A",
                deviceLocation: deviceLocation ?? "N/A",
                deviceID: deviceID ?? "N/A",
                current: current ?? 0,
                voltage: voltage ?? 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Device: ${deviceName ?? "N/A"}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      onDelete();
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(
                'Location: ${deviceLocation ?? "N/A"}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4.0),
              Row(
                children: [
                  Text(
                    'Current: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${current ?? 0} A',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 4.0),
              Row(
                children: [
                  Text(
                    'Voltage: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${voltage ?? 0} V',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateDeviceCardDialog extends StatefulWidget {
  @override
  _CreateDeviceCardDialogState createState() => _CreateDeviceCardDialogState();
}

class _CreateDeviceCardDialogState extends State<CreateDeviceCardDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _deviceIDController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _voltageController = TextEditingController();

  bool isDeviceIDExists = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create a New Device Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Device Name'),
          ),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(labelText: 'Device Location'),
          ),
          TextFormField(
            controller: _deviceIDController,
            decoration: InputDecoration(labelText: 'Device ID'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final deviceID = _deviceIDController.text;
            final deviceName = _nameController.text;
            final deviceExists = await checkDeviceExists(deviceID);

            if (deviceExists) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Device ID Already Exists'),
                    content: Text(
                        'A device with this ID already exists. Please choose a different ID.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else {
              final Map<String, dynamic> deviceData = {
                'DeviceLocation': _locationController.text,
                'DeviceID': deviceID,
                'DeviceName': deviceName,
                'Current': int.tryParse(_currentController.text) ?? 0,
                'Voltage': int.tryParse(_voltageController.text) ?? 0,
                'Threshold': int.tryParse(_voltageController.text) ?? 0,
                'DeviceStatus': int.tryParse(_voltageController.text) ?? 0,
                'Power': int.tryParse(_voltageController.text) ?? 0,
                'Energy': int.tryParse(_voltageController.text) ?? 0,
              };

              FirebaseFirestore.instance
                  .collection('Devices')
                  .doc(_deviceIDController.text)
                  .set(deviceData);

              _nameController.clear();
              _locationController.clear();
              _deviceIDController.clear();
              _currentController.clear();
              _voltageController.clear();

              Navigator.of(context).pop();
            }
          },
          child: Text('Create'),
        ),
      ],
    );
  }

  Future<bool> checkDeviceExists(String deviceID) async {
    final query = await FirebaseFirestore.instance
        .collection('Devices')
        .where('DeviceID', isEqualTo: deviceID)
        .get();

    return query.docs.isNotEmpty;
  }
}

void openDeviceDetails(BuildContext context, String deviceName,
    String deviceLocation, String deviceID, int current, int voltage) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => DeviceDetailsScreen(
        deviceName: deviceName,
        deviceLocation: deviceLocation,
        deviceID: deviceID,
        current: current,
        voltage: voltage,
      ),
    ),
  );
}
