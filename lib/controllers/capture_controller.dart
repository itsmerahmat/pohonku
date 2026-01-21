import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/models/photo_model.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/services/exif_service.dart';
import 'package:treedocs/services/photo_service.dart';

class CaptureController extends GetxController {
  final String varietas;
  final String blok;
  final bool autoIdMode;

  CaptureController({
    required this.varietas,
    required this.blok,
    this.autoIdMode = false,
  });

  final PhotoService _photoService = PhotoService();
  final ExifService _exifService = ExifService();
  final TreeController _treeController = Get.find<TreeController>();

  final RxList<String?> currentPhotos = <String?>[null, null, null, null].obs;
  final RxList<bool> isProcessingPhotos = <bool>[
    false,
    false,
    false,
    false,
  ].obs;
  final RxInt currentPhotoIndex = 0.obs;
  final RxString currentTreeId = ''.obs;
  final RxInt currentTreeNumber = 1.obs;
  final RxInt savedTreesCount = 0.obs;
  final RxBool isCapturing = false.obs;
  final RxBool isReady = false.obs; // Ready untuk capture
  // final RxBool isVibrationEnabled = true.obs;

  CameraController? cameraController;
  final Rx<CameraDescription?> selectedCamera = Rx<CameraDescription?>(null);
  final RxBool isCameraInitialized = false.obs;

  // Store GPS coordinates
  double? currentLatitude;
  double? currentLongitude;

  // Best-effort GPS for the current tree/session (used for DB write).
  double? _sessionLatitude;
  double? _sessionLongitude;

  String? _deviceNameCache;

  bool _isTakingPicture = false;
  final List<Future<String?>> _pendingSaveFutures = [];

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
        // NOTE: `max` sering menghasilkan file sangat besar dan memperlambat
        // capture + post-processing. `veryHigh` biasanya sudah cukup tajam
        // untuk output 12MP yang kita simpan (3000x4000).
        ResolutionPreset.veryHigh,
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

    Get.snackbar(
      'Siap Capture!',
      'Tekan tombol shutter atau remote bluetooth untuk mengambil foto',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Capture single photo (dipanggil saat tombol volume/remote ditekan)
  Future<void> capturePhoto() async {
    if (!isReady.value) return;
    if (currentPhotoIndex.value >= 4) return;
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
      if (index < 3) {
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

      // Jika sudah 4 foto, baru tunggu semua proses save selesai lalu simpan ke DB
      if (currentPhotoIndex.value >= 4) {
        await Future.wait(_pendingSaveFutures);
        _pendingSaveFutures.clear();

        await _saveCurrentTree();

        // Auto next tree jika mode auto aktif
        if (autoIdMode) {
          startNewTree();
          await startContinuousCapture();
        } else {
          isReady.value = false;
        }
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

    await _treeController.addTree(tree);
    savedTreesCount.value++;
  }

  /// Mulai pohon baru
  void startNewTree() {
    currentPhotos.assignAll([null, null, null, null]);
    isProcessingPhotos.assignAll([false, false, false, false]);
    currentPhotoIndex.value = 0;
    currentTreeNumber.value++;

    // Auto set ID jika mode auto
    if (autoIdMode) {
      currentTreeId.value = currentTreeNumber.value.toString().padLeft(3, '0');
    } else {
      currentTreeId.value = '';
    }

    isReady.value = false;
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
    isProcessingPhotos.assignAll([false, false, false, false]);
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
