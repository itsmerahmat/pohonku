import 'package:get/get.dart';
import 'package:treedocs/services/db_service.dart';

class GroupController extends GetxController {
  final DatabaseService _dbService = DatabaseService();

  final RxList<Map<String, dynamic>> groups = <Map<String, dynamic>>[].obs;
  final RxBool loading = true.obs;
  final RxString searchKeyword = ''.obs;

  /// Mengambil group varietas & blok
  Future<void> loadGroups() async {
    loading.value = true;
    final data = await _dbService.getVarietasBlokGroups(query: searchKeyword.value);
    groups.assignAll(data);
    loading.value = false;
  }
}
