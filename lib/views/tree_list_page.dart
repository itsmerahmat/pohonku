import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/services/db_service.dart';
import 'package:treedocs/views/widgets/empty_state.dart';
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
            child: EmptyState(
              icon: Icons.park_outlined,
              title: 'Belum Ada Pohon',
              description: 'Tidak ada data pohon untuk\n$varietas - Blok $blok',
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
                onTap: () async {
                  final result = await Get.toNamed('/detail', arguments: tree);
                  // Reload list if tree was deleted
                  if (result == true) {
                    _loadTrees();
                  }
                },
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
