import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/services/db_service.dart';
import 'package:treedocs/views/widgets/tree_card.dart';

class TreeListPage extends StatefulWidget {
  const TreeListPage({super.key});

  @override
  State<TreeListPage> createState() => _TreeListPageState();
}

class _TreeListPageState extends State<TreeListPage> {
  final DatabaseService _dbService = DatabaseService();
  final RxList<TreeModel> trees = <TreeModel>[].obs;
  final RxBool loading = true.obs;

  late String varietas;
  late String blok;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    varietas = args['varietas'];
    blok = args['blok'];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTrees();
      }
    });
  }

  Future<void> _loadTrees() async {
    loading.value = true;
    final data = await _dbService.getTreesByVarietasBlok(varietas, blok);
    trees.assignAll(data);
    loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(varietas),
            Text(
              'Blok $blok',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrees,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: Obx(() {
        if (loading.value) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Skeletonizer(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          );
        }

        if (trees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.park_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Pohon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada data pohon untuk\n$varietas - Blok $blok',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: trees.length,
          itemBuilder: (_, index) {
            final tree = trees[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TreeCard(
                tree: tree,
                onTap: () => Get.toNamed('/detail', arguments: tree),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/session', arguments: {
          'varietas': varietas,
          'blok': blok,
        }),
        icon: const Icon(Icons.add),
        label: const Text('Pohon'),
      ),
    );
  }
}
