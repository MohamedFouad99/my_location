// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, avoid_print, avoid_init_to_null, unused_field, prefer_final_fields, unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Set<Marker> markers = {};
double defLat = 31.2671367;
double defLng = 32.2897708;

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static final CameraPosition _home = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(31.2671367, 32.2897708),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  void initState() {
    getUserLocation();
    var userMarker = Marker(
        markerId: MarkerId('USER_Location'),
        position: LatLng(locationData?.latitude ?? defLat,
            locationData?.longitude ?? defLng));
    markers.add(userMarker);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location App'),
      ),
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheHome,
        label: Text('My Home'),
        icon: Icon(Icons.home),
      ),
    );
  }

  Future<void> _goToTheHome() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_home));
  }

  Location location = Location();
  late PermissionStatus permissionStatus;
  bool serviceEnabled = false;
  LocationData? locationData = null;
  StreamSubscription<LocationData>? locationListener;

  Future<bool> isPermissionGranted() async {
    permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
    }
    return permissionStatus == PermissionStatus.granted;
  }

  Future<bool> isServiceEnabled() async {
    serviceEnabled = await location.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await location.requestService();
    }
    return serviceEnabled;
  }

  void getUserLocation() async {
    bool permissionGranted = await isPermissionGranted();
    if (permissionGranted == false) return; //user denied permission
    bool gpsEnabled = await isServiceEnabled();
    if (gpsEnabled == false) return; // user didn't allow open gps

    locationData = await location.getLocation();
    print(locationData?.latitude ?? 0);
    print(locationData?.longitude ?? 0);
    location.changeSettings(
        accuracy: LocationAccuracy.high, interval: 1000, distanceFilter: 10);

    locationListener = location.onLocationChanged.listen((newestLocation) {
      locationData = newestLocation;
      updateUserMarker();
      print(locationData?.latitude ?? 0);
      print(locationData?.longitude ?? 0);
    });
  }

  void updateUserMarker() async {
    var userMarker = Marker(
        markerId: MarkerId('USER_Location'),
        position: LatLng(locationData?.latitude ?? defLat,
            locationData?.longitude ?? defLng));
    markers.add(userMarker);
    setState(() {});
    final GoogleMapController controller = await _controller.future;
    var newCameraPos = CameraPosition(
        target: LatLng(locationData?.latitude ?? defLat,
            locationData?.longitude ?? defLng),
        zoom: 19);
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPos));
  }
}
