import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(GoogleMapApp());
}

class GoogleMapApp extends StatelessWidget {
  const GoogleMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? position;
  late GoogleMapController mapController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();
  }

  Set<Marker> markers = {};
  List<LatLng> points = [];
  Set<Polyline> polylines = {};

  void gotoLocation(LatLng position) {
    markers.clear;
    markers.add(Marker(markerId: MarkerId('${position}'), position: position));
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 12),
      ),
    );

    setState(() {});
  }

  Future<bool> checkLocationServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location service is turned-off. Please enable it in settings for the app to work.',
          ),
        ),
      );
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission to use devices\'s location is denied. Please enable it in the Settings.',
            ),
          ),
        );
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permission to use devices\'s location is denied. Please enable it in the Settings.',
            ),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void getCurrentLocation() async {
    if (!await checkLocationServicePermission()) {
      return;
    }
    position = await Geolocator.getCurrentPosition();
    setState(() {});
    print('${position?.latitude} ${position?.longitude}');
    Geolocator.getPositionStream().listen((geoPosition) {
      gotoLocation(LatLng(geoPosition.latitude, geoPosition.longitude));
    });
  }

  void onTapMarked(LatLng position) {
    if (points.length == 2) {
      setState(() {
        points.clear();
        markers.clear();
        polylines.clear();
      });
    } else {
      setState(() {
        points.add(position);

        if (points.length == 1) {
          markers.add(
            Marker(
              markerId: MarkerId('start'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(title: 'Start Point'),
            ),
          );
        } else if (points.length == 2) {
          markers.add(
            Marker(
              markerId: MarkerId('end'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(title: 'End Point'),
            ),
          );
        }

        polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            visible: true,
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GoogleMap(
          onMapCreated: (controller) => mapController = controller,
          mapType: MapType.normal,
          mapToolbarEnabled: true,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: false,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          initialCameraPosition: CameraPosition(
            target: LatLng(15.98789091430814, 120.57330634637879),
            zoom: 10,
            // tilt: 60,
          ),
          markers: markers,
          onTap: onTapMarked,
          polylines: polylines,
        ),
      ),
    );
  }
}
