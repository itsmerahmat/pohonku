import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:treedocs/utils/snackbar_helper.dart';

class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key});

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _varietasController = TextEditingController();
  final _blokController = TextEditingController();
  bool _isGpsEnabled = false;
  bool _checkingGps = true;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill jika ada arguments dari tree_list_page
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _varietasController.text = args['varietas'] ?? '';
      _blokController.text = args['blok'] ?? '';
    }
    
    _checkGpsStatus();
  }

  @override
  void dispose() {
    _varietasController.dispose();
    _blokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mulai Sesi Pendataan'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.start,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesi Pendataan Baru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Isi data blok untuk mulai dokumentasi',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Section
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Informasi Blok',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _varietasController,
                      decoration: const InputDecoration(
                        labelText: 'Varietas Pohon',
                        hintText: 'Contoh: Sawit',
                        prefixIcon: Icon(Icons.park),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _blokController,
                      decoration: const InputDecoration(
                        labelText: 'Blok',
                        hintText: 'Contoh: A1',
                        prefixIcon: Icon(Icons.grid_on),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GPS Status Warning
              if (!_checkingGps && !_isGpsEnabled)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPS Belum Aktif',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aktifkan GPS untuk menyimpan koordinat lokasi pohon',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openLocationSettings,
                        child: const Text('Aktifkan'),
                      ),
                    ],
                  ),
                ),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Varietas dan Blok akan digunakan untuk semua pohon dalam sesi ini',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _handleStart,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Mulai Dokumentasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkGpsStatus() async {
    setState(() => _checkingGps = true);
    
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _isGpsEnabled = serviceEnabled;
        _checkingGps = false;
      });

      if (!serviceEnabled) {
        _showGpsWarning();
      }
    } catch (e) {
      setState(() => _checkingGps = false);
    }
  }

  void _showGpsWarning() {
    SnackbarHelper.showWarning(
      'Aktifkan GPS untuk menyimpan koordinat lokasi pohon',
      title: 'GPS Tidak Aktif',
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    // Recheck after 1 second
    Future.delayed(const Duration(seconds: 1), _checkGpsStatus);
  }

  void _handleStart() {
    if (!_formKey.currentState!.validate()) return;

    final args = Get.arguments as Map<String, dynamic>?;
    
    Get.toNamed('/capture', arguments: {
      'varietas': args?['varietas'] ?? _varietasController.text,
      'blok': args?['blok'] ?? _blokController.text,
    });
  }
}
