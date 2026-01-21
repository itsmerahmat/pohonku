import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/capture_controller.dart';

import '../controllers/group_controller.dart';

class ContinuousCapturePage extends StatefulWidget {
  const ContinuousCapturePage({super.key});

  @override
  State<ContinuousCapturePage> createState() => _ContinuousCapturePageState();
}

class _ContinuousCapturePageState extends State<ContinuousCapturePage> {
  late final CaptureController controller;
  final _idPohonController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    controller = Get.put(
      CaptureController(
        varietas: args['varietas'],
        blok: args['blok'],
        autoIdMode: args['autoIdMode'] ?? false,
      ),
    );

    // Initialize camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeCamera();
      // Request focus untuk menangkap keyboard events dari bluetooth remote
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _idPohonController.dispose();
    _focusNode.dispose();
    Get.delete<CaptureController>();
    super.dispose();
  }

  // Handle key events dari bluetooth remote atau volume buttons
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Volume Up, Volume Down, Enter, atau Space dari bluetooth remote
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeDown ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select) {
        // Trigger capture jika dalam ready mode
        if (controller.isReady.value && !controller.isCapturing.value) {
          controller.capturePhoto();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Obx(() => Text('Pohon ${controller.currentTreeNumber.value}')),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleFinish,
              tooltip: 'Selesai',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.forest, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.varietas,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Blok ${controller.blok}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${controller.savedTreesCount.value} Tersimpan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ID Pohon Input or Auto Badge
              if (controller.autoIdMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondaryContainer,
                        colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode ID Otomatis',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => Text(
                                'ID Pohon: ${controller.currentTreeId.value.isEmpty ? "---" : controller.currentTreeId.value}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
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
                      const Text(
                        'ID Pohon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _idPohonController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 001',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        onChanged: (value) {
                          controller.currentTreeId.value = value;
                        },
                      ),
                    ],
                  ),
                ),
              // const SizedBox(height: 12),

              // // Pengaturan getaran
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(16),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withValues(alpha: 0.05),
              //         blurRadius: 10,
              //         offset: const Offset(0, 2),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       const Icon(Icons.vibration, color: Colors.blue),
              //       const SizedBox(width: 12),
              //       const Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Getaran saat foto',
              //               style: TextStyle(
              //                 fontSize: 16,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //             SizedBox(height: 4),
              //             Text(
              //               'Aktifkan atau nonaktifkan getaran ketika foto berhasil diambil',
              //               style: TextStyle(
              //                 fontSize: 12,
              //                 color: Colors.grey,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Obx(() => Switch(
              //             value: controller.isVibrationEnabled.value,
              //             onChanged: (value) {
              //               controller.isVibrationEnabled.value = value;
              //             },
              //           )),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 20),

              // Camera Preview (jika ready mode)
              Obx(() {
                if (!controller.isReady.value) {
                  return const SizedBox.shrink();
                }

                final screenHeight = MediaQuery.of(context).size.height;
                final cameraHeight =
                    screenHeight * 0.6; // 60% dari tinggi layar

                if (!controller.isCameraInitialized.value) {
                  return Container(
                    height: cameraHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                return Container(
                  height: cameraHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Preview langsung dipaksa ke rasio 4:3 (portrait = 3:4), tanpa framing overlay.
                        Center(
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: ClipRect(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: controller
                                      .cameraController!
                                      .value
                                      .previewSize!
                                      .height,
                                  height: controller
                                      .cameraController!
                                      .value
                                      .previewSize!
                                      .width,
                                  child: CameraPreview(
                                    controller.cameraController!,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Overlay info
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'Foto ${controller.currentPhotoIndex.value + 1}/4',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Tombol capture manual
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: controller.capturePhoto,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera,
                                  color: colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Photo Grid
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
                        const Icon(Icons.photo_camera, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Foto Pohon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.currentPhotoIndex.value}/4',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final photos = controller.currentPhotos.toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                        itemCount: 4,
                        itemBuilder: (_, index) {
                          final path = photos[index];
                          final isProcessing =
                              controller.isProcessingPhotos[index];
                          final isCurrent =
                              index == controller.currentPhotoIndex.value;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: path != null
                                    ? Colors.green
                                    : isCurrent
                                    ? colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isCurrent ? 3 : 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: path == null ? Colors.grey[50] : null,
                            ),
                            child: path == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isCurrent
                                            ? Icons.camera_alt
                                            : Icons.photo_camera_back,
                                        size: 40,
                                        color: isCurrent
                                            ? colorScheme.primary
                                            : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Foto ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrent
                                              ? colorScheme.primary
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      if (isProcessing) ...[
                                        const SizedBox(height: 8),
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Memproses…',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ] else if (isCurrent)
                                        Text(
                                          'Siap',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Obx(() {
                final canCapture =
                    controller.autoIdMode ||
                    controller.currentTreeId.value.isNotEmpty;
                final photoIndex = controller.currentPhotoIndex.value;
                final isCompleted = photoIndex >= 4;

                if (isCompleted) {
                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _handleNextTree,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.navigate_next),
                          label: const Text(
                            'Berikutnya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleFinish,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Obx(() {
                  final isCapturing = controller.isCapturing.value;
                  final isReady = controller.isReady.value;

                  if (isReady) {
                    // Mode capture aktif - tampilkan tombol manual
                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: controller.capturePhoto,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              'Ambil Foto ${photoIndex + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: controller.cancelCapture,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (canCapture && !isCapturing)
                          ? _handleCapture
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: (canCapture && !isCapturing)
                            ? null
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        'Mulai Mode Capture',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCapture() async {
    // Request focus kembali setelah memulai mode capture
    _focusNode.requestFocus();
    await controller.startContinuousCapture();
  }

  void _handleNextTree() {
    _idPohonController.clear();
    controller.startNewTree();
  }

  void _handleFinish() {
    final count = controller.savedTreesCount.value;

    // Kembali ke halaman depan
    Get.until((route) => route.isFirst);

    // Refresh data di home page
    try {
      final groupController = Get.find<GroupController>();
      groupController.loadGroups();
    } catch (e) {
      // GroupController tidak ditemukan
    }

    Get.snackbar(
      'Sesi Selesai!',
      '$count pohon berhasil disimpan',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
