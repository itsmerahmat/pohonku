import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';

import '../models/tree_model.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/photo_service.dart';

/// Controller utama untuk mengelola data pohon.
///
/// Menangani operasi CRUD pohon termasuk:
/// - Load daftar pohon dari database
/// - Tambah, update, dan hapus pohon
/// - Mengambil lokasi GPS dan info perangkat
class TreeController extends GetxController {
  final DatabaseService _dbService = DatabaseService();
  final PhotoService _photoService = PhotoService();
  final LocationService _locationService = LocationService();

  /// Daftar pohon yang ditampilkan.
  final RxList<TreeModel> trees = <TreeModel>[].obs;

  /// Status loading data.
  final RxBool loading = true.obs;

  /// Keyword pencarian aktif.
  final RxString searchKeyword = ''.obs;

  /// Mengambil semua entri pohon dari database berdasarkan keyword pencarian.
  Future<void> loadTrees() async {
    loading.value = true;
    final data = await _dbService.getTrees(query: searchKeyword.value);
    trees.assignAll(data);
    loading.value = false;
  }

  /// Menyimpan entri pohon baru ke database.
  Future<int> addTree(TreeModel tree, {bool refresh = true}) async {
    final id = await _dbService.insertTree(tree);
    if (refresh) {
      await loadTrees();
    }
    return id;
  }

  /// Memperbarui entri pohon.
  Future<void> updateTree(TreeModel tree) async {
    await _dbService.updateTree(tree);
    await loadTrees();
  }

  /// Mengambil data pohon berdasarkan ID.
  Future<TreeModel?> getTreeById(int id) async {
    return await _dbService.getTreeById(id);
  }

  /// Mengambil nomor pohon terbesar (numeric) berdasarkan varietas dan blok.
  Future<int?> getMaxTreeNumber(String varietas, String blok) async {
    return _dbService.getMaxTreeNumber(varietas, blok);
  }

  /// Mengecek apakah nomor pohon sudah ada dalam varietas dan blok tertentu.
  Future<bool> isTreeNumberExists(
    String varietas,
    String blok,
    String nomorPohon,
  ) async {
    return _dbService.isTreeNumberExists(varietas, blok, nomorPohon);
  }

  /// Menghapus data pohon dan semua file foto terkait.
  Future<void> removeTree(TreeModel tree) async {
    for (final photo in tree.photos) {
      await _photoService.deletePhoto(photo.pathFile);
    }
    if (tree.id != null) {
      await _dbService.deleteTree(tree.id!);
    }
    await loadTrees();
  }

  /// Mengambil posisi GPS saat menyimpan data. Null jika gagal.
  Future<List<double?>?> getCurrentLatLng() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return null;
    return [position.latitude, position.longitude];
  }

  /// Mengambil nama perangkat untuk dicatat sebagai metadata.
  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return '${androidInfo.manufacturer} ${androidInfo.model}';
  }
}
