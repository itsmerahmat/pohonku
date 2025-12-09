import 'package:get/get.dart';
import 'package:treedocs/models/photo_model.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/services/photo_service.dart';

class TreeFormController extends GetxController {
  final RxList<String?> photoPaths = <String?>[null, null, null, null].obs;
  final RxBool saving = false.obs;

  /// Menyimpan state apakah sedang mode edit serta data lama.
  TreeModel? existing;

  final PhotoService _photoService = PhotoService();

  /// Mengambil foto untuk slot tertentu lalu menyimpannya ke storage lokal.
  Future<void> capturePhoto({
    required int index,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    final savedPath = await _photoService.captureAndSave(
      urutan: index + 1,
      varietas: varietas,
      blok: blok,
      nomorPohon: nomorPohon,
    );
    if (savedPath != null) {
      // Jika ada foto lama di slot ini, hapus agar tidak menumpuk di storage.
      final oldPath = photoPaths[index];
      photoPaths[index] = savedPath;
      if (oldPath != null && oldPath != savedPath) {
        await _photoService.deletePhoto(oldPath);
      }
    }
  }

  /// Mengisi foto ketika mode edit sehingga user bisa melihat preview.
  void loadExistingPhotos(List<PhotoModel> photos) {
    for (final photo in photos) {
      final idx = photo.urutanFoto - 1;
      if (idx >= 0 && idx < photoPaths.length) {
        photoPaths[idx] = photo.pathFile;
      }
    }
  }

  /// Menghapus foto di slot tertentu.
  Future<void> removePhoto(int index) async {
    final current = photoPaths[index];
    photoPaths[index] = null;
    if (current != null) {
      await _photoService.deletePhoto(current);
    }
  }

  /// Mengonversi jalur foto menjadi objek PhotoModel untuk penyimpanan DB.
  List<PhotoModel> toPhotoModels(int? treeId) {
    final List<PhotoModel> photos = [];
    for (int i = 0; i < photoPaths.length; i++) {
      final path = photoPaths[i];
      if (path != null) {
        photos.add(PhotoModel(
          treeId: treeId,
          urutanFoto: i + 1,
          pathFile: path,
        ));
      }
    }
    return photos;
  }
}
