import 'package:treedocs/models/photo_model.dart';

class TreeModel {
  int? id;
  final String varietas;
  final String blok;
  final String nomorPohon;
  final double? latitude;
  final double? longitude;
  final DateTime tanggalPengambilan;
  final String deviceName;
  final String fileType;
  final List<PhotoModel> photos;

  TreeModel({
    this.id,
    required this.varietas,
    required this.blok,
    required this.nomorPohon,
    required this.latitude,
    required this.longitude,
    required this.tanggalPengambilan,
    required this.deviceName,
    required this.fileType,
    required this.photos,
  });

  factory TreeModel.fromMap(Map<String, dynamic> map, List<PhotoModel> photos) {
    return TreeModel(
      id: map['id'] as int?,
      varietas: map['varietas'] as String,
      blok: map['blok'] as String,
      nomorPohon: map['nomor_pohon'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      tanggalPengambilan: DateTime.parse(map['tanggal_pengambilan'] as String),
      deviceName: map['device_name'] as String,
      fileType: map['file_type'] as String,
      photos: photos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'varietas': varietas,
      'blok': blok,
      'nomor_pohon': nomorPohon,
      'latitude': latitude,
      'longitude': longitude,
      'tanggal_pengambilan': tanggalPengambilan.toIso8601String(),
      'device_name': deviceName,
      'file_type': fileType,
    };
  }
}
