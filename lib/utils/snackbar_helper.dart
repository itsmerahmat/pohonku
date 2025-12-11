import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static void showSuccess(
    String message, {
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Berhasil!',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  static void showError(
    String message, {
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showWarning(
    String message, {
    String? title,
    Duration? duration,
  }) {
    Get.snackbar(
      title ?? 'Peringatan',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showInfo(
    String message, {
    String? title,
    Duration? duration,
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    Get.snackbar(
      title ?? 'Info',
      message,
      snackPosition: position,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void showWithAction(
    String title,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor ?? Colors.orange,
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          onAction();
        },
        child: Text(
          actionLabel,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
