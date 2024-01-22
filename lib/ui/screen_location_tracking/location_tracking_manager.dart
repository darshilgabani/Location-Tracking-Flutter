import 'dart:convert';
import 'dart:math';

import 'package:location_tracking_flutter/ui/screen_location_tracking/shared_preferences_helper.dart';
import 'package:location_tracking_flutter/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IdleTimeType { inHours, inMinutes, inSeconds }

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

  static Future<dynamic>? getSportIdleTime() async {
    final prefs = await SharedPreferences.getInstance();
    String idleSportStringList = prefs.getString(idleSportStringListKey) ?? "";
    Map<String, dynamic>? idleSportDataMap = {};

    if (idleSportStringList != "") {
      try {
        idleSportDataMap.addAll(jsonDecode(idleSportStringList));
        return idleSportDataMap;
      } catch (e) {
        print("Error decoding existingIdleData: $e");
      }
    } else {
      return "The user never has any free time.";
    }
  }

  static Future<bool?> setSportIdleTime(
      IdleTimeType idleTimeType, int idleTimeDuration, int index) async {
    final prefs = await SharedPreferences.getInstance();
    Duration idleSportDuration;
    Map<String, dynamic> existingIdleDataMap;

    int? sportLastActivityTime =
        await SharedPreferencesHelper.getTime(sportLastActivityTimeKey);

    if (sportLastActivityTime == null) {
      await SharedPreferencesHelper.submitTime(sportLastActivityTimeKey);
      return false;
    } else {
      DateTime currentTime = DateTime.now();
      idleSportDuration = getTotalDuration(currentTime.microsecondsSinceEpoch, sportLastActivityTime);

      if (idleSportDuration.inHours > idleTimeDuration ||
          idleSportDuration.inMinutes > idleTimeDuration ||
          idleSportDuration.inSeconds > idleTimeDuration) {
        String idleSportStringList =
            prefs.getString(idleSportStringListKey) ?? "";

        Map<String, dynamic> idleDataObject = {
          index.toString(): {
            "Idle_Start_Time": DateTime.fromMicrosecondsSinceEpoch(sportLastActivityTime).toString(),
            "Idle_End_Time": currentTime.toString(),
            "Idle_Duration": idleSportDuration.toString()
          }
        };

        if (idleSportStringList != "") {
          try {
            final jsonDecoded = jsonDecode(idleSportStringList);
            if (jsonDecoded != null) {
              existingIdleDataMap = jsonDecoded;
              // existingIdleDataMap.addAll(jsonDecoded);
              existingIdleDataMap.addAll(idleDataObject);
              print(existingIdleDataMap);
              final jsonExistingIdleMapEncoded =
                  jsonEncode(existingIdleDataMap);
              print(jsonExistingIdleMapEncoded);
              prefs.setString(idleSportStringListKey,
                  jsonExistingIdleMapEncoded.toString());
              await SharedPreferencesHelper.submitTime(sportLastActivityTimeKey);
              return true;
            }
          } catch (e) {
            print("Error decoding existingIdleData: $e");
          }
        } else {
          final jsonEncoded = jsonEncode(idleDataObject);
          print(jsonEncoded);
          prefs.setString(idleSportStringListKey, jsonEncoded.toString());
          await SharedPreferencesHelper.submitTime(sportLastActivityTimeKey);
          return true;
        }
      } else {
        await SharedPreferencesHelper.submitTime(sportLastActivityTimeKey);
        return false;
      }
    }
    return null;
  }

// static Future<dynamic> getSportIdleTime(
//     IdleTimeType idleTimeType, int idleTimeDuration) async {
//   int? sportLastActivityTime =
//   await SharedPreferencesHelper.getTime(sportLastActivityTimeKey);
//   int currentTime = DateTime.now().microsecondsSinceEpoch;
//   Duration idleSportDuration =
//   getTotalDuration(currentTime, sportLastActivityTime!);
//
//   switch (idleTimeType) {
//     case IdleTimeType.inHours:
//       if (idleSportDuration.inHours > idleTimeDuration) {
//         return idleSportDuration.inHours;
//       }
//     case IdleTimeType.inMinutes:
//       if (idleSportDuration.inMinutes > idleTimeDuration) {
//         return idleSportDuration.inMinutes;
//       }
//     case IdleTimeType.inSeconds:
//       if (idleSportDuration.inSeconds > idleTimeDuration) {
//         return idleSportDuration.inSeconds;
//       }
//     default:
//       return null;
//   }
// }
}
