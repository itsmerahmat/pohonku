class PhotoModel {
  int? id;
  int? treeId;
  final int urutanFoto;
  final String pathFile;

  PhotoModel({
    this.id,
    this.treeId,
    required this.urutanFoto,
    required this.pathFile,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] as int?,
      treeId: map['tree_id'] as int?,
      urutanFoto: map['urutan_foto'] as int,
      pathFile: map['path_file'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tree_id': treeId,
      'urutan_foto': urutanFoto,
      'path_file': pathFile,
    };
  }
}
