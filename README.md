# TreeDocs - Aplikasi Dokumentasi Pohon Digital

Aplikasi mobile untuk pendataan dan dokumentasi pohon secara digital dengan fitur pengambilan foto otomatis, penyimpanan koordinat GPS, dan manajemen data yang terstruktur.

## 📱 Tentang Aplikasi

TreeDocs adalah aplikasi Flutter yang dirancang khusus untuk memudahkan proses dokumentasi pohon di lapangan. Aplikasi ini mendukung pengambilan foto menggunakan remote bluetooth/volume button untuk pengalaman hands-free, menyimpan koordinat GPS otomatis, dan mengelola data pohon berdasarkan varietas dan blok.

## ✨ Fitur Utama

### 📸 Capture Foto Otomatis
- **Mode Capture Manual**: Ambil 4 foto per pohon menggunakan tombol volume atau remote bluetooth
- **Auto-Advance**: Otomatis lanjut ke foto berikutnya tanpa konfirmasi
- **Camera Preview**: Preview kamera real-time dengan ukuran responsif (60% tinggi layar)
- **Hands-Free Operation**: Ideal untuk penggunaan di lapangan dengan remote bluetooth

### 📍 GPS & Lokasi
- **Auto GPS Capture**: Koordinat GPS tersimpan otomatis saat foto pertama diambil
- **High Accuracy**: Menggunakan `LocationAccuracy.high` untuk presisi maksimal
- **GPS Status Check**: Pengecekan status GPS sebelum memulai sesi dokumentasi

### 🗂️ Manajemen Data Terstruktur
- **Grouping by Varietas & Blok**: Data pohon dikelompokkan berdasarkan varietas dan blok
- **Tree List View**: Lihat daftar pohon per grup dengan detail lengkap
- **Search Function**: Cari pohon berdasarkan varietas atau blok dengan debounce
- **Statistics Dashboard**: Tampilan statistik total pohon dan total grup

### 📊 Detail Informasi
- **Photo Grid**: Tampilan grid 4 foto per pohon dengan preview thumbnail
- **File Information**: Nama file, urutan foto, dan metadata lengkap
- **Download Feature**: Download foto ke folder Downloads device
- **GPS Coordinates**: Koordinat lintang dan bujur dengan 6 digit desimal
- **Device Info**: Nama perangkat yang digunakan untuk dokumentasi
- **Timestamp**: Tanggal dan waktu pengambilan dengan format lengkap (dd MMM yyyy, HH:mm)

### 🎨 UI/UX Modern
- **Material Design 3**: Mengikuti guidelines Material Design terbaru
- **Gradient Backgrounds**: Header dan card dengan gradient yang menarik
- **Skeleton Loading**: Loading state yang informatif dan smooth
- **Responsive Design**: Adaptif terhadap berbagai ukuran layar
- **Rounded Corners**: Border radius 12-16px untuk tampilan modern

## 🛠️ Teknologi yang Digunakan

### Core
- **Flutter**: ^3.8.1
- **Dart SDK**: >=3.5.4 <4.0.0

### State Management
- **GetX**: ^4.6.6 - Reactive state management, navigation, dan dependency injection

### Database & Storage
- **sqflite**: ^2.4.1 - Local SQLite database
- **path_provider**: ^2.1.5 - Access to device directories

### Camera & Media
- **camera**: ^0.11.2+1 - Camera plugin untuk manual capture
- **exif**: ^3.3.0 - Extract EXIF metadata (GPS, timestamp)

### Location
- **geolocator**: ^12.0.0 - GPS location services
- **permission_handler**: ^11.3.1 - Runtime permission management

### Mapping
- **flutter_map**: ^7.0.2 - Interactive map display
- **latlong2**: ^0.9.1 - Geographic coordinates handling

### UI Components
- **intl**: ^0.20.1 - Date/time formatting dan internationalization
- **skeletonizer**: ^2.1.1 - Skeleton loading animations

### Device Info
- **device_info_plus**: ^11.2.0 - Device information (manufacturer, model)

