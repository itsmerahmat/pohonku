import 'dart:io';
import 'dart:isolate';

import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {
  PhotoService._internal();
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;

  static const int _targetPortraitWidth = 3000;
  static const int _targetPortraitHeight = 4000;
  static const int _jpegQuality = 95;

  static Future<String?> _processAndSavePhotoJpegOnBackgroundIsolate({
    required String sourcePath,
    required String savedPath,
  }) async {
    // NOTE: Do NOT call any plugins (path_provider, etc.) inside isolate.
    // Only pure Dart + file IO + package:image.
    return Isolate.run(() {
      try {
        final bytes = File(sourcePath).readAsBytesSync();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          File(sourcePath).copySync(savedPath);
          return savedPath;
        }

        final baked = img.bakeOrientation(decoded);

        // Pastikan output selalu portrait.
        final img.Image portraitSource = baked.width > baked.height
            ? img.copyRotate(baked, angle: 90)
            : baked;

        const int targetWidth = _targetPortraitWidth;
        const int targetHeight = _targetPortraitHeight;
        const double targetAspectRatio = targetWidth / targetHeight; // 3:4
        final double sourceAspectRatio =
            portraitSource.width / portraitSource.height;

        int cropWidth = portraitSource.width;
        int cropHeight = portraitSource.height;
        if (sourceAspectRatio > targetAspectRatio) {
          cropWidth = (portraitSource.height * targetAspectRatio).round();
        } else if (sourceAspectRatio < targetAspectRatio) {
          cropHeight = (portraitSource.width / targetAspectRatio).round();
        }

        final int cropX = ((portraitSource.width - cropWidth) / 2)
            .round()
            .clamp(0, portraitSource.width - 1);
        final int cropY = ((portraitSource.height - cropHeight) / 2)
            .round()
            .clamp(0, portraitSource.height - 1);
        final int safeCropWidth = cropWidth.clamp(
          1,
          portraitSource.width - cropX,
        );
        final int safeCropHeight = cropHeight.clamp(
          1,
          portraitSource.height - cropY,
        );

        final cropped = img.copyCrop(
          portraitSource,
          x: cropX,
          y: cropY,
          width: safeCropWidth,
          height: safeCropHeight,
        );

        final resized = img.copyResize(
          cropped,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );

        final jpg = img.encodeJpg(resized, quality: _jpegQuality);
        File(savedPath).writeAsBytesSync(jpg, flush: true);
        return savedPath;
      } catch (_) {
        try {
          File(sourcePath).copySync(savedPath);
          return savedPath;
        } catch (_) {
          return null;
        }
      }
    });
  }

  /// Menyimpan foto dari XFile ke direktori aplikasi dengan:
  /// - Portrait only (rasio 3:4)
  /// - Resolusi output 12MP (3000x4000)
  /// - Format output JPEG
  Future<String?> _processAndSavePhotoJpeg(
    XFile file,
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

    return _processAndSavePhotoJpegOnBackgroundIsolate(
      sourcePath: file.path,
      savedPath: savedPath,
    );
  }

  /// Menyimpan foto dari XFile yang sudah ada (untuk continuous capture)
  Future<String?> captureAndSaveFromFile({
    required XFile file,
    required int urutan,
    required String varietas,
    required String blok,
    required String nomorPohon,
  }) async {
    return _processAndSavePhotoJpeg(file, urutan, varietas, blok, nomorPohon);
  }

  /// Menghapus file foto dari storage jika ada.
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
