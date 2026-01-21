import 'package:get/get.dart';
import 'package:treedocs/models/photo_model.dart';
import 'package:treedocs/models/tree_model.dart';

class TreeFormController extends GetxController {
  final RxList<String?> photoPaths = <String?>[null, null, null, null].obs;
  final RxBool saving = false.obs;

  /// Menyimpan state apakah sedang mode edit serta data lama.
  TreeModel? existing;

  /// Mengambil foto untuk slot tertentu lalu menyimpannya ke storage lokal.
  Future<void> capturePhoto({
    required int index,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    Get.snackbar(
      'Fitur dinonaktifkan',
      'Pengambilan foto via form memakai image_picker sudah dihapus. Gunakan mode capture utama.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Memilih foto dari galeri untuk slot tertentu lalu menyimpannya ke storage lokal.
  Future<void> pickPhoto({
    required int index,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    Get.snackbar(
      'Fitur dinonaktifkan',
      'Pemilihan foto galeri via form memakai image_picker sudah dihapus.',
      snackPosition: SnackPosition.BOTTOM,
    );
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
    photoPaths[index] = null;
    // Penghapusan file tetap dilakukan oleh flow utama (TreeController) saat delete entry.
    // Di form legacy ini, kita hanya mengosongkan slot.
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
