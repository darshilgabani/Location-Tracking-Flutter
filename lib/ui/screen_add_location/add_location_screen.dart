import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/theme.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:location_tracking_flutter/model/model_location_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:location_tracking_flutter/utils/custom/circular_progress.dart';
import 'package:location_tracking_flutter/utils/custom/custom_btn.dart';
import 'package:location_tracking_flutter/utils/helper.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  Location location = Location();
  CameraPosition? initialCameraPosition;
  DatabaseReference database = FirebaseDatabase.instance.ref();
  LocationData? currentLocation;
  bool isBtnEnable = false;
  bool isLoading = false;
  List<Marker> markerList = [];
  List<LocationDataModel> locationDataList = [];
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    getLocationData();
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
            titleAddLocationScreen,
            style: appBarTextStyle,
          ),
        ),
        body: Stack(
          children: [
            currentLocation == null || initialCameraPosition == null
                ? CircularProgress()
                : GoogleMap(
                    initialCameraPosition: initialCameraPosition!,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onTap: (latLng) {
                      showAddLocationDialog(latLng);
                    },
                    markers: Set<Marker>.of(markerList),
                  ),
            Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: CustomButton(
                  btnName: lblAddBtn,
                  isBtnEnable: isBtnEnable,
                  callback: () {
                    submitLocationData();
                  },
                )),
            if (isLoading == true) CircularProgress()
          ],
        ));
  }

  getCurrentLocation() async {
    location.getLocation().then((location) {
      currentLocation = location;
      LatLng initialLatLng = LatLng(location.latitude!, location.longitude!);
      initialCameraPosition = CameraPosition(
        target: initialLatLng,
        zoom: 16,
      );
      setState(() {});
    });
  }

  showAddLocationDialog(LatLng latLng) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeShadeOfOrangeColor,
          title: Text(addDialogTitle,
              style: TextStyle(
                  color: themeDarkOrangeColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _textEditingController,
            cursorColor: themeDarkOrangeColor,
            decoration: InputDecoration(
              hintText: addDialogHintText,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: themeDarkOrangeColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: themeDarkOrangeColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            CustomButton(
              btnName: addDialogCancelBtn,
              isPaddingEnable: false,
              width: MediaQuery.of(context).size.width * 0.3,
              callback: () {
                Navigator.of(context).pop();
              },
            ),
            CustomButton(
              btnName: addDialogAddBtn,
              isPaddingEnable: false,
              width: MediaQuery.of(context).size.width * 0.3,
              callback: () {
                String locationTag = _textEditingController.text;

                if (locationTag != "") {
                  addLocation(latLng, locationTag);
                  _textEditingController.clear();
                  Navigator.of(context).pop();
                } else {
                  showSnackBar(context, addDialogEmptyTextError);
                }
                print('Text entered: $locationTag');
              },
            ),
          ],
        );
      },
    );
  }

  addLocation(LatLng latLng, String locationTag) {
    int index = markerList.length;
    markerList.add(Marker(
        markerId: MarkerId("markerId$index"),
        // icon: BitmapDescriptor.defaultMarker,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: locationTag),
        position: latLng));
    if (markerList.isNotEmpty) {
      isBtnEnable = true;
    }
    String latLngString = "${latLng.latitude},${latLng.longitude}";
    locationDataList.add(
        LocationDataModel(index.toString(), locationTag, latLngString, false,false,false));
    setState(() {});
  }

  submitLocationData() async {
    try {
      DeviceInfo? deviceInfo = await getDeviceIdAndType();
      String? deviceId = deviceInfo.deviceId;
      String deviceType = deviceInfo.deviceType;

      Map<String, Object> locationDataObject = {};

      for (var item in locationDataList) {
        var object = {
          "LatLng": item.latLng,
          "Location_Tag": item.locationTag,
          "Worked_Done": item.isWorkedDone,
        };
        locationDataObject[item.markerId!] = object;
      }

      if (deviceId != null && deviceType != "Unknown") {
        setState(() {
          isLoading = true;
        });
        await database
            .child(deviceType.toString())
            .child(deviceId.toString())
            .update(locationDataObject)
            .whenComplete(
          () {
            setState(() {
              isLoading = false;
            });
            showSnackBar(context, dataAddSuccess);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      print('Error submitting data: $e');
    }
  }

  getLocationData() {
    database.once().then(
      (event) async {
        final data = event.snapshot.value as Map;
        DeviceInfo deviceInfo = await getDeviceIdAndType();
        String deviceType = deviceInfo.deviceType;
        String? deviceId = deviceInfo.deviceId;
        print(data);

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
                    index.toString(), locationTag, latLngString, isWorkedDone,isCheckedIn,isCheckedOut));

                List<String> latLngList = latLngString.split(',');
                double latitude = double.parse(latLngList[0]);
                double longitude = double.parse(latLngList[1]);

                markerList.add(Marker(
                    markerId: MarkerId("markerId$index"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange),
                    infoWindow: InfoWindow(title: locationTag),
                    position: LatLng(latitude, longitude)));

                if (markerList.isNotEmpty) {
                  isBtnEnable = true;
                }
              });
              setState(() {});
            }
          });
        }
      },
    );
  }
}
