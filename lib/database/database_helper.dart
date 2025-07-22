import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'fotokopian.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE modal_awal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_barang TEXT NOT NULL,
        harga_satuan INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        total INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        keterangan TEXT NOT NULL,
        jumlah INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pemasukan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        jenis_layanan TEXT NOT NULL,
        jumlah_transaksi INTEGER NOT NULL,
        total_harga INTEGER NOT NULL
      )
    ''');
  }

  // Modal Awal Methods
  Future<int> insertModalAwal(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('modal_awal', data);
  }

  Future<List<Map<String, dynamic>>> getModalAwal() async {
    final db = await database;
    return await db.query('modal_awal', orderBy: 'id DESC');
  }

  Future<int> deleteModalAwal(int id) async {
    final db = await database;
    return await db.delete('modal_awal', where: 'id = ?', whereArgs: [id]);
  }

  // Pengeluaran Methods
  Future<int> insertPengeluaran(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pengeluaran', data);
  }

  Future<List<Map<String, dynamic>>> getPengeluaran() async {
    final db = await database;
    return await db.query('pengeluaran', orderBy: 'tanggal DESC, id DESC');
  }

  Future<int> deletePengeluaran(int id) async {
    final db = await database;
    return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }

  // Pemasukan Methods
  Future<int> insertPemasukan(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pemasukan', data);
  }

  Future<List<Map<String, dynamic>>> getPemasukan() async {
    final db = await database;
    return await db.query('pemasukan', orderBy: 'tanggal DESC, id DESC');
  }

  Future<int> deletePemasukan(int id) async {
    final db = await database;
    return await db.delete('pemasukan', where: 'id = ?', whereArgs: [id]);
  }

  // Summary Methods
  Future<int> getTotalModal() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total) as total FROM modal_awal');
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalPengeluaran() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(jumlah) as total FROM pengeluaran');
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalPemasukan() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(total_harga) as total FROM pemasukan');
    return result.first['total'] as int? ?? 0;
  }
}