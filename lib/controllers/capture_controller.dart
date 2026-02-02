import 'dart:async';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:get/get.dart';

import '../models/photo_model.dart';
import '../models/tree_model.dart';
import '../services/exif_service.dart';
import '../services/photo_service.dart';
import 'group_controller.dart';
import 'tree_controller.dart';

/// Controller untuk mode capture foto kontinyu.
///
/// Menangani:
/// - Inisialisasi dan kontrol kamera
/// - Capture foto dengan GPS
/// - Penyimpanan otomatis ke database
/// - Mode ID otomatis untuk dokumentasi cepat
class CaptureController extends GetxController {
  /// Varietas pohon untuk sesi ini.
  final String varietas;

  /// Blok lokasi untuk sesi ini.
  final String blok;

  /// Mode ID otomatis (increment otomatis).
  final bool autoIdMode;

  /// Total foto per pohon (minimal 4, harus genap).
  final int totalPhotos;

  /// Normalisasi jumlah foto (minimal 4, harus genap).
  static int _normalizePhotoCount(int value) {
    if (value < 4) return 4;
    if (value.isOdd) return value + 1;
    return value;
  }

  CaptureController({
    required this.varietas,
    required this.blok,
    this.autoIdMode = false,
    int photoCount = 4,
  }) : totalPhotos = _normalizePhotoCount(photoCount) {
    currentPhotos.assignAll(List<String?>.filled(totalPhotos, null));
    isProcessingPhotos.assignAll(List<bool>.filled(totalPhotos, false));
  }

  // Services
  final PhotoService _photoService = PhotoService();
  final ExifService _exifService = ExifService();
  final TreeController _treeController = Get.find<TreeController>();

  // State observables
  final RxList<String?> currentPhotos = <String?>[].obs;
  final RxList<bool> isProcessingPhotos = <bool>[].obs;
  final RxInt currentPhotoIndex = 0.obs;
  final RxString currentTreeId = ''.obs;
  final RxInt currentTreeNumber = 1.obs;
  final RxInt savedTreesCount = 0.obs;
  final RxBool isCapturing = false.obs;
  final RxBool isReady = false.obs;
  final RxBool isFinalizing = false.obs;

  // Camera
  CameraController? cameraController;
  final Rx<CameraDescription?> selectedCamera = Rx<CameraDescription?>(null);
  final RxBool isCameraInitialized = false.obs;

  // GPS coordinates
  double? currentLatitude;
  double? currentLongitude;
  double? _sessionLatitude;
  double? _sessionLongitude;

  // Cache
  String? _deviceNameCache;
  bool _isTakingPicture = false;
  final List<Future<String?>> _pendingSaveFutures = [];

  @override
  void onInit() {
    super.onInit();
    if (autoIdMode) {
      _syncAutoTreeNumber();
    }
  }

