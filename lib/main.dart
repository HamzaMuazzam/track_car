import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:track_car/logs_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: MapSample()));
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  TextEditingController controller = TextEditingController();
  late FirebaseFirestore fireStore;

  Marker? carMarker;
  BitmapDescriptor? carIcon;

  @override
  void initState() {
    super.initState();
    fireStore = FirebaseFirestore.instance;
    _setCustomMarkerIcon();
  }

  StreamSubscription? listen;

  // Load the custom car icon
  void _setCustomMarkerIcon() async {
    carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/car_icon.png', // Replace with the path to your car icon
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Scaffold(
        body: Column(
          children: [
            TextField(
              controller: controller,
            ),
            Expanded(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: carMarker != null ? {carMarker!} : {},
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          if (listen != null) listen?.cancel();
                          var collection = fireStore.collection(controller.text);
                          listen = collection.snapshots().listen((querySnapshot) {
                            for (var change in querySnapshot.docChanges) {
                              if (change.doc.exists) {
                                print(change.doc.data());
                                double? latitude = change.doc.get("latitude");
                                double? longitude = change.doc.get("longitude");
                                _updateCarMarker(latitude, longitude);
                                goToLiveTrack(latitude, longitude);
                                setState(() {});
                              }
                            }
                          });
                        }
                      },
                      child: const Text("Start Tracking")),
                ),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (builder){
                            return LogsScreen(collectionName: controller.text);
                          }));
                        }
                      },
                      child: const Text("View Logs")),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> goToLiveTrack(double? latitude, double? longitude) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(latitude ?? 0.0, longitude ?? 0.0), zoom: 16,),));
  }

  void _updateCarMarker(double? latitude, double? longitude) {
    if (latitude == null || longitude == null || carIcon == null) return;

      carMarker = Marker(
        markerId: const MarkerId('car'),
        position: LatLng(latitude, longitude),
        icon: carIcon!,
        infoWindow: const InfoWindow(title: 'Car Location'),
      );
  }
}
