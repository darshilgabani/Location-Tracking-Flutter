import 'dart:math';

import 'package:location_tracking_flutter/ui/screen_location_tracking/shared_preferences_helper.dart';
import 'package:location_tracking_flutter/utils/constants.dart';

class LocationTrackingManager {
  static double distanceBetweenCoordinates(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    var earthRadius = 6378137.0;
    var dLat = _toRadians(endLatitude - startLatitude);
    var dLon = _toRadians(endLongitude - startLongitude);

    var a = pow(sin(dLat / 2), 2) +
        pow(sin(dLon / 2), 2) *
            cos(_toRadians(startLatitude)) *
            cos(_toRadians(endLatitude));
    var c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static _toRadians(double degree) {
    return degree * pi / 180;
  }

  static Duration getTotalDuration(int time1, int time2) {
    DateTime dateTime1 = DateTime.fromMicrosecondsSinceEpoch(time1);
    DateTime dateTime2 = DateTime.fromMicrosecondsSinceEpoch(time2);
    return dateTime1.difference(dateTime2);
  }

  static Future<Duration> getSportIdleTime() async {
    int? sportLastActivityTime = await SharedPreferencesHelper.getTime(sportLastActivityTimeKey);
    int currentTime = DateTime.now().microsecondsSinceEpoch;
    Duration idleSportDuration = getTotalDuration(currentTime, sportLastActivityTime!);
    return idleSportDuration;
  }
}
