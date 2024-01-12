import 'package:firebase_database/firebase_database.dart';
import 'package:location_tracking_flutter/model/model_device_info.dart';
import 'package:location_tracking_flutter/model/model_location_data.dart';
import 'package:location_tracking_flutter/utils/helper.dart';

class LocationDataManager {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  Future<List<LocationDataModel>> getLocationData() async {
    List<LocationDataModel> locationDataList = [];

    try {
      var event = await database.once();
      final data = event.snapshot.value as Map;
      DeviceInfo deviceInfo = await getDeviceIdAndType();
      String deviceType = deviceInfo.deviceType;
      String? deviceId = deviceInfo.deviceId;

      if (deviceType != 'Unknown' && deviceId != null) {
        final userLocationData = data[deviceType] as Map<dynamic, dynamic>;
        userLocationData.forEach((key, value) {
          if (key == deviceId) {
            final locations = value as List<dynamic>;
            locations.asMap().forEach((index, location) {
              String latLng = location['LatLng'];
              String locationTag = location['Location_Tag'];
              bool isWorkedDone = location['Worked_Done'];
              locationDataList.add(LocationDataModel(
                  index.toString(), locationTag, latLng, isWorkedDone));
            });
          }
        });
      }
    } catch (e) {
      print('Error fetching location data: $e');
    }

    return locationDataList;
  }

  Future<void> deleteLocationData(
    LocationDataModel locationDataModel,
    List<LocationDataModel> locationDataList,
    int index,
    Function() callback,
  ) async {
    if (index >= 0 && index < locationDataList.length) {
      locationDataList.remove(locationDataModel);

      DeviceInfo? deviceInfo = await getDeviceIdAndType();
      String? deviceId = deviceInfo.deviceId;
      String deviceType = deviceInfo.deviceType;

      Map<String, Object> locationDataObject = {};

      List<LocationDataModel> locationDataNewList = [];
      locationDataNewList.addAll(locationDataList);

      for (var i = 0; i < locationDataNewList.length; i++) {
        var item = locationDataNewList[i];
        var object = {
          "LatLng": item.latLng,
          "Location_Tag": item.locationTag,
        };
        locationDataObject[i.toString()] = object;
      }

      await database
          .child(deviceType.toString())
          .child(deviceId.toString())
          .set(locationDataObject)
          .then((_) {
        callback.call();
      }).catchError((error) {
        print("Error updating Firebase: $error");
      });
    }
  }

  Future<void> updateLocationTagName(
    List<LocationDataModel> locationDataList,
    String updatedLocationTag,
    int index,
    Function() callback,
  ) async {
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .child(index.toString())
        .child("Location_Tag")
        .set(updatedLocationTag)
        .whenComplete(
      () {
        var currentLocationData = locationDataList.elementAt(index);
        var updatedLocationData = LocationDataModel(
          currentLocationData.markerId,
          updatedLocationTag,
          currentLocationData.latLng,
          currentLocationData.isWorkedDone
        );
        locationDataList[index] = updatedLocationData;
        callback.call();
      },
    ).catchError((error) {
      print("Error updating Firebase: $error");
    });
  }

  Future<void> updateDraggedCardIndex(
    List<LocationDataModel> locationDataList,
    Function() callback,
  ) async {
    DeviceInfo? deviceInfo = await getDeviceIdAndType();
    String? deviceId = deviceInfo.deviceId;
    String deviceType = deviceInfo.deviceType;

    Map<String, Object> locationDataObject = {};

    List<LocationDataModel> locationDataNewList = [];
    locationDataNewList.addAll(locationDataList);

    for (var i = 0; i < locationDataNewList.length; i++) {
      var item = locationDataNewList[i];
      var object = {
        "LatLng": item.latLng,
        "Location_Tag": item.locationTag,
      };
      locationDataObject[i.toString()] = object;
    }

    await database
        .child(deviceType.toString())
        .child(deviceId.toString())
        .set(locationDataObject)
        .then((_) {
      callback.call();
    }).catchError((error) {
      print("Error updating Firebase: $error");
    });
  }
}
