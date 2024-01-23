class LocationDataModel {
  final String? markerId;
  final String? locationTag;
  final String? latLng;
  final bool? isCheckedIn;
  final bool? isCheckedOut;
  final bool? isWorkedDone;

  LocationDataModel(this.markerId, this.locationTag, this.latLng,
      this.isWorkedDone, this.isCheckedIn, this.isCheckedOut);
}
