import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/models/tree_model.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  late final TreeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<TreeController>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Lokasi Pohon'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerToCurrentLocation,
            tooltip: 'Lokasi Saya',
          ),
        ],
      ),
      body: Obx(() {
        final treesWithLocation = controller.trees
            .where((tree) => tree.latitude != null && tree.longitude != null)
            .toList();

        if (treesWithLocation.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pohon dengan lokasi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Hitung center dari semua lokasi pohon
        double avgLat = treesWithLocation.fold(
                0.0, (sum, tree) => sum + tree.latitude!) /
            treesWithLocation.length;
        double avgLng = treesWithLocation.fold(
                0.0, (sum, tree) => sum + tree.longitude!) /
            treesWithLocation.length;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(avgLat, avgLng),
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.treedocs',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: treesWithLocation.map((tree) {
                    return Marker(
                      point: LatLng(tree.latitude!, tree.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showTreeInfo(tree),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.park,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            // Info Card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${treesWithLocation.length} pohon dengan lokasi GPS',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showTreeInfo(TreeModel tree) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.park,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tree.varietas,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Blok ${tree.blok} • No. ${tree.nomorPohon}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              Icons.location_on,
              'Koordinat',
              '${tree.latitude!.toStringAsFixed(6)}, ${tree.longitude!.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.photo_library,
              'Foto',
              '${tree.photos.length} foto tersimpan',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed('/detail', arguments: tree);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Lihat Detail'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _mapController.move(
                        LatLng(tree.latitude!, tree.longitude!),
                        18.0,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('Zoom In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _centerToCurrentLocation() async {
    final latLng = await controller.getCurrentLatLng();
    if (latLng != null && latLng[0] != null && latLng[1] != null) {
      _mapController.move(LatLng(latLng[0]!, latLng[1]!), 15.0);
      Get.snackbar(
        'Lokasi Ditemukan',
        'Peta dipusatkan ke lokasi Anda',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.my_location, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Gagal',
        'Tidak dapat mengambil lokasi Anda',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
