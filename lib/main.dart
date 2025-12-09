import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:treedocs/controllers/tree_controller.dart';
import 'package:treedocs/views/home_page.dart';
import 'package:treedocs/views/tree_detail_page.dart';
import 'package:treedocs/views/tree_form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi TreeController lebih awal agar database siap sebelum UI tampil.
  Get.put(TreeController());
  runApp(const TreeDocsApp());
}

class TreeDocsApp extends StatelessWidget {
  const TreeDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TreeDocs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      translations: _IdTranslations(),
      locale: const Locale('id', 'ID'),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/form', page: () => const TreeFormPage()),
        GetPage(name: '/detail', page: () => const TreeDetailPage()),
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
