import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:treedocs/views/widgets/tree_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TreeController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pohon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTrees,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari varietas / blok / nomor',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                controller.searchKeyword.value = value;
                controller.loadTrees();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.trees.isEmpty) {
                return const Center(child: Text('Belum ada data pohon'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, index) {
                  final tree = controller.trees[index];
                  return TreeCard(
                    tree: tree,
                    onTap: () => Get.toNamed('/detail', arguments: tree),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: controller.trees.length,
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/form'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pohon'),
      ),
    );
  }
}
