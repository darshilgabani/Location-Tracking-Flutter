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

  bool isTrackingBtnEnable = false;
  bool isResumeBtnEnable = false;
  bool isWorkCompleted = false;
  String trackingBtnName = "";

  @override
  void initState() {
    super.initState();
    fetchLocationData();
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
                    child: Icon(Icons.drag_indicator_rounded,
                        color: Colors.grey),
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
                  if(locationDataList[index].isWorkedDone == true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 20, 0),
                    child: Icon(Icons.done_outline_sharp, color: Colors.green),
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
                    toNavigate(context, widget);
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
                child: locationDataList.isNotEmpty
                    ? ReorderableListView(
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
                )
                    : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(
                        emptyLocationDataListMsg,
                        style: TextStyle(
                            color: themeOrangeColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ))),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: CustomButton(
                  btnName: trackingBtnName.isNotEmpty
                      ? trackingBtnName
                      : getTrackingBtnName(),
                  isBtnEnable: isTrackingBtnEnable || isResumeBtnEnable,
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
              children: [
                Expanded(
                  child: CustomButton(
                    btnName: updateDeleteDialogCancelBtn,
                    isPaddingEnable: false,
                    fontSize: 13,
                    callback: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: CustomButton(
                    btnName: updateDeleteDialogDeleteBtn,
                    isPaddingEnable: false,
                    fontSize: 13,
                    callback: () {
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
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: CustomButton(
                    btnName: updateDeleteDialogUpdateBtn,
                    isPaddingEnable: false,
                    fontSize: 13,
                    callback: () {
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
                  ),
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

  Future<void> fetchLocationData() async {
    await locationDataManager.getLocationData();

    locationDataManager.locationDataStream.listen((list) {
      setState(() {
        locationDataList.clear();
        locationDataList.addAll(list);
        trackingBtnName = "";
        for (final (index, element) in locationDataList.indexed) {
          if (index == 0 && element.isWorkedDone == false) {
            isTrackingBtnEnable = true;
            isResumeBtnEnable = false;
          } else if (index == 0 && element.isWorkedDone == true) {
            isTrackingBtnEnable = false;
            isResumeBtnEnable = true;
          }

          if (index == (locationDataList.length - 1) &&
              element.isWorkedDone == true) {
            isTrackingBtnEnable = false;
            isResumeBtnEnable = false;
            trackingBtnName = lblWorkCompletedBtn;
          }
        }
      });
    });
  }

  String getTrackingBtnName() {
    return isTrackingBtnEnable ? lblStartBtn : lblResumeBtn;
  }
}
