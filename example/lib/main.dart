import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geofencing/enums/geofence_status.dart';
import 'package:geofencing/geofencing.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _geofencingPlugin = EmmGeofencing();

  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController radiusController = TextEditingController();

  StreamSubscription<GeofenceStatus>? geofenceStatusStream;
  Geolocator geolocator = Geolocator();
  String geofenceStatus = '';
  bool isReady = false;
  Position? position;
  LocationSettings? locationSettings;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    getCurrentPosition();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  getCurrentPosition() async {

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 10),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
            "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: false,
          )
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("LOCATION => ${position!.toJson()}");
    latitudeController.text = position!.latitude.toString();
    longitudeController.text = position!.longitude.toString();

    isReady = (position != null) ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text("Geofencing"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                const SizedBox(height: 20),

                TextField(
                  controller: latitudeController,
                  decoration:  InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 0.6)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.teal, width: 1.0),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    labelText: "Enter pointed Latitude",
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: longitudeController,
                  decoration:  InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 0.6)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.teal, width: 1.0),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    labelText: "Enter pointed longitude",
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: radiusController,
                  decoration:  InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 0.6)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Colors.teal, width: 1.0),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    labelText: "Enter radius in meter",
                  ),
                ),
                const SizedBox(
                  height: 60,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.teal,
                        onPrimary: Colors.white,
                        onSurface: Colors.grey,
                      ),
                      onPressed: () {
                        EmmGeofencing.startGeofenceService(
                            pointedLatitude: latitudeController.text,
                            pointedLongitude: longitudeController.text,
                            radiusMeter: radiusController.text,
                            eventPeriodInSeconds: 5,
                            locationSettings: locationSettings!
                        );
                        geofenceStatusStream ??= EmmGeofencing.getGeofenceStream()!
                            .listen((GeofenceStatus status) {
                          print("status => $status");
                          setState(() {
                            geofenceStatus = status.toString();
                          });
                        });
                      },
                      child: const Text('Start'),
                    ),

                    const SizedBox(
                      width: 10.0,
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.redAccent,
                        onPrimary: Colors.white,
                        onSurface: Colors.grey,
                      ),
                      onPressed: () {
                        EmmGeofencing.stopGeofenceService();
                        geofenceStatusStream!.cancel();
                      },
                      child: const Text('Stop'),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                ),
                Text(
                  "Geofence Status: \n\n\n$geofenceStatus",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}
