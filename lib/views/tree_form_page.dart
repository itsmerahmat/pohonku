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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Data Pohon' : 'Tambah Data Pohon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _varietasController,
                  decoration: const InputDecoration(
                    labelText: 'Varietas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _blokController,
                  decoration: const InputDecoration(
                    labelText: 'Blok',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomorController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Pohon',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Text('Ambil 4 Foto Pohon', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Obx(() {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: 4,
                    itemBuilder: (_, index) {
                      final path = formController.photoPaths[index];
                      return InkWell(
                        onTap: () => _handleCapture(index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: path == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 32),
                                    const SizedBox(height: 4),
                                    Text('Foto ${index + 1}'),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: InkWell(
                                        onTap: () => formController.removePhoto(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),
                Obx(() {
                  final allFilled = formController.photoPaths.every((p) => p != null);
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: formController.saving.value
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              if (!allFilled) {
                                Get.snackbar('Foto belum lengkap', 'Silakan ambil 4 foto terlebih dahulu');
                                return;
                              }
                              await _handleSave();
                            },
                      icon: const Icon(Icons.save),
                      label: Text(formController.saving.value ? 'Menyimpan...' : 'Simpan'),
                    ),
                  );
                }),
              ],
            ),
          ),
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
    } else {
      await treeController.updateTree(tree);
    }

    formController.saving.value = false;
    Get.back();
  }
}
