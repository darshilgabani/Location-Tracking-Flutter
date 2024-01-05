import 'package:flutter/material.dart';
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
