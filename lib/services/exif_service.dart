import 'dart:io';

import 'package:exif/exif.dart';

class ExifService {
  ExifService._internal();
  static final ExifService _instance = ExifService._internal();
  factory ExifService() => _instance;

  /// Extract GPS coordinates from photo EXIF data
  Future<Map<String, double>?> extractGpsFromPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      print('EXIF Data: $data');

      if (data.isEmpty) return null;

      // Get GPS data
      final gpsLat = data['GPS GPSLatitude'];
      final gpsLatRef = data['GPS GPSLatitudeRef'];
      final gpsLng = data['GPS GPSLongitude'];
      final gpsLngRef = data['GPS GPSLongitudeRef'];

      if (gpsLat == null || gpsLatRef == null || gpsLng == null || gpsLngRef == null) {
        return null;
      }

      // Convert GPS coordinates to decimal degrees
      final latitude = _convertGpsToDecimal(gpsLat.printable, gpsLatRef.printable);
      final longitude = _convertGpsToDecimal(gpsLng.printable, gpsLngRef.printable);

      if (latitude == null || longitude == null) return null;

      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      // print('Error extracting EXIF GPS: $e');
      return null;
    }
  }

  /// Convert GPS coordinate from EXIF format to decimal degrees
  double? _convertGpsToDecimal(String coordinate, String ref) {
    try {
      // Format: [46, 1, 37, 1, 2819, 100] atau "46/1, 37/1, 2819/100"
      final parts = coordinate
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();

      if (parts.length < 3) return null;

      double degrees = _parseFraction(parts[0]);
      double minutes = _parseFraction(parts[1]);
      double seconds = _parseFraction(parts[2]);

      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      // Apply reference (N/S for latitude, E/W for longitude)
      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      // print('Error converting GPS coordinate: $e');
      return null;
    }
  }

  /// Parse fraction string like "46/1" to decimal
  double _parseFraction(String fraction) {
    if (fraction.contains('/')) {
      final parts = fraction.split('/');
      final numerator = double.tryParse(parts[0]) ?? 0;
      final denominator = double.tryParse(parts[1]) ?? 1;
      return numerator / denominator;
    }
    return double.tryParse(fraction) ?? 0;
  }
}
