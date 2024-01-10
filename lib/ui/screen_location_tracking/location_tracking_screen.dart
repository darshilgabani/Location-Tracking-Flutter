import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:location_tracking_flutter/model/model_location_data.dart';
import 'package:location_tracking_flutter/ui/screen_location_tracking/location_tracking_manager.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/custom/circular_progress.dart';
import 'package:location_tracking_flutter/utils/custom/custom_btn.dart';
import 'package:location_tracking_flutter/utils/helper.dart';
import 'package:location_tracking_flutter/utils/theme.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  DatabaseReference database = FirebaseDatabase.instance.ref();
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  StreamSubscription<LocationData>? locationSubscription;

  Location location = Location();
  LatLng? destination;
  LocationData? currentLocation;
  CameraPosition? initialCameraPosition;
  List<Marker> markerList = [];
  List<LocationDataModel> locationDataList = [];
  List<LatLng> polyline = [];
  bool isBtnEnable = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    location.enableBackgroundMode(enable: true);
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: textWhiteColor,
          ),
          backgroundColor: appBarColor(context),
          title: Text(
            titleLocationTrackingScreen,
            style: appBarTextStyle,
          ),
        ),
        body: Stack(
          children: [
            currentLocation == null
                ? CircularProgress()
                : GoogleMap(
                    initialCameraPosition: initialCameraPosition!,
                    polylines: {
                      Polyline(
                          polylineId: PolylineId("route"),
                          points: polyline,
                          color: themeOrangeColor,
                          width: 6)
                    },
                    onMapCreated: (controller) {
                      _controller.complete(controller);
                    },
                    markers: Set<Marker>.of(markerList),
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
            Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: CustomButton(
                  btnName: lblCheckoutBtn,
                  isBtnEnable: isBtnEnable,
                  callback: () {
                    onCheckOutBtnClick();
                  },
                )),
            if (isLoading == true) CircularProgress()
          ],
        ));
  }

  void getCurrentLocation() async {
    location.getLocation().then((location) {
      print("Accuracy: ${location.accuracy}");
      setState(() {
        currentLocation = location;
      });
      LatLng initialLatLng = LatLng(location.latitude!, location.longitude!);
      initialCameraPosition = CameraPosition(
        target: initialLatLng,
        zoom: 16,
      );
      polyline.insert(0, initialLatLng);
      getLocationData();
      setState(() {});
    });
  }

  getLocationData() async {
    database.once().then(
      (event) async {
        final data = event.snapshot.value as Map;
        DeviceInfo deviceInfo = await getDeviceIdAndType();
        String deviceType = deviceInfo.deviceType;
        String? deviceId = deviceInfo.deviceId;

        if (deviceType != 'Unknown' && deviceId != null) {
          final userLocationData = data[deviceType] as Map<dynamic, dynamic>;
          userLocationData.forEach((key, value) {
            if (key == deviceId) {
              final locations = value as List<dynamic>;
              locations.asMap().forEach((index, location) {
                String latLngString = location['LatLng'];
                String locationTag = location['Location_Tag'];
                locationDataList.add(LocationDataModel(
                    index.toString(), locationTag, latLngString));

                List<String> latLngList = latLngString.split(',');
                double latitude = double.parse(latLngList[0]);
                double longitude = double.parse(latLngList[1]);

                if (index == 0) {
                  destination = LatLng(latitude, longitude);
                  backgroundLocationService();
                }

                polyline.insert(index + 1, LatLng(latitude, longitude));

                markerList.add(Marker(
                    markerId: MarkerId("markerId$index"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
                    infoWindow: InfoWindow(title: locationTag),
                    position: LatLng(latitude, longitude)));
              });
              setState(() {});
            }
          });
        }
      },
    );
  }

  backgroundLocationService() {
    locationSubscription = location.onLocationChanged.listen((newLocation) {
      polyline.clear();
      currentLocation = newLocation;
      updateMapAndPolyline(newLocation);

      print("@@##$newLocation");
    });
  }

  updateMapAndPolyline(LocationData newLocation) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(newLocation.latitude!, newLocation.longitude!),
            zoom: 16)));

    if (destination != null) {
      List<LatLng> remainPolyline = [];
      remainPolyline.insert(
          0, LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
      remainPolyline.insert(1, destination!);
      setState(() {
        polyline.addAll(remainPolyline);
      });
    }

    final distance = LocationTrackingManager().distanceBetweenCoordinates(
        newLocation.latitude!,
        newLocation.longitude!,
        destination!.latitude,
        destination!.longitude);
    print("Distance: $distance");
    if (distance <= 100) {
      setState(() {
        isBtnEnable = true;
      });
    }
  }

  onCheckOutBtnClick() async {
    final isBackgroundModeEnabled = await location.isBackgroundModeEnabled();
    if (isBackgroundModeEnabled) {
      location.enableBackgroundMode(enable: false);
      locationSubscription?.cancel();
      if(!mounted) return;
      Navigator.pop(context);
    }
  }
}