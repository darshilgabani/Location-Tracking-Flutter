import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/custom/custom_btn.dart';
import 'package:location_tracking_flutter/utils/helper.dart';
import 'package:location_tracking_flutter/utils/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location_tracking_flutter/ui/screen_location_list/location_data_manager.dart';
import 'package:location_tracking_flutter/model/model_location_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:location_tracking_flutter/ui/screen_add_location/add_location_screen.dart';
import 'package:location_tracking_flutter/ui/screen_location_tracking/location_tracking_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  DatabaseReference database = FirebaseDatabase.instance.ref();
  final TextEditingController _textEditingController = TextEditingController();
  List<LocationDataModel> locationDataList = [];
  LocationDataManager locationDataManager = LocationDataManager();

  @override
  void initState() {
    super.initState();
    locationDataManager.getLocationData().then(
      (value) {
        setState(() {
          locationDataList.addAll(value);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Card> cards = <Card>[
      for (int index = 0; index < locationDataList.length; index += 1)
        Card(
          key: Key('$index'),
          color: themeShadeOfOrangeColor,
          child: GestureDetector(
            onTap: () {
              final LocationDataModel locationDataModel =
                  locationDataList[index];
              showUpdateDeleteLocationDialog(locationDataModel, index);
            },
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: Draggable(
                      feedback: Icon(Icons.drag_indicator_rounded,
                          color: Colors.grey),
                      data: index,
                      child: Icon(Icons.drag_indicator_rounded,
                          color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                      child: Text(
                        '${index + 1}. ${locationDataList[index].locationTag}',
                        style: TextStyle(
                          fontSize: 20,
                          color: themeOrangeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];

    Widget proxyDecorator(
        Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double elevation = lerpDouble(1, 6, animValue)!;
          final double scale = lerpDouble(1, 1.02, animValue)!;
          return Transform.scale(
            scale: scale,
            child: Card(
              elevation: elevation,
              color: cards[index].color,
              child: cards[index].child,
            ),
          );
        },
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor(context),
        title: Text(
          titleLocationListScreen,
          style: appBarTextStyle,
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              checkPermission(Permission.location).then(
                (isGranted) {
                  if (!context.mounted) return;
                  if (isGranted) {
                    toNavigate(context, AddLocationScreen());
                    showSnackBar(context, permissionGranted);
                  } else {
                    showSnackBar(context, permissionDenied);
                  }
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Icon(
                Icons.add,
                color: themeWhiteColor,
                size: 25,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                proxyDecorator: proxyDecorator,
                children: cards,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final LocationDataModel item =
                        locationDataList.removeAt(oldIndex);
                    locationDataList.insert(newIndex, item);
                  });
                  locationDataManager.updateDraggedCardIndex(
                    locationDataList,
                    () {
                      setState(() {});
                    },
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: CustomButton(
                  btnName: lblStartBtn,
                  callback: () {
                    checkLocationPermission(
                      context,
                      () {
                        toNavigate(context, LocationTrackingScreen());
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showUpdateDeleteLocationDialog(
      LocationDataModel locationDataModel, int index) {
    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: themeOrangeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );

    final textStyle = TextStyle(color: themeWhiteColor);

    _textEditingController.text = locationDataModel.locationTag!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeShadeOfOrangeColor,
          title: Text(updateDeleteDialogTitle,
              style: TextStyle(
                  color: themeOrangeColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _textEditingController,
            cursorColor: themeOrangeColor,
            decoration: InputDecoration(
              hintText: updateDeleteDialogHintText,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: themeOrangeColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: themeOrangeColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                      style: elevatedButtonStyle,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        updateDeleteDialogCancelBtn,
                        style: textStyle,
                      )),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                      style: elevatedButtonStyle,
                      onPressed: () {
                        locationDataManager.deleteLocationData(
                          locationDataModel,
                          locationDataList,
                          index,
                          () {
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                        );
                      },
                      child: Text(
                        updateDeleteDialogDeleteBtn,
                        style: textStyle,
                      )),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                      style: elevatedButtonStyle,
                      onPressed: () {
                        String updatedLocationTag = _textEditingController.text;
                        if (updatedLocationTag != "") {
                          locationDataManager.updateLocationTagName(
                            locationDataList,
                            updatedLocationTag,
                            index,
                            () {
                              Navigator.of(context).pop();
                              setState(() {});
                            },
                          );
                        } else {
                          showSnackBar(context, updateDeleteDialogEmptyTextError);
                        }
                      },
                      child: Text(
                        updateDeleteDialogUpdateBtn,
                        style: textStyle,
                      )),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<bool> checkPermission(PermissionWithService permissionType) async {
    final permissionGranted = await permissionType.status;
    var isGranted = false;
    if (permissionGranted == PermissionStatus.denied) {
      var permission = await permissionType.request();
      isGranted = (permission == PermissionStatus.granted);
    } else if (permissionGranted == PermissionStatus.granted) {
      isGranted = true;
    } else if (permissionGranted == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    return isGranted;
  }
}
