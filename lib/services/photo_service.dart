import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Type alias untuk XFile agar kompatibel dengan berbagai package.
typedef XFileAny = dynamic;

/// Service untuk mengelola foto pohon.
///
/// Menangani capture, kompresi, dan penyimpanan foto ke storage lokal.
/// Menggunakan native compression untuk performa optimal.
class PhotoService {
  PhotoService._internal();
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;

  /// Kualitas JPEG - balance antara ukuran dan kualitas.
  static const int _jpegQuality = 88;

  /// Serial processing untuk stabilitas (hindari buffer overflow).
  static const int _maxConcurrentProcessing = 1;
  final _AsyncSemaphore _processingSemaphore = _AsyncSemaphore(
    _maxConcurrentProcessing,
  );

  /// Proses dan simpan foto menggunakan native compression (flutter_image_compress)
  /// Ini JAUH lebih cepat dari package:image karena menggunakan native code.
  Future<String?> _processAndSavePhotoNative({
    required String sourcePath,
    required String savedPath,
  }) async {
    try {
      // Gunakan flutter_image_compress yang native (Java/ObjC)
      // Ini otomatis handle rotation dari EXIF dan jauh lebih cepat
      // Resolusi dipertahankan dari camera (biasanya 12MP 4:3)
      // minWidth/minHeight di-set tinggi agar TIDAK di-downscale
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        savedPath,
        quality: _jpegQuality,
        minWidth: 9999, // Pertahankan lebar asli
        minHeight: 9999, // Pertahankan tinggi asli
        // Biarkan library handle rotation otomatis
        autoCorrectionAngle: true,
        keepExif: true,
        format: CompressFormat.jpeg,
      );

      if (result != null && await File(result.path).exists()) {
        return result.path;
      }

      // Fallback: copy langsung jika compress gagal
      return await _copyFileDirect(sourcePath, savedPath);
    } catch (e) {
      // Fallback: copy langsung
      return await _copyFileDirect(sourcePath, savedPath);
    }
  }

  /// Copy file langsung tanpa processing (fallback)
  Future<String?> _copyFileDirect(String sourcePath, String savedPath) async {
    try {
      await File(sourcePath).copy(savedPath);
      return savedPath;
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan foto ke direktori aplikasi
  Future<String?> _processAndSavePhotoJpeg(
    String sourcePath,
    int urutan,
    String varietas,
    String blok,
    String nomorPohon,
  ) async {
    final sanitizedVarietas = varietas.replaceAll(' ', '_').toUpperCase();
    final sanitizedBlok = blok.replaceAll(' ', '_').toUpperCase();
    final sanitizedNomor = nomorPohon.replaceAll(' ', '_').toUpperCase();
    final fileName =
        '${sanitizedVarietas}_${sanitizedBlok}_${sanitizedNomor}_$urutan.jpg';

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(dir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final savedPath = join(photosDir.path, fileName);

    return _processAndSavePhotoNative(
      sourcePath: sourcePath,
      savedPath: savedPath,
    );
  }

  /// Menyimpan foto dari XFile yang sudah ada (untuk continuous capture)
  /// Menerima XFile dari camera package
  Future<String?> captureAndSaveFromFile({
    required XFileAny file,
    required int urutan,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    await _processingSemaphore.acquire();
    try {
      // Akses path dari XFile (works dengan camera atau flutter_image_compress XFile)
      final String sourcePath = file.path;
      return await _processAndSavePhotoJpeg(
        sourcePath,
        urutan,
        varietas,
        blok,
        nomorPohon,
      );
    } catch (_) {
      return null;
    } finally {
      _processingSemaphore.release();
    }
  }

  /// Menghapus file foto dari storage jika ada.
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _AsyncSemaphore {
  _AsyncSemaphore(this._available);

  int _available;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    _available++;
  }
}
