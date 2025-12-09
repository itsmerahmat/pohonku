import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;

  /// Meminta permission lokasi dan mengambil posisi terkini.
  /// Jika user menolak atau GPS bermasalah, fungsi akan mengembalikan null.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }
}
