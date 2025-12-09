import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {
  PhotoService._internal();
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;

  /// Membuka kamera lalu menyimpan foto ke direktori aplikasi dengan nama khusus.
  Future<String?> captureAndSave({
    required int urutan,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return null;

    // Ekstensi file asli (jpg/png) dipertahankan agar metadata tetap konsisten.
    final ext = extension(file.path);
    final sanitizedVarietas = varietas.replaceAll(' ', '_').toUpperCase();
    final sanitizedBlok = blok.replaceAll(' ', '_').toUpperCase();
    final sanitizedNomor = nomorPohon.replaceAll(' ', '_').toUpperCase();
    final fileName = '${sanitizedVarietas}_${sanitizedBlok}_${sanitizedNomor}_$urutan$ext';

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(dir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final savedPath = join(photosDir.path, fileName);
    // Simpan file dari kamera ke path baru.
    await file.saveTo(savedPath);
    return savedPath;
  }

  /// Menghapus file foto dari storage jika ada.
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
