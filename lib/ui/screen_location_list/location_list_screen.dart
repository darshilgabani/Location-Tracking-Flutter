import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/custom/custom_btn.dart';
import 'package:location_tracking_flutter/utils/helper.dart';
import 'package:location_tracking_flutter/utils/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:location_tracking_flutter/model/model_location_data.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  DatabaseReference database = FirebaseDatabase.instance.ref();

  List<LocationDataModel> locationDataList = [];

  @override
  void initState() {
    super.initState();
    getLocationData();
  }

  @override
  Widget build(BuildContext context) {
    final List<Card> cards = <Card>[
      for (int index = 0; index < locationDataList.length; index += 1)
        Card(
          key: Key('$index'),
          color: themeShadeOfOrangeColor,
          child: SizedBox(
            height: 60,
            child: Center(
              child: Text(
                  '${index + 1}. ${locationDataList[index].locationTag}',
                  style: TextStyle(
                      fontSize: 20,
                      color: themeOrangeColor,
                      fontWeight: FontWeight.bold)),
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
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: CustomButton(btnName: lblStartBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getLocationData() {
    database.onValue.listen((event) async {
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
              String latLng = location['LatLng'];
              String locationTag = location['Location_Tag'];
              locationDataList.add(
                  LocationDataModel(index.toString(), locationTag, latLng));
            });
            setState(() {});
          }
        });
      }
    });
  }
}
