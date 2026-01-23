import 'photo_model.dart';

/// Model data pohon yang mencakup informasi lokasi, metadata, dan foto-foto.
///
/// Setiap pohon memiliki:
/// - Identitas: varietas, blok, dan nomor pohon
/// - Lokasi: koordinat GPS (latitude & longitude)
/// - Metadata: tanggal pengambilan, device, tipe file
/// - Foto: daftar foto pohon (minimal 4 foto)
class TreeModel {
  /// ID unik dari database (null jika belum disimpan).
  int? id;

  /// Jenis/varietas pohon (contoh: Sawit, Karet).
  final String varietas;

  /// Kode blok lokasi pohon (contoh: A1, B2).
  final String blok;

  /// Nomor identifikasi pohon dalam blok.
  final String nomorPohon;

  /// Koordinat latitude GPS (null jika tidak tersedia).
  final double? latitude;

  /// Koordinat longitude GPS (null jika tidak tersedia).
  final double? longitude;

  /// Waktu pengambilan data pohon.
  final DateTime tanggalPengambilan;

  /// Nama perangkat yang digunakan untuk dokumentasi.
  final String deviceName;

  /// Ekstensi file foto (contoh: jpg, png).
  final String fileType;

  /// Daftar foto pohon.
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

  /// Membuat instance dari Map database.
  factory TreeModel.fromMap(Map<String, dynamic> map, List<PhotoModel> photos) {
    return TreeModel(
      id: map['id'] as int?,
      varietas: map['varietas'] as String,
      blok: map['blok'] as String,
      nomorPohon: map['nomor_pohon'] as String,
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      tanggalPengambilan: DateTime.parse(map['tanggal_pengambilan'] as String),
      deviceName: map['device_name'] as String,
      fileType: map['file_type'] as String,
      photos: photos,
    );
  }

  /// Mengkonversi ke Map untuk penyimpanan database.
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
