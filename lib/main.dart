import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'views/continuous_capture_page.dart';
import 'views/home_page.dart';
import 'views/session_form_page.dart';
import 'views/tree_detail_page.dart';
import 'views/tree_list_page.dart';

/// Entry point aplikasi Pohonku - Dokumentasi Pohon Digital.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientasi ke portrait untuk UX yang konsisten
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const PohonkuApp());
}

/// Aplikasi utama Pohonku - Dokumentasi Pohon Digital.
///
/// Menggunakan GetX untuk state management dan navigasi.
class PohonkuApp extends StatelessWidget {
  const PohonkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pohonku',
      theme: _buildAppTheme(),
      translations: _AppTranslations(),
      locale: const Locale('id', 'ID'),
      initialRoute: '/',
      getPages: _buildRoutes(),
    );
  }

  /// Membangun tema aplikasi dengan Material 3.
  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  /// Mendaftarkan semua route halaman aplikasi.
  List<GetPage> _buildRoutes() {
    return [
      GetPage(name: '/', page: () => const HomePage()),
      GetPage(name: '/trees', page: () => const TreeListPage()),
      GetPage(name: '/session', page: () => const SessionFormPage()),
      GetPage(name: '/capture', page: () => const ContinuousCapturePage()),
      GetPage(name: '/detail', page: () => const TreeDetailPage()),
    ];
  }
}

/// Terjemahan bahasa Indonesia untuk aplikasi.
class _AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'id_ID': {'app_title': 'Pendataan Pohon'},
  };
}
