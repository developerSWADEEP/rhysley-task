class LocationRequest {
  final int userId;
  final double lat;
  final double lng;

  LocationRequest({required this.userId, required this.lat, required this.lng});

  Map<String, dynamic> toJson() {
    return {"user_id": userId, "lat": lat, "lng": lng};
  }
}
