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
    // Ambil foto dengan kualitas penuh (tanpa kompresi).
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;

    return _savePhoto(file, urutan, varietas, blok, nomorPohon);
  }

  /// Membuka galeri lalu menyimpan foto ke direktori aplikasi dengan nama khusus.
  Future<String?> pickFromGallery({
    required int urutan,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    final picker = ImagePicker();
    // Ambil foto dari galeri tanpa penurunan kualitas.
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    return _savePhoto(file, urutan, varietas, blok, nomorPohon);
  }

  /// Menyimpan foto dari XFile ke direktori aplikasi dengan nama khusus.
  Future<String?> _savePhoto(
    XFile file,
    int urutan,
    String varietas,
    String blok,
    String nomorPohon,
  ) async {
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
    // Simpan file ke path baru.
    await file.saveTo(savedPath);
    return savedPath;
  }

  /// Menyimpan foto dari XFile yang sudah ada (untuk continuous capture)
  Future<String?> captureAndSaveFromFile({
    required XFile file,
    required int urutan,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    return _savePhoto(file, urutan, varietas, blok, nomorPohon);
  }

  /// Menghapus file foto dari storage jika ada.
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
