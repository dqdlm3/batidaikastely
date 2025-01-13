import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';

void main() {
  runApp(const BatidaApp());
}

class BatidaApp extends StatelessWidget {
  const BatidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batidai vadászkastély',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BatidaHomePage(),
    );
  }
}

class BatidaHomePage extends StatefulWidget {
  const BatidaHomePage({super.key});

  @override
  State<BatidaHomePage> createState() => _BatidaHomePageState();
}

class _BatidaHomePageState extends State<BatidaHomePage> {
  static const double targetLatitude = 46.4171;
  static const double targetLongitude = 20.31907;

  Position? _currentPosition;
  double? _distance;
  double? _bearing;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _calculateDistanceAndBearing();
    });
  }

  void _calculateDistanceAndBearing() {
    if (_currentPosition == null) return;

    final double currentLat = _currentPosition!.latitude;
    final double currentLon = _currentPosition!.longitude;

    // Calculate distance
    _distance = Geolocator.distanceBetween(
      currentLat,
      currentLon,
      targetLatitude,
      targetLongitude,
    );

    // Calculate bearing
    final double lat1 = currentLat * pi / 180;
    final double lon1 = currentLon * pi / 180;
    final double lat2 = targetLatitude * pi / 180;
    final double lon2 = targetLongitude * pi / 180;

    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    _bearing = (atan2(y, x) * 180 / pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, 
        title: const Text(
          'Batidai vadászkastély',
          style: TextStyle(
            fontSize: 24, // Nagyobb betűméret
            fontWeight: FontWeight.bold, // Félkövér stílus
          ),
         ),
      ),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Iránytű hiba: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final double deviceHeading = snapshot.data!.heading ?? 0;
          final double? arrowDirection = _bearing != null ? (_bearing! - deviceHeading) % 360 : null;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_distance != null)
                  Text('Távolság: ${_distance!.toStringAsFixed(2)} m',
                      style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                if (arrowDirection != null)
                  Transform.rotate(
                    angle: arrowDirection * pi / 180,
                    child: Icon(Icons.navigation, size: 100, color: Colors.blue),
                  ),
                const SizedBox(height: 20),
                // ElevatedButton(
                //   onPressed: _getCurrentPosition,
                //   child: const Text('Helyzet frissítése'),
                // ),
                const SizedBox(height: 20), // Extra tér a kép előtt
                Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150, // A kívánt méret
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
