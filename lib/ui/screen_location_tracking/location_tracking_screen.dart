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
import 'package:location_tracking_flutter/ui/screen_location_tracking/shared_preferences_helper.dart';

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
  int sportIndex = 0;
  bool destinationSet = false;
  int sportIdleIndex = 0;
  bool sportCheckedInStatus = false;
  bool sportCheckedOutStatus = false;

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
                    onTap: (argument) {
                      onSportActivity();
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
                          submitGoodByeStatus();
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
                String locationTag = location[locationTagKey];
                bool isWorkedDone = location[workDoneKey];
                bool isCheckedIn = location[checkedInKey];
                bool isCheckedOut = location[checkedOutKey];
                locationDataList.add(LocationDataModel(
                    index.toString(),
                    locationTag,
                    latLngString,
                    isWorkedDone,
                    isCheckedIn,
                    isCheckedOut));

                List<String> latLngList = latLngString.split(',');
                double latitude = double.parse(latLngList[0]);
                double longitude = double.parse(latLngList[1]);

                if (sportIndex == index) {
                  sportCheckedInStatus = isCheckedIn;
                  sportCheckedOutStatus = isCheckedOut;
                  if (sportCheckedInStatus == true &&
                      sportCheckedOutStatus == false) {
                    isSportCheckOutBtnEnable = true;
                    isSportCheckInBtnEnable = false;
                  } else if (sportCheckedInStatus == false &&
                      sportCheckedOutStatus == false) {
                    isSportCheckOutBtnEnable = false;
                    isSportCheckInBtnEnable = false;
                  } else if (sportCheckedInStatus == true &&
                      sportCheckedOutStatus == true) {
                    isSportCheckOutBtnEnable = false;
                    isSportCheckInBtnEnable = false;
                  }
                }

                if (destinationSet == false && isWorkedDone == false) {
                  destination = LatLng(latitude, longitude);
                  backgroundLocationService();
                  destinationSet = true;
                } else if (isWorkedDone == true) {
                  destinationLocationIndex++;
                  sportIndex++;
                }

                remainPolyline.add(LatLng(latitude, longitude));

                if (isWorkedDone == false) {
                  circleList.add(Circle(
                      circleId: CircleId("circleId$index"),
                      center: LatLng(latitude, longitude),
                      radius: 100,
                      fillColor: mapCircleFillColor,
                      strokeColor: mapCircleStrokeColor,
                      strokeWidth: 1));
                }
                polyline.addAll(remainPolyline);

                markerList.add(Marker(
                    markerId: MarkerId("markerId$index"),
                    icon: isWorkedDone == true
                        ? BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen)
                        : BitmapDescriptor.defaultMarkerWithHue(
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
      currentLocation = newLocation;
      updateMapAndPolyline(newLocation);
      print("@@##$newLocation");
    });
  }

  stopBackgroundLocationService() async {
    final isBackgroundModeEnabled = await location.isBackgroundModeEnabled();
    if (isBackgroundModeEnabled) {
      location.enableBackgroundMode(enable: false);
      locationSubscription?.cancel();
      if (!mounted) return;
    }
  }

  updateMapAndPolyline(LocationData newLocation) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(newLocation.latitude!, newLocation.longitude!),
            zoom: 16)));

    updateLiveLocation();

    if (destination != null) {
      final distance = LocationTrackingManager.distanceBetweenCoordinates(
          newLocation.latitude!,
          newLocation.longitude!,
          destination!.latitude,
          destination!.longitude);

      print("Distance: $distance");

      if (distance <= 100) {
        if (circleList.isNotEmpty) {
          circleList.removeAt(0);
        }

        if (destinationLocationIndex < locationDataList.length) {
          if (destinationLocationIndex != locationDataList.length - 1) {
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
                0,
                LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!));

            if (destinationLocationIndex == 0) {
              destinationLocationIndex++;
              remainPolyline.removeAt(0);
            } else {
              remainPolyline.removeRange(0, destinationLocationIndex);
              destinationLocationIndex++;
            }

            polyline.addAll(remainPolyline);

            if (sportCheckedInStatus == false &&
                sportCheckedOutStatus == false) {
              isSportCheckInBtnEnable = true;
              isSportCheckOutBtnEnable = false;
            } else {
              isSportCheckInBtnEnable = true;
            }
            setState(() {});
          } else if (destinationLocationIndex == locationDataList.length - 1) {
            if (sportCheckedInStatus == true &&
                sportCheckedOutStatus == false) {
              isSportCheckOutBtnEnable = true;
              isSportCheckInBtnEnable = false;
            } else if (sportCheckedInStatus == false &&
                sportCheckedOutStatus == false) {
              isSportCheckOutBtnEnable = false;
              isSportCheckInBtnEnable = true;
            } else if (sportCheckedInStatus == true &&
                sportCheckedOutStatus == true) {
              isSportCheckOutBtnEnable = false;
              isSportCheckInBtnEnable = false;
            } else {
              isSportCheckInBtnEnable = true;
            }
            polyline.clear();
            destination = null;
            setState(() {});
          } else {
            destination = null;
          }
        }
      }
    }
  }

  updateLiveLocation() {
    if (destination != null) {
      if (polyline.isNotEmpty) {
        polyline.removeAt(0);
        polyline.insert(
            0, LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  onSportCheckInBtnClick() async {
    SharedPreferencesHelper.submitTime(sportLastActivityTimeKey);
    final locationDataModel = locationDataList[sportIndex];
    String? locationTag = locationDataModel.locationTag;

    if (sportIndex == 0) {
      await SharedPreferencesHelper.submitTime(dayCheckedInTimeKey);
    }

    final checkedInTime = DateTime.now().microsecondsSinceEpoch;
    await SharedPreferencesHelper.submitTime(checkedInTimeKey);
    await SharedPreferencesHelper.submitTime(sportCheckedInTimeKey);

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
        submitCheckedInStatus();
      },
    );
  }

  onSportCheckOutBtnClick() async {
    final locationDataModel = locationDataList[sportIndex];
    String? latLngString = locationDataModel.latLng;
    String? locationTag = locationDataModel.locationTag;
    List<String> latLngList = latLngString!.split(',');
    double latitude = double.parse(latLngList[0]);
    double longitude = double.parse(latLngList[1]);

    if (sportIndex == locationDataList.length - 1) {
      await SharedPreferencesHelper.submitTime(dayCheckedOutTimeKey);
    }

    markerList.add(Marker(
        markerId: MarkerId("markerId$sportIndex"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: locationTag),
        position: LatLng(latitude, longitude)));
    setState(() {});

    Map<String, Object> userDataObject = {};

    final checkInTime = await SharedPreferencesHelper.getTime(checkedInTimeKey);
    final checkOutTime = DateTime.now().microsecondsSinceEpoch;
    final duration =
        LocationTrackingManager.getTotalDuration(checkOutTime, checkInTime!);

    userDataObject = {
      checkedOutTimeKey: checkOutTime,
      workDurationKey: duration.toString(),
    };

    await database
        .child(userDbChildKey)
        .child(deviceId!)
        .child(sportIndex.toString())
        .update(userDataObject)
        .whenComplete(
      () {
        submitWorkDoneStatus();
        submitIdleDurationStatus();
      },
    );
  }

  submitWorkDoneStatus() async {
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child(checkedOutKey)
        .set(true);

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child(workDoneKey)
        .set(true)
        .whenComplete(
      () {
        if (sportIndex == locationDataList.length - 1) {
          isCheckOutBtnEnable = true;
          isSportCheckOutBtnEnable = false;
          isSportCheckInBtnEnable = false;
        } else {
          sportIndex++;
          isSportCheckOutBtnEnable = false;
        }
        showSnackBar(context, checkedOutSuccessMsg);
        setState(() {});
      },
    );
  }

  submitGoodByeStatus() async {
    final int? dayCheckedInTime =
        await SharedPreferencesHelper.getTime(dayCheckedInTimeKey);
    final int? dayCheckedOutTime =
        await SharedPreferencesHelper.getTime(dayCheckedOutTimeKey);

    final duration = LocationTrackingManager.getTotalDuration(
        dayCheckedOutTime!, dayCheckedInTime!);

    final object = {
      deviceId!: {
        dayCheckedInTimeKey: dayCheckedInTime,
        dayCheckedOutTimeKey: dayCheckedOutTime,
        workDurationKey: duration.toString(),
      }
    };

    await database.child(userIdleDbChildKey).set(object).whenComplete(
      () async {
        final isBackgroundModeEnabled =
            await location.isBackgroundModeEnabled();
        if (isBackgroundModeEnabled) {
          location.enableBackgroundMode(enable: false);
          locationSubscription?.cancel();
          if (!mounted) return;
          Navigator.pop(context);
        }
      },
    ).catchError((error) {
      print("Error: $error");
    });
  }

  onSportActivity() async {
    final value = await LocationTrackingManager.setSportIdleTime(
        IdleTimeType.inSeconds, 10, sportIdleIndex);
    if (value == true) {
      setState(() {
        sportIdleIndex++;
      });
    }
    print("onSportActivitySubmitted");
  }

  submitIdleDurationStatus() async {
    final idleSportDataMap = await LocationTrackingManager.getSportIdleTime();
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;
    print(idleSportDataMap);

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child(idleDurationKey)
        .set(idleSportDataMap)
        .whenComplete(
      () {
        SharedPreferencesHelper.clearPrefs(idleSportStringListKey);
        SharedPreferencesHelper.clearPrefs(sportLastActivityTimeKey);
        showSnackBar(context, "Idle Data Submitted Successfully!");
      },
    );
  }

  submitCheckedInStatus() async {
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child(checkedInKey)
        .set(true)
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

  submitCheckedOutStatus() async {
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(sportIndex.toString())
        .child(checkedOutKey)
        .set(true);
  }
}
