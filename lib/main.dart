import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:treedocs/views/continuous_capture_page.dart';
import 'package:treedocs/views/home_page.dart';
// import 'package:treedocs/views/map_page.dart';
import 'package:treedocs/views/session_form_page.dart';
import 'package:treedocs/views/tree_detail_page.dart';
import 'package:treedocs/views/tree_form_page.dart';
import 'package:treedocs/views/tree_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PohonkuApp());
}

class PohonkuApp extends StatelessWidget {
  const PohonkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pohonku',
      theme: ThemeData(
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      translations: _IdTranslations(),
      locale: const Locale('id', 'ID'),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/trees', page: () => const TreeListPage()),
        GetPage(name: '/session', page: () => const SessionFormPage()),
        GetPage(name: '/capture', page: () => const ContinuousCapturePage()),
        GetPage(name: '/form', page: () => const TreeFormPage()),
        GetPage(name: '/detail', page: () => const TreeDetailPage()),
        // GetPage(name: '/map', page: () => const MapPage()),
      ],
    );
  }
}

class _IdTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'id_ID': {
          'app_title': 'Pendataan Pohon',
        },
      };
}
