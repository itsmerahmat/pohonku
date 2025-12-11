import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/models/photo_model.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/services/exif_service.dart';
import 'package:treedocs/services/photo_service.dart';
import 'package:treedocs/utils/snackbar_helper.dart';

class CaptureController extends GetxController {
  final String varietas;
  final String blok;

  CaptureController({
    required this.varietas,
    required this.blok,
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
        SnackbarHelper.showError('Tidak ada kamera tersedia');
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
      SnackbarHelper.showError('Gagal menginisialisasi kamera: ${e.toString()}');
    }
  }

  /// Mulai capture 4 foto berurutan dengan camera package
  Future<void> startContinuousCapture() async {
    if (!_validateTreeId()) return;
    await _ensureLocationPermission();
    final cameraReady = await _ensureCameraInitialized();
    if (!cameraReady) return;

    // Set ready mode - siap untuk capture manual
    isReady.value = true;
    currentPhotoIndex.value = 0;

    SnackbarHelper.showInfo(
      'Tekan tombol shutter atau remote bluetooth untuk mengambil foto',
      title: 'Siap Capture!',
      position: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// Capture single photo (dipanggil saat tombol volume/remote ditekan)
  Future<void> capturePhoto() async {
    if (!isReady.value || currentPhotoIndex.value >= 4 || isCapturing.value) {
      return;
    }

    isCapturing.value = true;

    try {
      final index = currentPhotoIndex.value;

      // Ambil GPS dari Geolocator untuk setiap foto
      await _refreshCurrentLocation();

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
        // Tulis GPS ke EXIF jika tersedia
        await _writeGpsToPhoto(savedPath);

        currentPhotos[index] = savedPath;
        currentPhotoIndex.value++;

        // Auto save jika sudah 4 foto
        if (currentPhotoIndex.value >= 4) {
          await _saveCurrentTree();
          isReady.value = false;
        }
      } else {
        SnackbarHelper.showError('Gagal menyimpan foto ${index + 1}');
      }
    } catch (e) {
      SnackbarHelper.showError('Gagal mengambil foto: ${e.toString()}');
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
    currentTreeId.value = '';
    currentTreeNumber.value++;
    isReady.value = false;
    currentLatitude = null;
    currentLongitude = null;
  }

  /// Cancel capture session
  void cancelCapture() {
    isReady.value = false;
    isCapturing.value = false;
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
    } catch (_) {
      currentLatitude = null;
      currentLongitude = null;
    }
  }

  Future<void> _writeGpsToPhoto(String savedPath) async {
    if (currentLatitude != null && currentLongitude != null) {
      await _exifService.writeGpsToPhoto(
        savedPath,
        currentLatitude!,
        currentLongitude!,
      );
    }
  }

  bool _validateTreeId() {
    if (currentTreeId.value.isEmpty) {
      SnackbarHelper.showWarning('Masukkan ID Pohon terlebih dahulu');
      return false;
    }
    return true;
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      SnackbarHelper.showWithAction(
        'GPS Tidak Aktif',
        'Aktifkan GPS untuk menyimpan koordinat lokasi pohon',
        actionLabel: 'Aktifkan',
        onAction: () => Geolocator.openLocationSettings(),
        duration: const Duration(seconds: 4),
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        SnackbarHelper.showWarning(
          'Foto akan disimpan tanpa koordinat GPS',
          title: 'Izin Lokasi Ditolak',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      SnackbarHelper.showWithAction(
        'Izin Lokasi Ditolak Permanen',
        'Aktifkan izin lokasi di pengaturan untuk menyimpan GPS',
        actionLabel: 'Pengaturan',
        onAction: () => Geolocator.openAppSettings(),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<bool> _ensureCameraInitialized() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      await initializeCamera();
    }

    if (!isCameraInitialized.value) {
      SnackbarHelper.showError('Kamera tidak dapat diinisialisasi');
      return false;
    }

    return true;
  }


}
