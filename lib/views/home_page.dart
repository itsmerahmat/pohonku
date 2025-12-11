import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:treedocs/controllers/group_controller.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/views/widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GroupController controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Init TreeController untuk keperluan lain
    Get.put(TreeController(), permanent: true);
    
    // Init GroupController untuk home page
    controller = Get.put(GroupController(), permanent: true);
    
    // Load data SETELAH frame pertama selesai render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.loadGroups();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel timer sebelumnya jika ada
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Set timer baru dengan delay 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      controller.searchKeyword.value = value;
      controller.loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar dengan Gradient
          SliverAppBar(
            expandedHeight: 110,
            // floating: false,
            // pinned: true,
            // snap: false,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pohonku',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Dokumentasi Pohon Digital',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(Icons.map, color: Colors.white),
                            //   onPressed: () => Get.toNamed('/map'),
                            //   tooltip: 'Lihat Peta',
                            // ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: controller.loadGroups,
                              tooltip: 'Segarkan',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari varietas atau blok...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
          ),
          
          // Stats Card
          SliverToBoxAdapter(
            child: Obx(() {
              final totalGroups = controller.groups.length;
              final totalTrees = controller.groups.fold<int>(
                0,
                (sum, group) => sum + (group['count'] as int),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.primaryContainer.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.forest,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalTrees',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'Pohon',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondaryContainer,
                              colorScheme.secondaryContainer.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.category,
                              color: colorScheme.secondary,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalGroups',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            Text(
                              'Grup',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
          // List Content - Group by Varietas & Blok
          Obx(() {
            if (controller.loading.value) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Skeletonizer(
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: 5,
                  ),
                ),
              );
            }

            if (controller.groups.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: EmptyState(
                    icon: Icons.park_outlined,
                    title: 'Belum Ada Data Pohon',
                    description: 'Mulai dokumentasi pohon dengan\nmenambahkan data pohon pertama',
                    action: ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/session'),
                      icon: const Icon(Icons.add),
                      label: const Text('Mulai Sesi Baru'),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) {
                    final group = controller.groups[index];
                    final varietas = group['varietas'] as String;
                    final blok = group['blok'] as String;
                    final count = group['count'] as int;
                    final lastUpdated = group['last_updated'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GroupCard(
                        varietas: varietas,
                        blok: blok,
                        count: count,
                        lastUpdated: lastUpdated,
                        onTap: () => Get.toNamed('/trees', arguments: {
                          'varietas': varietas,
                          'blok': blok,
                        }),
                      ),
                    );
                  },
                  childCount: controller.groups.length,
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/session'),
        icon: const Icon(Icons.add),
        label: const Text('Sesi Baru'),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String varietas;
  final String blok;
  final int count;
  final String lastUpdated;
  final VoidCallback onTap;

  const _GroupCard({
    required this.varietas,
    required this.blok,
    required this.count,
    required this.lastUpdated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateTime = DateTime.parse(lastUpdated);
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      varietas,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.grid_view,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Blok $blok',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count pohon',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
