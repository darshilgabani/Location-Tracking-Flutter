import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:location/location.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';

void toNavigate(BuildContext context, Widget widget) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => widget),
  );
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<DeviceInfo> getDeviceIdAndType() async {
  var deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    var iosDeviceInfo = await deviceInfo.iosInfo;
    return DeviceInfo(iosDeviceInfo.identifierForVendor, 'iOS');
  } else if (Platform.isAndroid) {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    return DeviceInfo(androidDeviceInfo.id.replaceAll('.', ''), 'Android');
  }
  return DeviceInfo(null, 'Unknown');
}

checkLocationPermission(
  BuildContext context,
  Function() callback,
) async {
  final permissionGranted = await Permission.locationAlways.isGranted;
  if (!permissionGranted) {
    if (Platform.isAndroid) {
      if (!context.mounted) return;
      showSettingsDialog(context);
    } else if (Platform.isIOS) {
      await Location().requestPermission().then(
        (value) {
          if (!permissionGranted) {
            showSettingsDialog(context);
          } else {
            callback.call();
          }
        },
      );
    }
  } else {
    if (!context.mounted) return;
    callback.call();
  }
}

showSettingsDialog(BuildContext context) {
  if (Platform.isAndroid) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: themeShadeOfOrangeColor,
        title: Text(lblAlwaysAllowLocationPermission),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(lblNotNowBtn,style: TextStyle(color: themeOrangeColor)),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text(lblSettingsBtn,style: TextStyle(color: themeOrangeColor)),
          ),
        ],
      ),
    );
  } else if (Platform.isIOS) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(lblAlwaysAllowLocationPermission),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            textStyle: TextStyle(color: themeOrangeColor),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(lblNotNowBtn),
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: themeOrangeColor),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(lblSettingsBtn),
          ),
        ],
      ),
    );
  }
}
