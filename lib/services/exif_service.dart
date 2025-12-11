import 'dart:io';

import 'package:native_exif/native_exif.dart';

class ExifService {
  ExifService._internal();
  static final ExifService _instance = ExifService._internal();
  factory ExifService() => _instance;

  /// Extract GPS coordinates from photo EXIF data
  Future<Map<String, double>?> extractGpsFromPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) return null;

      // Open EXIF reader
      final exif = await Exif.fromPath(photoPath);
      
      // Get GPS coordinates using native_exif getLatLong method
      final latLong = await exif.getLatLong();

      // Close EXIF interface
      await exif.close();

      if (latLong == null) return null;

      return {
        'latitude': latLong.latitude,
        'longitude': latLong.longitude,
      };
    } catch (e) {
      return null;
    }
  }

  /// Write GPS coordinates to photo EXIF data
  Future<bool> writeGpsToPhoto(String photoPath, double latitude, double longitude) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) return false;

      // Open EXIF writer
      final exif = await Exif.fromPath(photoPath);
      
      // Write GPS coordinates
      await exif.writeAttributes({
        'GPSLatitude': latitude.abs().toString(),
        'GPSLatitudeRef': latitude >= 0 ? 'N' : 'S',
        'GPSLongitude': longitude.abs().toString(),
        'GPSLongitudeRef': longitude >= 0 ? 'E' : 'W',
      });

      // Close EXIF interface
      await exif.close();

      return true;
    } catch (e) {
      return false;
    }
  }
}
