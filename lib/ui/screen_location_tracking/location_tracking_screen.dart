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
import 'package:shared_preferences/shared_preferences.dart';

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
  String? deviceId;
  LocationData? currentLocation;
  CameraPosition? initialCameraPosition;
  List<Marker> markerList = [];
  List<LocationDataModel> locationDataList = [];
  List<LatLng> polyline = [];
  List<LatLng> remainPolyline = [];
  bool isCheckOutBtnEnable = false;
  List<Circle> circleList = [];
  bool isSportCheckInBtnEnable = false;
  bool isSportCheckOutBtnEnable = false;
  bool isLoading = false;
  int destinationLocationIndex = 0;

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
                    circles: Set<Circle>.of(circleList),
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
            Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        btnName: isSportCheckInBtnEnable
                            ? lblSportCheckInBtn
                            : lblSportCheckOutBtn,
                        isBtnEnable:
                            isSportCheckInBtnEnable || isSportCheckOutBtnEnable,
                        isPaddingEnable: false,
                        callback: () {
                          // onSportCheckInBtnClick();
                          if (isSportCheckInBtnEnable) {
                            onSportCheckInBtnClick();
                          } else if (isSportCheckOutBtnEnable) {
                            onSportCheckOutBtnClick();
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        btnName: lblCheckoutBtn,
                        isBtnEnable: isCheckOutBtnEnable,
                        callback: () {
                          onCheckOutBtnClick();
                        },
                      ),
                    ),
                  ],
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
        deviceId = deviceInfo.deviceId;
        print("Device Id: $deviceId");
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

                remainPolyline.insert(index, LatLng(latitude, longitude));
                polyline.addAll(remainPolyline);

                markerList.add(Marker(
                    markerId: MarkerId("markerId$index"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
                    infoWindow: InfoWindow(title: locationTag),
                    position: LatLng(latitude, longitude)));

                circleList.add(Circle(
                    circleId: CircleId("circleId$index"),
                    center: LatLng(latitude, longitude),
                    radius: 100,
                    fillColor: mapCircleFillColor,
                    strokeColor: mapCircleStrokeColor,
                    strokeWidth: 1));
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

    updateLiveLocation();

    final distance = LocationTrackingManager().distanceBetweenCoordinates(
        newLocation.latitude!,
        newLocation.longitude!,
        destination!.latitude,
        destination!.longitude);

    print("Distance: $distance");

    if (distance <= 100) {
      circleList.removeAt(0);

      if (destinationLocationIndex < remainPolyline.length) {
        final locationDataModel =
            locationDataList.elementAt(destinationLocationIndex + 1);
        print(locationDataModel);

        String? latLngString = locationDataModel.latLng;
        List<String> latLngList = latLngString!.split(',');
        double latitude = double.parse(latLngList[0]);
        double longitude = double.parse(latLngList[1]);

        destination = LatLng(latitude, longitude);

        polyline.clear();
        polyline.insert(
            0, LatLng(currentLocation!.latitude!, currentLocation!.longitude!));

        if (destinationLocationIndex == 0) {
          destinationLocationIndex++;
          remainPolyline.removeAt(0);
        } else {
          remainPolyline.removeRange(0, destinationLocationIndex);
          destinationLocationIndex++;
        }

        polyline.addAll(remainPolyline);
      } else {
        destinationLocationIndex++;
        polyline.clear();
      }

      setState(() {
        isSportCheckInBtnEnable = true;
      });
    }
  }

  updateLiveLocation() {
    if (destination != null) {
      polyline.removeAt(0);
      polyline.insert(
          0, LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
      setState(() {});
    }
  }

  onCheckOutBtnClick() async {
    final isBackgroundModeEnabled = await location.isBackgroundModeEnabled();
    if (isBackgroundModeEnabled) {
      location.enableBackgroundMode(enable: false);
      locationSubscription?.cancel();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  onSportCheckInBtnClick() async {
    var prefs = await SharedPreferences.getInstance();
    final sportIndex = destinationLocationIndex - 1;
    final locationDataModel = locationDataList[sportIndex];
    String? locationTag = locationDataModel.locationTag;

    final checkedInTime = DateTime.now().microsecondsSinceEpoch;

    prefs.setInt(checkedInTimeKey, checkedInTime);

    Map<String, Object> userDataObject = {};

    userDataObject = {
      sportIndex.toString(): {
        checkedInTimeKey: checkedInTime,
        locationTagKey: locationTag,
      }
    };

    await database
        .child(userDbChildKey)
        .child(deviceId!)
        .update(userDataObject)
        .whenComplete(
      () {
        setState(() {
          isSportCheckInBtnEnable = false;
          isSportCheckOutBtnEnable = true;
        });
        showSnackBar(context, checkedInSuccessMsg);
      },
    );
  }

  onSportCheckOutBtnClick() async {
    var prefs = await SharedPreferences.getInstance();
    final sportIndex = destinationLocationIndex - 1;
    final locationDataModel = locationDataList[sportIndex];
    String? latLngString = locationDataModel.latLng;
    String? locationTag = locationDataModel.locationTag;
    List<String> latLngList = latLngString!.split(',');
    double latitude = double.parse(latLngList[0]);
    double longitude = double.parse(latLngList[1]);

    markerList.add(Marker(
        markerId: MarkerId("markerId$sportIndex"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: locationTag),
        position: LatLng(latitude, longitude)));
    setState(() {});

    Map<String, Object> userDataObject = {};

    final checkInTime = prefs.getInt(checkedInTimeKey);
    final checkOutTime = DateTime.now().microsecondsSinceEpoch;
    final duration = getTotalDuration(checkOutTime, checkInTime!);

    userDataObject = {
      checkedOutTimeKey: checkOutTime,
      durationKey: duration.toString(),
    };

    await database
        .child(userDbChildKey)
        .child(deviceId!)
        .child(sportIndex.toString())
        .update(userDataObject)
        .whenComplete(
      () {
        submitWorkDoneStatus(sportIndex);
      },
    );
  }

  submitWorkDoneStatus(int sportIndex) async {
    var prefs = await SharedPreferences.getInstance();
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child("Worked_Done")
        .set(true)
        .whenComplete(
      () {
        prefs.clear();
        if (sportIndex == locationDataList.length - 1) {
          isCheckOutBtnEnable = true;
        }
        isSportCheckOutBtnEnable = false;
        showSnackBar(context, checkedOutSuccessMsg);
        setState(() {});
      },
    );
  }

  Duration getTotalDuration(int time1, int time2) {
    DateTime dateTime1 = DateTime.fromMillisecondsSinceEpoch(time1);
    DateTime dateTime2 = DateTime.fromMillisecondsSinceEpoch(time2);
    return dateTime1.difference(dateTime2);
  }
}
