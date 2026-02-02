import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Halaman form untuk memulai sesi pendataan baru.
///
/// User mengisi varietas, blok, dan jumlah foto per pohon
/// sebelum memulai mode capture.
class SessionFormPage extends StatefulWidget {
  const SessionFormPage({super.key});

  @override
  State<SessionFormPage> createState() => _SessionFormPageState();
}

class _SessionFormPageState extends State<SessionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _varietasController = TextEditingController();
  final _blokController = TextEditingController();
  final _photoCountController = TextEditingController(text: '4');
  bool _isGpsEnabled = false;
  bool _checkingGps = true;
  bool _autoIdMode = false;
  bool _isFromExistingGroup =
      false; // Flag untuk disable input jika dari grup existing

  @override
  void initState() {
    super.initState();

    // Pre-fill jika ada arguments dari tree_list_page
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _varietasController.text = args['varietas'] ?? '';
      _blokController.text = args['blok'] ?? '';
      _isFromExistingGroup = true; // Disable input jika dari grup existing

      // Pre-fill photoCount dari grup existing jika ada
      if (args['photoCount'] != null) {
        _photoCountController.text = args['photoCount'].toString();
      }
    }

    _checkGpsStatus();
  }

  @override
  void dispose() {
    _varietasController.dispose();
    _blokController.dispose();
    _photoCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Mulai Sesi Pendataan'), elevation: 0),
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
                            'Sesi Pendataan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Varietas dan Blok akan digunakan untuk semua pohon dalam sesi ini',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
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
                      enabled: !_isFromExistingGroup,
                      decoration: InputDecoration(
                        labelText: 'Varietas Pohon',
                        hintText: 'Contoh: Sawit',
                        prefixIcon: const Icon(Icons.park),
                        suffixIcon: _isFromExistingGroup
                            ? const Icon(Icons.lock, size: 20)
                            : null,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _blokController,
                      enabled: !_isFromExistingGroup,
                      decoration: InputDecoration(
                        labelText: 'Blok',
                        hintText: 'Contoh: A1',
                        prefixIcon: const Icon(Icons.grid_on),
                        suffixIcon: _isFromExistingGroup
                            ? const Icon(Icons.lock, size: 20)
                            : null,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photoCountController,
                      enabled: !_isFromExistingGroup,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Foto per Pohon',
                        hintText: 'Minimal 4, harus genap (mis. 4, 6, 8)',
                        prefixIcon: const Icon(Icons.photo_library),
                        suffixIcon: _isFromExistingGroup
                            ? const Icon(Icons.lock, size: 20)
                            : null,
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        final parsed = int.tryParse(trimmed);
                        if (parsed == null) return 'Masukkan angka';
                        if (parsed < 4) return 'Minimal 4';
                        if (parsed.isOdd) return 'Harus kelipatan 2 (genap)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_fix_high,
                            color: colorScheme.primary,
                            size: 20,
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
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isFromExistingGroup && _autoIdMode
                                      ? 'ID otomatis melanjutkan dari pohon terakhir'
                                      : 'ID pohon otomatis increment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoIdMode,
                            onChanged: (value) {
                              setState(() => _autoIdMode = value);
                            },
                          ),
                        ],
                      ),
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
                      Icon(
                        Icons.warning,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
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
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: Colors.blue.shade200),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(Icons.info, color: Colors.blue.shade700, size: 24),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: Text(
              //           'Varietas dan Blok akan digunakan untuk semua pohon dalam sesi ini',
              //           style: TextStyle(
              //             fontSize: 13,
              //             color: Colors.blue.shade900,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _handleStart();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
    Get.snackbar(
      'GPS Tidak Aktif',
      'Aktifkan GPS untuk menyimpan koordinat lokasi pohon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
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

    final photoCount = int.tryParse(_photoCountController.text.trim()) ?? 4;

    final args = Get.arguments as Map<String, dynamic>?;

    Get.toNamed(
      '/capture',
      arguments: {
        'varietas': args?['varietas'] ?? _varietasController.text,
        'blok': args?['blok'] ?? _blokController.text,
        'autoIdMode': _autoIdMode,
        'photoCount': photoCount,
      },
    );
  }
}
