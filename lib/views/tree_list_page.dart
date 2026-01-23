import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/tree_model.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import 'widgets/tree_card.dart';

/// Halaman daftar pohon dalam satu grup (varietas + blok).
///
/// Menampilkan semua pohon yang sudah didokumentasikan
/// dengan fitur export per grup.
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

  Future<void> _showExportDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Foto'),
        content: Text(
          'Export semua foto dari $varietas - Blok $blok?\n\nFile ZIP akan disimpan ke folder Download.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _exportPhotos();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPhotos() async {
    // Show loading
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengexport foto...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      if (trees.isEmpty) {
        Get.back();
        Get.snackbar(
          'Peringatan',
          'Tidak ada foto untuk diexport',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final exportService = ExportService();
      final zipPath = await exportService.exportPhotosByGroup(
        trees.toList(),
        varietas,
        blok,
      );

      Get.back(); // Close loading

      if (zipPath != null) {
        Get.snackbar(
          'Berhasil!',
          'Foto berhasil diexport ke:\n$zipPath',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Gagal',
          'Gagal mengexport foto. Pastikan izin storage diaktifkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export Foto',
          ),
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
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forest_outlined,
                      size: 72,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Pohon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada data pohon untuk\n$varietas - Blok $blok',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.toNamed(
                        '/session',
                        arguments: {'varietas': varietas, 'blok': blok},
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Pohon'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await _loadTrees();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: trees.length,
            itemBuilder: (_, index) {
              final tree = trees[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TreeCard(
                    tree: tree,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final result = await Get.toNamed(
                        '/detail',
                        arguments: tree,
                      );
                      // Reload list if tree was deleted
                      if (result == true) {
                        _loadTrees();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Get.toNamed(
            '/session',
            arguments: {'varietas': varietas, 'blok': blok},
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Pohon'),
      ),
    );
  }
}
