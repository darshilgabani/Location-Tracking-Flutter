import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:location_tracking_flutter/utils/custom/custom_btn.dart';
import 'package:location_tracking_flutter/utils/helper.dart';
import 'package:location_tracking_flutter/utils/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  @override
  Widget build(BuildContext context) {
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
          children: const [
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                children: [],
              )),
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
}
