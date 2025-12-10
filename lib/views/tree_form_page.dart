import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/controllers/tree_form_controller.dart';
import 'package:treedocs/models/tree_model.dart';

class TreeFormPage extends StatefulWidget {
  const TreeFormPage({super.key});

  @override
  State<TreeFormPage> createState() => _TreeFormPageState();
}

class _TreeFormPageState extends State<TreeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _varietasController = TextEditingController();
  final _blokController = TextEditingController();
  final _nomorController = TextEditingController();
  late final TreeFormController formController;
  late final TreeController treeController;

  @override
  void initState() {
    super.initState();
    formController = Get.put(TreeFormController());
    treeController = Get.find<TreeController>();
    final TreeModel? existing = Get.arguments as TreeModel?;
    formController.existing = existing;
    if (existing != null) {
      _varietasController.text = existing.varietas;
      _blokController.text = existing.blok;
      _nomorController.text = existing.nomorPohon;
      formController.loadExistingPhotos(existing.photos);
    }
  }

  @override
  void dispose() {
    _varietasController.dispose();
    _blokController.dispose();
    _nomorController.dispose();
    Get.delete<TreeFormController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = formController.existing != null;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Data Pohon' : 'Tambah Data Pohon'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Pohon Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Informasi Pohon',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _varietasController,
                      decoration: const InputDecoration(
                        labelText: 'Varietas Pohon',
                        hintText: 'Contoh: Sawit',
                        prefixIcon: Icon(Icons.park),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _blokController,
                            decoration: const InputDecoration(
                              labelText: 'Blok',
                              hintText: 'A1',
                              prefixIcon: Icon(Icons.grid_on),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nomorController,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Pohon',
                              hintText: '001',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Foto Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Pohon',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ambil 4 foto pohon dari berbagai sudut',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final photosList = formController.photoPaths.toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: 4,
                        itemBuilder: (_, index) {
                          final path = photosList[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showPhotoSourceDialog(index),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: path != null ? Colors.green : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: path == null ? Colors.grey[50] : null,
                                ),
                                child: path == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Foto ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Tap untuk ambil',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: Image.file(
                                                File(path),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => formController.removePhoto(index),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Foto ${index + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Save Button
              Obx(() {
                final photosList = formController.photoPaths.toList();
                final isSaving = formController.saving.value;
                final allFilled = photosList.every((p) => p != null);
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (!allFilled) {
                              Get.snackbar(
                                'Foto Belum Lengkap',
                                'Silakan ambil 4 foto terlebih dahulu',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                icon: const Icon(Icons.warning, color: Colors.white),
                              );
                              return;
                            }
                            await _handleSave();
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: allFilled ? null : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(isSaving ? Icons.hourglass_empty : Icons.save),
                    label: Text(
                      isSaving ? 'Menyimpan...' : 'Simpan Data Pohon',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoSourceDialog(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Sumber Foto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto dengan kamera'),
              onTap: () {
                Navigator.pop(context);
                _handleCapture(index);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih foto dari galeri'),
              onTap: () {
                Navigator.pop(context);
                _handlePickFromGallery(index);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCapture(int index) async {
    await formController.capturePhoto(
      index: index,
      varietas: _varietasController.text.isEmpty ? 'VARIETAS' : _varietasController.text,
      blok: _blokController.text.isEmpty ? 'BLOK' : _blokController.text,
      nomorPohon: _nomorController.text.isEmpty ? 'NOMOR' : _nomorController.text,
    );
  }

  Future<void> _handlePickFromGallery(int index) async {
    await formController.pickPhoto(
      index: index,
      varietas: _varietasController.text.isEmpty ? 'VARIETAS' : _varietasController.text,
      blok: _blokController.text.isEmpty ? 'BLOK' : _blokController.text,
      nomorPohon: _nomorController.text.isEmpty ? 'NOMOR' : _nomorController.text,
    );
  }

  Future<void> _handleSave() async {
    formController.saving.value = true;
    final now = DateTime.now();
    final latLng = await treeController.getCurrentLatLng();
    final deviceName = await treeController.getDeviceName();
    final photos = formController.toPhotoModels(formController.existing?.id);
    final fileType = photos.isNotEmpty ? photos.first.pathFile.split('.').last : 'jpg';

    final tree = TreeModel(
      id: formController.existing?.id,
      varietas: _varietasController.text,
      blok: _blokController.text,
      nomorPohon: _nomorController.text,
      latitude: latLng?[0],
      longitude: latLng?[1],
      tanggalPengambilan: formController.existing?.tanggalPengambilan ?? now,
      deviceName: deviceName,
      fileType: fileType,
      photos: photos,
    );

    if (formController.existing == null) {
      await treeController.addTree(tree);
      Get.back();
      Get.snackbar(
        'Berhasil!',
        'Data pohon berhasil ditambahkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } else {
      await treeController.updateTree(tree);
      // Get updated tree data
      final updatedTree = await treeController.getTreeById(tree.id!);
      Get.back(result: updatedTree);
      Get.snackbar(
        'Berhasil!',
        'Data pohon berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    }

    formController.saving.value = false;
  }
}
