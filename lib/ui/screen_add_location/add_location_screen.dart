import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/theme.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  Location location = Location();
  CameraPosition? initialCameraPosition;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor(context),
        title: Text(
          titleAddLocationScreen,
          style: appBarTextStyle,
        ),
      ),
      body: GoogleMap(initialCameraPosition: initialCameraPosition!,
        myLocationEnabled: true,
      ),
    );
  }

  getCurrentLocation() async {
    location.getLocation().then((location) {
      LatLng initialLatLng = LatLng(location.latitude!, location.longitude!);
      initialCameraPosition = CameraPosition(
        target: initialLatLng,
        zoom: 16,
      );
      setState(() {});
    });
  }

}
