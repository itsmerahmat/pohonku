import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
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
          child: const Text('Pengaturan', style: TextStyle(color: Colors.white)),
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
    if (isCapturing.value) return;

    isCapturing.value = true;

    try {
      final index = currentPhotoIndex.value;

      // Ambil GPS dari Geolocator untuk setiap foto
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      } catch (e) {
        currentLatitude = null;
        currentLongitude = null;
      }

      // Capture foto
      final image = await cameraController!.takePicture();

      // Save foto ke storage
      final savedPath = await _photoService.captureAndSaveFromFile(
        file: XFile(image.path),
        urutan: index + 1,
        varietas: varietas,
        blok: blok,
        nomorPohon: currentTreeId.value,
      );

      if (savedPath != null) {
        // if (isVibrationEnabled.value) {
        //   await HapticFeedback.mediumImpact();
        // }

        // Tulis GPS ke EXIF jika tersedia
        if (currentLatitude != null && currentLongitude != null) {
          await _exifService.writeGpsToPhoto(
            savedPath,
            currentLatitude!,
            currentLongitude!,
          );
        }

        currentPhotos[index] = savedPath;
        currentPhotoIndex.value++;

        // Auto save jika sudah 4 foto
        if (currentPhotoIndex.value >= 4) {
          await _saveCurrentTree();
          
          // Auto next tree jika mode auto aktif
          if (autoIdMode) {
            startNewTree();
            await startContinuousCapture();
          } else {
            isReady.value = false;
          }
        }
      } else {
        Get.snackbar(
          'Error',
          'Gagal menyimpan foto ${index + 1}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
    }
  }

  /// Simpan pohon saat ini ke database
  Future<void> _saveCurrentTree() async {
    final photos = <PhotoModel>[];
    for (int i = 0; i < currentPhotos.length; i++) {
      final path = currentPhotos[i];
      if (path != null) {
        photos.add(PhotoModel(
          treeId: null,
          urutanFoto: i + 1,
          pathFile: path,
        ));
      }
    }

    if (photos.isEmpty) return;

    final fileType = photos.first.pathFile.split('.').last;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';

    // Ambil GPS dari EXIF foto (coba foto pertama sampai keempat)
    double? latitude;
    double? longitude;

    for (final photo in photos) {
      final gpsData = await _exifService.extractGpsFromPhoto(photo.pathFile);
      if (gpsData != null) {
        latitude = gpsData['latitude'];
        longitude = gpsData['longitude'];
        break;
      }
    }
    
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
  }

  /// Cancel capture session
  void cancelCapture() {
    isReady.value = false;
    isCapturing.value = false;
  }
}
