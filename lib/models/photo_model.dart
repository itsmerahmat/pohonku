/// Model data foto pohon.
///
/// Setiap foto terkait dengan satu pohon dan memiliki urutan tertentu.
class PhotoModel {
  /// ID unik dari database (null jika belum disimpan).
  int? id;

  /// ID pohon yang terkait dengan foto ini.
  int? treeId;

  /// Urutan foto (1-4 atau lebih sesuai konfigurasi sesi).
  final int urutanFoto;

  /// Path absolut ke file foto di storage lokal.
  final String pathFile;

  PhotoModel({
    this.id,
    this.treeId,
    required this.urutanFoto,
    required this.pathFile,
  });

  /// Membuat instance dari Map database.
  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as int?,
      treeId: map['tree_id'] as int?,
      urutanFoto: map['urutan_foto'] as int,
      pathFile: map['path_file'] as String,
    );
  }

  /// Mengkonversi ke Map untuk penyimpanan database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tree_id': treeId,
      'urutan_foto': urutanFoto,
      'path_file': pathFile,
    };
  }
}
