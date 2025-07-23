// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
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
    try {
      String path = join(await getDatabasesPath(), 'fotokopian.db');
      if (kDebugMode) {
        print('Database path: $path');
      }
      
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          if (kDebugMode) {
            print('Database opened successfully');
          }
          // Test database connection
          await db.rawQuery('SELECT 1');
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database: $e');
      }
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      if (kDebugMode) {
        print('Creating database tables...');
      }
      
      await db.execute('''
        CREATE TABLE modal_awal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama_barang TEXT NOT NULL,
          harga_satuan INTEGER NOT NULL,
          jumlah INTEGER NOT NULL,
          total INTEGER NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE pengeluaran (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal TEXT NOT NULL,
          keterangan TEXT NOT NULL,
          jumlah INTEGER NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE pemasukan (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal TEXT NOT NULL,
          jenis_layanan TEXT NOT NULL,
          jumlah_transaksi INTEGER NOT NULL,
          total_harga INTEGER NOT NULL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      if (kDebugMode) {
        print('Database tables created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating database tables: $e');
      }
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      if (kDebugMode) {
        print('Upgrading database from version $oldVersion to $newVersion');
      }
      
      if (oldVersion < 2) {
        // Check if columns already exist before adding them
        final modalColumns = await db.rawQuery("PRAGMA table_info(modal_awal)");
        final hasCreatedAt = modalColumns.any((col) => col['name'] == 'createdAt');
        final hasUpdatedAt = modalColumns.any((col) => col['name'] == 'updatedAt');
        
        if (!hasCreatedAt) {
          await db.execute("ALTER TABLE modal_awal ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }
        if (!hasUpdatedAt) {
          await db.execute("ALTER TABLE modal_awal ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }

        // Similar checks for other tables
        final pengeluaranColumns = await db.rawQuery("PRAGMA table_info(pengeluaran)");
        final pengeluaranHasCreatedAt = pengeluaranColumns.any((col) => col['name'] == 'createdAt');
        final pengeluaranHasUpdatedAt = pengeluaranColumns.any((col) => col['name'] == 'updatedAt');
        
        if (!pengeluaranHasCreatedAt) {
          await db.execute("ALTER TABLE pengeluaran ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }
        if (!pengeluaranHasUpdatedAt) {
          await db.execute("ALTER TABLE pengeluaran ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }

        final pemasukanColumns = await db.rawQuery("PRAGMA table_info(pemasukan)");
        final pemasukanHasCreatedAt = pemasukanColumns.any((col) => col['name'] == 'createdAt');
        final pemasukanHasUpdatedAt = pemasukanColumns.any((col) => col['name'] == 'updatedAt');
        
        if (!pemasukanHasCreatedAt) {
          await db.execute("ALTER TABLE pemasukan ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }
        if (!pemasukanHasUpdatedAt) {
          await db.execute("ALTER TABLE pemasukan ADD COLUMN updatedAt TEXT DEFAULT CURRENT_TIMESTAMP");
        }
      }
      
      if (kDebugMode) {
        print('Database upgrade completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error upgrading database: $e');
      }
      rethrow;
    }
  }

  // Helper method to validate database connection
  Future<bool> isDatabaseReady() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Database not ready: $e');
      }
      return false;
    }
  }

  // Modal Awal Methods
  Future<int> insertModalAwal(Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      // Validate required fields
      if (data['nama_barang'] == null || data['nama_barang'].toString().trim().isEmpty) {
        throw Exception('Nama barang tidak boleh kosong');
      }
      if (data['harga_satuan'] == null || data['harga_satuan'] <= 0) {
        throw Exception('Harga satuan harus lebih dari 0');
      }
      if (data['jumlah'] == null || data['jumlah'] <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }
      if (data['total'] == null || data['total'] <= 0) {
        throw Exception('Total harus lebih dari 0');
      }

      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      if (kDebugMode) {
        print('Inserting modal awal: $data');
      }
      
      final result = await db.insert(
        'modal_awal', 
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('Insert modal awal result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting modal awal: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTotalModal() async {
    try {
      final db = await database;
      if (kDebugMode) {
        print('Fetching modal awal data...');
      }
      
      final result = await db.query(
        'modal_awal', 
        orderBy: 'id DESC',
      );
      
      if (kDebugMode) {
        print('Modal awal data fetched: ${result.length} records');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting modal awal: $e');
      }
      rethrow;
    }
  }

  Future<int> deleteModalAwal(int id) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }
      
      if (kDebugMode) {
        print('Deleting modal awal with ID: $id');
      }
      
      final result = await db.delete(
        'modal_awal', 
        where: 'id = ?', 
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('Delete modal awal result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting modal awal: $e');
      }
      rethrow;
    }
  }

  Future<int> updateModalAwal(int id, Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }

      // Validate required fields
      if (data['nama_barang'] != null && data['nama_barang'].toString().trim().isEmpty) {
        throw Exception('Nama barang tidak boleh kosong');
      }
      if (data['harga_satuan'] != null && data['harga_satuan'] <= 0) {
        throw Exception('Harga satuan harus lebih dari 0');
      }
      if (data['jumlah'] != null && data['jumlah'] <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }
      if (data['total'] != null && data['total'] <= 0) {
        throw Exception('Total harus lebih dari 0');
      }

      data['updatedAt'] = DateTime.now().toIso8601String();
      
      if (kDebugMode) {
        print('Updating modal awal ID $id with data: $data');
      }
      
      final result = await db.update(
        'modal_awal', 
        data, 
        where: 'id = ?', 
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('Update modal awal result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating modal awal: $e');
      }
      rethrow;
    }
  }

  // Pengeluaran Methods
  Future<int> insertPengeluaran(Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      // Validate required fields
      if (data['tanggal'] == null || data['tanggal'].toString().trim().isEmpty) {
        throw Exception('Tanggal tidak boleh kosong');
      }
      if (data['keterangan'] == null || data['keterangan'].toString().trim().isEmpty) {
        throw Exception('Keterangan tidak boleh kosong');
      }
      if (data['jumlah'] == null || data['jumlah'] <= 0) {
        throw Exception('Jumlah harus lebih dari 0');
      }

      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      return await db.insert('pengeluaran', data);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting pengeluaran: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPengeluaran() async {
    try {
      final db = await database;
      return await db.query('pengeluaran', orderBy: 'tanggal DESC, id DESC');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pengeluaran: $e');
      }
      rethrow;
    }
  }

  Future<int> updatePengeluaran(int id, Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }

      data['updatedAt'] = DateTime.now().toIso8601String();
      return await db.update('pengeluaran', data, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pengeluaran: $e');
      }
      rethrow;
    }
  }

  Future<int> deletePengeluaran(int id) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }
      
      return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting pengeluaran: $e');
      }
      rethrow;
    }
  }

  // Pemasukan Methods
  Future<int> insertPemasukan(Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      // Validate required fields
      if (data['tanggal'] == null || data['tanggal'].toString().trim().isEmpty) {
        throw Exception('Tanggal tidak boleh kosong');
      }
      if (data['jenis_layanan'] == null || data['jenis_layanan'].toString().trim().isEmpty) {
        throw Exception('Jenis layanan tidak boleh kosong');
      }
      if (data['jumlah_transaksi'] == null || data['jumlah_transaksi'] <= 0) {
        throw Exception('Jumlah transaksi harus lebih dari 0');
      }
      if (data['total_harga'] == null || data['total_harga'] <= 0) {
        throw Exception('Total harga harus lebih dari 0');
      }

      data['createdAt'] = DateTime.now().toIso8601String();
      data['updatedAt'] = DateTime.now().toIso8601String();
      
      return await db.insert('pemasukan', data);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting pemasukan: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPemasukan() async {
    try {
      final db = await database;
      return await db.query('pemasukan', orderBy: 'tanggal DESC, id DESC');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pemasukan: $e');
      }
      rethrow;
    }
  }

  Future<int> updatePemasukan(int id, Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }

      // Validate required fields if they exist in data
      if (data['tanggal'] != null && data['tanggal'].toString().trim().isEmpty) {
        throw Exception('Tanggal tidak boleh kosong');
      }
      if (data['jenis_layanan'] != null && data['jenis_layanan'].toString().trim().isEmpty) {
        throw Exception('Jenis layanan tidak boleh kosong');
      }
      if (data['jumlah_transaksi'] != null && data['jumlah_transaksi'] <= 0) {
        throw Exception('Jumlah transaksi harus lebih dari 0');
      }
      if (data['total_harga'] != null && data['total_harga'] <= 0) {
        throw Exception('Total harga harus lebih dari 0');
      }

      data['updatedAt'] = DateTime.now().toIso8601String();
      
      if (kDebugMode) {
        print('Updating pemasukan ID $id with data: $data');
      }
      
      final result = await db.update(
        'pemasukan', 
        data, 
        where: 'id = ?', 
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('Update pemasukan result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pemasukan: $e');
      }
      rethrow;
    }
  }

  Future<int> deletePemasukan(int id) async {
    try {
      final db = await database;
      
      if (id <= 0) {
        throw Exception('ID tidak valid');
      }
      
      if (kDebugMode) {
        print('Deleting pemasukan with ID: $id');
      }
      
      final result = await db.delete(
        'pemasukan', 
        where: 'id = ?', 
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('Delete pemasukan result: $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting pemasukan: $e');
      }
      rethrow;
    }
  }

  // Additional utility methods
  Future<Map<String, dynamic>> getTotalModalAwal() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(total) as total_modal FROM modal_awal'
      );
      
      return {
        'total_modal': result.first['total_modal'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting total modal awal: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTotalPengeluaran({String? startDate, String? endDate}) async {
    try {
      final db = await database;
      String query = 'SELECT SUM(jumlah) as total_pengeluaran FROM pengeluaran';
      List<dynamic> args = [];

      if (startDate != null && endDate != null) {
        query += ' WHERE tanggal BETWEEN ? AND ?';
        args.addAll([startDate, endDate]);
      }
      
      final result = await db.rawQuery(query, args);
      
      return {
        'total_pengeluaran': result.first['total_pengeluaran'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting total pengeluaran: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTotalPemasukan({String? startDate, String? endDate}) async {
    try {
      final db = await database;
      String query = 'SELECT SUM(total_harga) as total_pemasukan, SUM(jumlah_transaksi) as total_transaksi FROM pemasukan';
      List<dynamic> args = [];

      if (startDate != null && endDate != null) {
        query += ' WHERE tanggal BETWEEN ? AND ?';
        args.addAll([startDate, endDate]);
      }
      
      final result = await db.rawQuery(query, args);
      
      return {
        'total_pemasukan': result.first['total_pemasukan'] ?? 0,
        'total_transaksi': result.first['total_transaksi'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting total pemasukan: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFinancialSummary({String? startDate, String? endDate}) async {
    try {
      final modalAwal = await getTotalModalAwal();
      final pengeluaran = await getTotalPengeluaran(startDate: startDate, endDate: endDate);
      final pemasukan = await getTotalPemasukan(startDate: startDate, endDate: endDate);

      final totalModal = modalAwal['total_modal'] as int;
      final totalPengeluaran = pengeluaran['total_pengeluaran'] as int;
      final totalPemasukan = pemasukan['total_pemasukan'] as int;
      final totalTransaksi = pemasukan['total_transaksi'] as int;

      return {
        'total_modal': totalModal,
        'total_pengeluaran': totalPengeluaran,
        'total_pemasukan': totalPemasukan,
        'total_transaksi': totalTransaksi,
        'laba_rugi': totalPemasukan - totalPengeluaran,
        'saldo': totalModal + totalPemasukan - totalPengeluaran,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting financial summary: $e');
      }
      rethrow;
    }
  }

  // Close database connection
  Future<void> closeDatabase() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
        if (kDebugMode) {
          print('Database closed successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error closing database: $e');
      }
      rethrow;
    }
  }

  // Delete database (for testing purposes)
  Future<void> deleteDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'fotokopian.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      if (kDebugMode) {
        print('Database deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting database: $e');
      }
      rethrow;
    }
  }

  Future getKategoriPemasukan() async {}

  Future<void> insertKategoriPemasukan(String kategori) async {}

  Future<void> deleteKategoriPemasukan(String kategori) async {}
}