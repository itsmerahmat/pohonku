import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:treedocs/models/photo_model.dart';
import 'package:treedocs/models/tree_model.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Database? _db;

  /// Membuka atau membuat database lokal sqflite.
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'treedocs.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabel trees menyimpan informasi umum per entri pohon.
        await db.execute('''
          CREATE TABLE trees(
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
        ''');
        // Tabel photos menyimpan path file foto dan urutan 1-4.
        await db.execute('''
          CREATE TABLE photos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tree_id INTEGER NOT NULL,
            urutan_foto INTEGER NOT NULL,
            path_file TEXT NOT NULL,
            FOREIGN KEY(tree_id) REFERENCES trees(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _db!;
  }

  /// Menyimpan entri pohon baru beserta 4 foto dalam satu transaksi.
  Future<int> insertTree(TreeModel tree) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final treeId = await txn.insert('trees', tree.toMap());
      for (final photo in tree.photos) {
        await txn.insert('photos', {
          ...photo.toMap(),
          'tree_id': treeId,
        });
      }
      return treeId;
    });
  }

  /// Memperbarui data pohon dan mengganti daftar foto yang tersimpan.
  Future<void> updateTree(TreeModel tree) async {
    if (tree.id == null) return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('trees', tree.toMap(), where: 'id = ?', whereArgs: [tree.id]);
      await txn.delete('photos', where: 'tree_id = ?', whereArgs: [tree.id]);
      for (final photo in tree.photos) {
        await txn.insert('photos', {
          ...photo.toMap(),
          'tree_id': tree.id,
        });
      }
    });
  }

  /// Menghapus pohon dan foto terkait dari database.
  Future<void> deleteTree(int treeId) async {
    final db = await database;
    await db.delete('photos', where: 'tree_id = ?', whereArgs: [treeId]);
    await db.delete('trees', where: 'id = ?', whereArgs: [treeId]);
  }

  /// Mengambil seluruh pohon dari database beserta foto yang terasosiasi.
  Future<List<TreeModel>> getTrees({String? query}) async {
    final db = await database;
    final whereClause = (query != null && query.isNotEmpty)
        ? 'WHERE varietas LIKE ? OR blok LIKE ? OR nomor_pohon LIKE ?'
        : '';
    final args = (query != null && query.isNotEmpty)
        ? ['%$query%', '%$query%', '%$query%']
        : null;
    final treeMaps = await db.rawQuery(
      'SELECT * FROM trees $whereClause ORDER BY datetime(tanggal_pengambilan) DESC',
      args,
    );
    final List<TreeModel> results = [];
    for (final map in treeMaps) {
      final photos = await db.query(
        'photos',
        where: 'tree_id = ?',
        whereArgs: [map['id']],
        orderBy: 'urutan_foto ASC',
      );
      results.add(
        TreeModel.fromMap(
          map,
          photos.map((p) => PhotoModel.fromMap(p)).toList(),
        ),
      );
    }
    return results;
  }

  /// Mengambil 1 pohon berdasarkan id untuk detail atau edit.
  Future<TreeModel?> getTreeById(int id) async {
    final db = await database;
    final maps = await db.query('trees', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    final photoMaps = await db.query('photos', where: 'tree_id = ?', whereArgs: [id], orderBy: 'urutan_foto ASC');
    return TreeModel.fromMap(
      maps.first,
      photoMaps.map((p) => PhotoModel.fromMap(p)).toList(),
    );
  }
}
