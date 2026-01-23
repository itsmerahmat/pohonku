import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/tree_model.dart';

/// Service untuk mengexport foto-foto pohon.
///
/// Mendukung export dalam format ZIP atau copy langsung ke folder.
/// File akan disimpan ke folder Download perangkat.
class ExportService {
  /// Export semua foto pohon dalam bentuk ZIP
  ///
  /// Returns: path ke file ZIP yang sudah dibuat, atau null jika gagal
  Future<String?> exportAllPhotosAsZip(List<TreeModel> trees) async {
    try {
      // Request storage permission untuk Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try with manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return null;
          }
        }
      }

      // Buat archive
      final archive = Archive();

      // Tambahkan semua foto ke archive
      for (final tree in trees) {
        for (final photo in tree.photos) {
          final file = File(photo.pathFile);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = p.basename(photo.pathFile);
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        }
      }

      // Encode ke ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) return null;

      // Simpan ke Downloads
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'TreeDocs_Export_$timestamp.zip';

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) return null;

      final zipFile = File('${targetDir.path}/$fileName');
      await zipFile.writeAsBytes(zipBytes);

      return zipFile.path;
    } catch (e) {
      debugPrint('Error exporting photos: $e');
      return null;
    }
  }

  /// Export foto pohon tertentu (berdasarkan varietas dan blok)
  Future<String?> exportPhotosByGroup(
    List<TreeModel> trees,
    String varietas,
    String blok,
  ) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return null;
          }
        }
      }

      final archive = Archive();

      for (final tree in trees) {
        for (final photo in tree.photos) {
          final file = File(photo.pathFile);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = p.basename(photo.pathFile);
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        }
      }

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) return null;

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'TreeDocs_${varietas}_${blok}_$timestamp.zip';

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) return null;

      final zipFile = File('${targetDir.path}/$fileName');
      await zipFile.writeAsBytes(zipBytes);

      return zipFile.path;
    } catch (e) {
      debugPrint('Error exporting photos: $e');
      return null;
    }
  }

  /// Copy semua foto ke folder tertentu (tanpa ZIP)
  Future<String?> copyAllPhotosToFolder(List<TreeModel> trees) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            return null;
          }
        }
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final folderName = 'TreeDocs_Export_$timestamp';

      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0/Download');
        if (!await baseDir.exists()) {
          baseDir = await getExternalStorageDirectory();
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) return null;

      final exportDir = Directory('${baseDir.path}/$folderName');
      await exportDir.create(recursive: true);

      int copiedCount = 0;
      for (final tree in trees) {
        for (final photo in tree.photos) {
          final file = File(photo.pathFile);
          if (await file.exists()) {
            final fileName = p.basename(photo.pathFile);
            final targetPath = '${exportDir.path}/$fileName';
            await file.copy(targetPath);
            copiedCount++;
          }
        }
      }

      return copiedCount > 0 ? exportDir.path : null;
    } catch (e) {
      debugPrint('Error copying photos: $e');
      return null;
    }
  }
}
