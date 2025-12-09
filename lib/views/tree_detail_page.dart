import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/models/tree_model.dart';

class TreeDetailPage extends StatelessWidget {
  const TreeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tree = Get.arguments as TreeModel;
    final controller = Get.find<TreeController>();
    final formatter = DateFormat('dd MMM yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pohon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.toNamed('/form', arguments: tree),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus Data?'),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus data pohon ini? Tindakan ini tidak dapat dibatalkan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.removeTree(tree);
                Get.back();
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tree.varietas, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Blok: ${tree.blok} | Nomor: ${tree.nomorPohon}'),
              const SizedBox(height: 8),
              Text('Tanggal: ${formatter.format(tree.tanggalPengambilan)}'),
              Text('Perangkat: ${tree.deviceName}'),
              Text('Tipe File: ${tree.fileType}'),
              if (tree.latitude != null && tree.longitude != null) ...[
                const SizedBox(height: 4),
                Text('Koordinat: ${tree.latitude}, ${tree.longitude}'),
              ] else ...[
                const SizedBox(height: 4),
                const Text('Koordinat: -'),
              ],
              const SizedBox(height: 16),
              Text('Foto Pohon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tree.photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) {
                  final photo = tree.photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photo.pathFile),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
