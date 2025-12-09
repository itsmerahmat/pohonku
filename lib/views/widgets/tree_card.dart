import 'package:flutter/material.dart';
import 'package:treedocs/models/tree_model.dart';
import 'package:intl/intl.dart';

class TreeCard extends StatelessWidget {
  final TreeModel tree;
  final VoidCallback? onTap;

  const TreeCard({super.key, required this.tree, this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy HH:mm');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text('${tree.varietas} - Blok ${tree.blok}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Nomor: ${tree.nomorPohon}'),
            Text('Tanggal: ${formatter.format(tree.tanggalPengambilan)}'),
            Text('Foto: ${tree.photos.length}/4'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
