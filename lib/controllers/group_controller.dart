import 'package:get/get.dart';

import '../services/db_service.dart';

/// Controller untuk mengelola grup pohon berdasarkan varietas dan blok.
///
/// Digunakan di halaman home untuk menampilkan daftar grup
/// dengan jumlah pohon per grup.
class GroupController extends GetxController {
  final DatabaseService _dbService = DatabaseService();

  /// Daftar grup varietas-blok dengan jumlah pohon.
  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;

  /// Status loading data.
  final RxBool loading = true.obs;

  /// Keyword pencarian aktif.
  final RxString searchKeyword = ''.obs;

  /// Mengambil group varietas & blok
  Future<void> loadGroups() async {
    loading.value = true;
    final data = await _dbService.getVarietasBlokGroups(
      query: searchKeyword.value,
    );
    groups.assignAll(data);
    loading.value = false;
  }
}
