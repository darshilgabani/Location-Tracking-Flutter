import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:permission_handler/permission_handler.dart';

void toNavigate(BuildContext context, Widget widget) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => widget),
  );
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