  Future<String> _getDeviceName() async {
    final cached = _deviceNameCache;
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final deviceInfo = DeviceInfoPlugin();
      // App ini utamanya Android; kalau platform lain, fallback aman.
      final androidInfo = await deviceInfo.androidInfo;
      final deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      _deviceNameCache = deviceName;
      return deviceName;
    } catch (_) {
      const fallback = 'Unknown device';
      _deviceNameCache = fallback;
      return fallback;
    }
  }

  void _setSessionGpsIfNull(double lat, double lng) {
    _sessionLatitude ??= lat;
    _sessionLongitude ??= lng;
  }

  Future<void> _syncAutoTreeNumber() async {
    final lastNumber = await _treeController.getMaxTreeNumber(varietas, blok);
    if (lastNumber != null) {
      currentTreeNumber.value = lastNumber + 1;
    } else {
      currentTreeNumber.value = 1;
    }
    currentTreeId.value = currentTreeNumber.value.toString().padLeft(3, '0');
  }

  /// Pastikan foto memiliki GPS di EXIF.
  /// Jika GPS snapshot null (sering terjadi di foto pertama), coba ambil fix baru
  /// tanpa memblokir UI, lalu tulis ke EXIF.
  void _ensureGpsWrittenForPhoto(String savedPath, double? lat, double? lng) {
    if (lat != null && lng != null) {
      _setSessionGpsIfNull(lat, lng);
      _writeGpsInBackground(savedPath, lat, lng);
      return;
    }

    Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 2),
        )
        .then((position) {
          currentLatitude = position.latitude;
          currentLongitude = position.longitude;
          _setSessionGpsIfNull(position.latitude, position.longitude);
          _writeGpsInBackground(
            savedPath,
            position.latitude,
            position.longitude,
          );
        })
        .catchError((_) {
          // Ignore: foto tetap tersimpan tanpa GPS.
        });
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  /// Initialize camera
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar(
          'Error',
          'Tidak ada kamera tersedia',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      selectedCamera.value = cameras.first;
      cameraController = CameraController(
        cameras.first,
        // Gunakan resolusi maksimum untuk mendapatkan foto 12MP+
        // Kebanyakan HP modern menghasilkan 12-48MP dengan rasio 4:3
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();

      // Lock orientation agar hasil capture portrait.
      try {
        await cameraController!.lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );
      } catch (_) {
        // Ignore jika tidak didukung.
      }

      // Pastikan flash selalu off (jika device mendukung).
      try {
        await cameraController!.setFlashMode(FlashMode.off);
      } catch (_) {
        // Ignore jika flash tidak didukung.
      }

      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menginisialisasi kamera: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Mulai capture 4 foto berurutan dengan camera package
  Future<void> startContinuousCapture() async {
    // Auto set ID jika mode auto aktif
    if (autoIdMode && currentTreeId.value.isEmpty) {
      currentTreeId.value = currentTreeNumber.value.toString().padLeft(3, '0');
    }

    if (currentTreeId.value.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Masukkan ID Pohon terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Cek ID duplikat sebelum mulai capture
    final isDuplicate = await _treeController.isTreeNumberExists(
      varietas,
      blok,
      currentTreeId.value,
    );

    if (isDuplicate) {
      Get.snackbar(
        'ID Sudah Ada',
        'ID Pohon ${currentTreeId.value} sudah digunakan di $varietas - Blok $blok. Gunakan ID berbeda.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Cek dan request permission lokasi
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'GPS Tidak Aktif',
        'Aktifkan GPS untuk menyimpan koordinat lokasi pohon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () async {
            await Geolocator.openLocationSettings();
            Get.back();
          },
          child: const Text('Aktifkan', style: TextStyle(color: Colors.white)),
        ),
      );
      // Lanjutkan tanpa GPS
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Izin Lokasi Ditolak',
          'Foto akan disimpan tanpa koordinat GPS',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // Lanjutkan tanpa GPS
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Izin Lokasi Ditolak Permanen',
        'Aktifkan izin lokasi di pengaturan untuk menyimpan GPS',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () async {
            await Geolocator.openAppSettings();
            Get.back();
          },
          child: const Text(
            'Pengaturan',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      // Lanjutkan tanpa GPS
    }

    // Initialize camera jika belum
    if (cameraController == null || !cameraController!.value.isInitialized) {
      await initializeCamera();
    }

    if (!isCameraInitialized.value) {
      Get.snackbar(
        'Error',
        'Kamera tidak dapat diinisialisasi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Pre-fetch GPS position untuk mengurangi delay saat capture
    await _prefetchGpsPosition();

    // Snapshot awal GPS untuk session (akan dipakai saat simpan ke DB)
    if (currentLatitude != null && currentLongitude != null) {
      _setSessionGpsIfNull(currentLatitude!, currentLongitude!);
    }

    // Set ready mode - siap untuk capture manual
    isReady.value = true;
    currentPhotoIndex.value = 0;

    // Get.snackbar(
    //   'Siap Capture!',
    //   'Tekan tombol shutter atau remote bluetooth untuk mengambil foto ($totalPhotos foto)',
    //   snackPosition: SnackPosition.TOP,
    //   backgroundColor: Colors.blue,
    //   colorText: Colors.white,
    //   duration: const Duration(seconds: 3),
    // );
  }

  /// Capture single photo (dipanggil saat tombol volume/remote ditekan)
  Future<void> capturePhoto() async {
    if (!isReady.value) return;
    if (currentPhotoIndex.value >= totalPhotos) return;
    if (_isTakingPicture) return;

    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    _isTakingPicture = true;
    isCapturing.value = true;

    try {
      final index = currentPhotoIndex.value;

      // Enforce flash off sebelum capture (defensive).
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      // Capture foto LANGSUNG tanpa delay GPS
      final image = await controller.takePicture();

      // Haptic feedback saat foto berhasil diambil
      Vibration.vibrate(duration: 200);

      // Snapshot GPS saat tombol ditekan (biar EXIF konsisten per foto)
      final double? latAtCapture = currentLatitude;
      final double? lngAtCapture = currentLongitude;

      if (latAtCapture != null && lngAtCapture != null) {
        _setSessionGpsIfNull(latAtCapture, lngAtCapture);
      }

      // Segera pindah ke slot berikutnya agar user bisa lanjut capture.
      isProcessingPhotos[index] = true;
      currentPhotoIndex.value++;

      // Update GPS di background untuk foto berikutnya
      if (index < totalPhotos - 1) {
        _updateGpsInBackground();
      }

      // Save + resize jalan paralel di background (tidak memblokir shutter)
      final saveFuture = _photoService
          .captureAndSaveFromFile(
            file: image,
            urutan: index + 1,
            varietas: varietas,
            blok: blok,
            nomorPohon: currentTreeId.value,
          )
          .then((savedPath) {
            if (savedPath != null) {
              currentPhotos[index] = savedPath;

              // Tulis GPS ke EXIF di background (non-blocking)
              _ensureGpsWrittenForPhoto(savedPath, latAtCapture, lngAtCapture);
            } else {
              Get.snackbar(
                'Error',
                'Gagal menyimpan foto ${index + 1}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }

            isProcessingPhotos[index] = false;
            return savedPath;
          })
          .catchError((_) {
            isProcessingPhotos[index] = false;
            return null;
          });

      _pendingSaveFutures.add(saveFuture);

      // Jika sudah foto terakhir, tunggu semua foto selesai diproses lalu tampilkan review
      if (currentPhotoIndex.value >= totalPhotos) {
        isReady.value = false;
        isFinalizing.value = true;
        // Tunggu semua foto selesai disimpan, lalu tampilkan review
        unawaited(_waitAndShowReview());
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengambil foto: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCapturing.value = false;
      _isTakingPicture = false;
    }
  }

  Future<void> _waitAndShowReview() async {
    try {
      // Tunggu semua save futures selesai dengan timeout
      try {
        await Future.wait(_pendingSaveFutures).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            debugPrint('⚠️ Save timeout, proceeding with available photos');
            return [];
          },
        );
      } catch (e) {
        debugPrint('⚠️ Error waiting for saves: $e');
      }
      _pendingSaveFutures.clear();

      isFinalizing.value = false;
    } catch (e) {
      debugPrint('Error in review: $e');
      isFinalizing.value = false;
    }
  }

  /// Retake foto untuk pohon saat ini
  void retakeCurrentTree() {
    // Reset semua foto pohon saat ini
    currentPhotos.assignAll(List<String?>.filled(totalPhotos, null));
    isProcessingPhotos.assignAll(List<bool>.filled(totalPhotos, false));
    currentPhotoIndex.value = 0;
    _pendingSaveFutures.clear();

    // Mulai ulang capture
    startContinuousCapture();
  }

  /// Simpan pohon dan lanjut ke pohon berikutnya
  Future<void> saveAndContinue() async {
    isFinalizing.value = true;
    await _saveCurrentTree();
    isFinalizing.value = false;

    if (autoIdMode) {
      startNewTree();
      await startContinuousCapture();
    } else {
      // Mode manual, reset untuk input ID baru
      startNewTree();
    }
  }

  /// Simpan pohon dan selesai (kembali ke home)
  Future<void> saveAndFinish() async {
    isFinalizing.value = true;
    await _saveCurrentTree();
    isFinalizing.value = false;

    // Refresh home page
    final groupController = Get.find<GroupController>();
    await groupController.loadGroups();

    // Kembali ke home
    Get.until((route) => route.isFirst);

    Get.snackbar(
      'Selesai!',
      'Berhasil menyimpan ${savedTreesCount.value} pohon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  /// Simpan pohon saat ini ke database
  Future<void> _saveCurrentTree() async {
    final photos = <PhotoModel>[];
    for (int i = 0; i < currentPhotos.length; i++) {
      final path = currentPhotos[i];
      if (path != null) {
        photos.add(PhotoModel(treeId: null, urutanFoto: i + 1, pathFile: path));
      }
    }

    if (photos.isEmpty) return;

    final fileType = photos.first.pathFile.split('.').last;
    final deviceName = await _getDeviceName();

    // Jangan baca EXIF di sini (berat & bisa bikin ANR). Pakai GPS session.
    final double? latitude = _sessionLatitude;
    final double? longitude = _sessionLongitude;

    final tree = TreeModel(
      id: null,
      varietas: varietas,
      blok: blok,
      nomorPohon: currentTreeId.value,
      latitude: latitude,
      longitude: longitude,
      tanggalPengambilan: DateTime.now(),
      deviceName: deviceName,
      fileType: fileType,
      photos: photos,
    );

    await _treeController.addTree(tree, refresh: false);
    savedTreesCount.value++;
  }

  /// Mulai pohon baru
  void startNewTree() {
    currentPhotos.assignAll(List<String?>.filled(totalPhotos, null));
    isProcessingPhotos.assignAll(List<bool>.filled(totalPhotos, false));
    currentPhotoIndex.value = 0;
    currentTreeNumber.value++;

    // Auto set ID jika mode auto
    if (autoIdMode) {
      currentTreeId.value = currentTreeNumber.value.toString().padLeft(3, '0');
    } else {
      currentTreeId.value = '';
    }

    isReady.value = false;
    isFinalizing.value = false;
    currentLatitude = null;
    currentLongitude = null;
    _sessionLatitude = null;
    _sessionLongitude = null;
  }

  /// Cancel capture session
  void cancelCapture() {
    isReady.value = false;
    isCapturing.value = false;
    _isTakingPicture = false;
    isFinalizing.value = false;
    isProcessingPhotos.assignAll(List<bool>.filled(totalPhotos, false));
  }

  /// Pre-fetch GPS position untuk mengurangi delay
  Future<void> _prefetchGpsPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      debugPrint('📍 GPS pre-fetched: $currentLatitude, $currentLongitude');
    } catch (e) {
      debugPrint('⚠️ GPS pre-fetch failed: $e');
      // Lanjutkan tanpa GPS
    }
  }

  /// Update GPS di background tanpa blocking UI
  void _updateGpsInBackground() {
    Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 2),
        )
        .then((position) {
          currentLatitude = position.latitude;
          currentLongitude = position.longitude;
        })
        .catchError((_) {
          // Ignore error, gunakan GPS terakhir
        });
  }

  /// Tulis GPS ke EXIF di background tanpa blocking UI
  void _writeGpsInBackground(String path, double lat, double lng) {
    _exifService.writeGpsToPhoto(path, lat, lng).then((_) {}).catchError((e) {
      debugPrint('⚠️ Failed to write GPS to EXIF: $e');
    });
  }
}