## 📁 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── controllers/             # GetX Controllers
│   ├── capture_controller.dart    # Logic capture foto
│   ├── tree_controller.dart       # CRUD pohon
│   └── group_controller.dart      # Grouping varietas/blok
├── models/                  # Data Models
│   ├── tree_model.dart           # Model pohon
│   └── photo_model.dart          # Model foto
├── services/               # Services Layer
│   ├── db_service.dart          # SQLite operations
│   ├── photo_service.dart       # Photo file management
│   └── exif_service.dart        # EXIF data extraction
├── views/                  # UI Pages
│   ├── home_page.dart           # Dashboard utama
│   ├── session_form_page.dart   # Form mulai sesi
│   ├── continuous_capture_page.dart  # Capture 4 foto
│   ├── tree_list_page.dart      # List pohon per grup
│   ├── tree_detail_page.dart    # Detail pohon
│   ├── tree_form_page.dart      # Form edit pohon
│   └── widgets/                 # Reusable widgets
│       └── tree_card.dart
└── routes/                 # Navigation routes
    └── app_routes.dart
```

## 🚀 Cara Install & Menjalankan

### Prerequisites
- Flutter SDK 3.8.1 atau lebih tinggi
- Android Studio / VS Code dengan Flutter extension
- Android device atau emulator (API level 21+)

### Langkah Instalasi

1. **Clone Repository**
   ```bash
   git clone https://github.com/itsmerahmat/treedocs.git
   cd treedocs
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run di Device/Emulator**
   ```bash
   flutter run
   ```

4. **Build APK Release**
   ```bash
   flutter build apk --release
   ```
   APK akan tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`

## 📖 Cara Penggunaan

### 1. Memulai Sesi Dokumentasi
- Klik **"Sesi Baru"** di home page
- Isi **Varietas Pohon** (contoh: Sawit)
- Isi **Blok** (contoh: A1)
- Pastikan GPS aktif
- Klik **"Mulai Dokumentasi"**

### 2. Mengambil Foto Pohon
- Isi **ID Pohon** (contoh: 001)
- Klik **"Mulai Mode Capture"**
- Camera preview akan muncul
- **Ambil foto dengan 3 cara:**
  - Tap tombol kamera di layar
  - Tekan volume up/down
  - Tekan tombol remote bluetooth
- Foto akan otomatis tersimpan dan lanjut ke foto berikutnya
- Setelah 4 foto selesai, data otomatis tersimpan

### 3. Dokumentasi Pohon Berikutnya
- Setelah 4 foto selesai, klik **"Berikutnya"**
- Isi ID pohon yang baru
- Ulangi proses capture

### 4. Mengakhiri Sesi
- Klik **"Selesai"** setelah dokumentasi selesai
- Aplikasi kembali ke home page
- Data otomatis ter-refresh

### 5. Melihat Data Pohon
- Di home page, klik grup **Varietas & Blok**
- Lihat list pohon dalam grup tersebut
- Klik pohon untuk melihat detail lengkap
- Download foto dengan klik icon download

## 🔑 Permission yang Dibutuhkan

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 📊 Database Schema

### Table: trees
```sql
CREATE TABLE trees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  varietas TEXT NOT NULL,
  blok TEXT NOT NULL,
  nomor_pohon TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  tanggal_pengambilan TEXT NOT NULL,
  device_name TEXT NOT NULL,
  file_type TEXT NOT NULL
)
```

### Table: photos
```sql
CREATE TABLE photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tree_id INTEGER NOT NULL,
  urutan_foto INTEGER NOT NULL,
  path_file TEXT NOT NULL,
  FOREIGN KEY (tree_id) REFERENCES trees(id) ON DELETE CASCADE
)
```

## 🎯 Fitur Mendatang (Roadmap)

- [ ] Export data ke CSV/Excel
- [ ] Backup & Restore database
- [ ] Map view untuk visualisasi lokasi pohon
- [ ] Filter & Sort advanced
- [ ] Sync data ke cloud
- [ ] Multi-user support
- [ ] Report generation
- [ ] Offline mode enhancement

## 🐛 Known Issues

- Camera package versi 0.11.2+1 (downgrade dari 0.11.3 untuk kompatibilitas SDK)
- EXIF GPS data tidak tersimpan dari camera package (solved dengan Geolocator)

## 👨‍💻 Developer

**itsmerahmat**
- GitHub: [@itsmerahmat](https://github.com/itsmerahmat)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter Team untuk framework yang luar biasa
- GetX Team untuk state management yang powerful
- Komunitas Flutter Indonesia

---

**Made with ❤️ using Flutter**
