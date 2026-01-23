import 'package:get/get.dart';

import '../models/photo_model.dart';
import '../models/tree_model.dart';

/// Controller untuk form input data pohon (legacy).
///
/// Catatan: Form ini sudah tidak digunakan untuk capture foto.
/// Gunakan CaptureController untuk mode capture utama.
class TreeFormController extends GetxController {
  /// Path foto untuk setiap slot (4 slot default).
  final RxList<String?> photoPaths = <String?>[null, null, null, null].obs;

  /// Status penyimpanan data.
  final RxBool saving = false.obs;

  /// Data pohon yang sedang diedit (null jika mode tambah baru).
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
        photos.add(
          PhotoModel(treeId: treeId, urutanFoto: i + 1, pathFile: path),
        );
      }
    }
    return photos;
  }
}
