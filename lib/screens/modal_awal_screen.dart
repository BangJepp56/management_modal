// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../widgets/custom_card.dart';
import '../widgets/form_input_field.dart';
import '../widgets/primary_button.dart';

class ModalAwalScreen extends StatefulWidget {
  const ModalAwalScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ModalAwalScreenState createState() => _ModalAwalScreenState();
}

class _ModalAwalScreenState extends State<ModalAwalScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _namaBarangController = TextEditingController();
  final _hargaSatuanController = TextEditingController();
  final _jumlahController = TextEditingController();

  List<Map<String, dynamic>> _modalList = [];
  int _totalModal = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModal();
  }

  @override
  void dispose() {
    _namaBarangController.dispose();
    _hargaSatuanController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadModal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading modal data...');
      final data = await _dbHelper.getTotalModal();
      final total = await _dbHelper.getTotalModal();
      
      print('Modal data loaded: ${data.length} items, total: $total');
      
      if (mounted) {
        setState(() {
          _modalList = data;
          _totalModal = total as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading modal: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Gagal memuat data modal: $e');
      }
    }
  }

  Future<void> _addModal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi input
    final hargaSatuanText = _hargaSatuanController.text.trim();
    final jumlahText = _jumlahController.text.trim();
    final namaBarang = _namaBarangController.text.trim();

    if (hargaSatuanText.isEmpty || jumlahText.isEmpty || namaBarang.isEmpty) {
      _showErrorSnackBar('Semua field harus diisi.');
      return;
    }

    final hargaSatuan = int.tryParse(hargaSatuanText);
    final jumlah = int.tryParse(jumlahText);

    if (hargaSatuan == null || hargaSatuan <= 0) {
      _showErrorSnackBar('Harga satuan harus berupa angka positif.');
      return;
    }

    if (jumlah == null || jumlah <= 0) {
      _showErrorSnackBar('Jumlah harus berupa angka positif.');
      return;
    }

    final total = hargaSatuan * jumlah;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Inserting modal: $namaBarang, $hargaSatuan, $jumlah, $total');
      
      final result = await _dbHelper.insertModalAwal({
        'nama_barang': namaBarang,
        'harga_satuan': hargaSatuan,
        'jumlah': jumlah,
        'total': total,
      });

      print('Insert result: $result');

      if (result > 0) {
        _namaBarangController.clear();
        _hargaSatuanController.clear();
        _jumlahController.clear();
        _showSuccessSnackBar('Modal berhasil ditambahkan.');
        await _loadModal();
      } else {
        _showErrorSnackBar('Gagal menambahkan modal.');
      }
    } catch (e) {
      print('Error adding modal: $e');
      _showErrorSnackBar('Gagal menambahkan modal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteModal(int id) async {
    // Konfirmasi penghapusan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus modal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Deleting modal with id: $id');
      final result = await _dbHelper.deleteModalAwal(id);
      
      if (result > 0) {
        _showSuccessSnackBar('Modal berhasil dihapus.');
        await _loadModal();
      } else {
        _showErrorSnackBar('Gagal menghapus modal.');
      }
    } catch (e) {
      print('Error deleting modal: $e');
      _showErrorSnackBar('Gagal menghapus modal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditModalDialog(Map<String, dynamic> modal) async {
    final editFormKey = GlobalKey<FormState>();
    final editNamaController = TextEditingController(text: modal['nama_barang']);
    final editHargaController = TextEditingController(text: modal['harga_satuan'].toString());
    final editJumlahController = TextEditingController(text: modal['jumlah'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Modal'),
          content: Form(
            key: editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editNamaController,
                  decoration: InputDecoration(labelText: 'Nama Barang'),
                  validator: (value) => value?.trim().isEmpty == true ? 'Nama barang harus diisi' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: editHargaController,
                  decoration: InputDecoration(labelText: 'Harga Satuan'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty == true) return 'Harga harus diisi';
                    final harga = int.tryParse(value!.trim());
                    if (harga == null || harga <= 0) return 'Harga harus berupa angka positif';
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: editJumlahController,
                  decoration: InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty == true) return 'Jumlah harus diisi';
                    final jumlah = int.tryParse(value!.trim());
                    if (jumlah == null || jumlah <= 0) return 'Jumlah harus berupa angka positif';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate()) {
                  final hargaSatuan = int.parse(editHargaController.text.trim());
                  final jumlah = int.parse(editJumlahController.text.trim());
                  final total = hargaSatuan * jumlah;

                  try {
                    print('Updating modal with id: ${modal['id']}');
                    final result = await _dbHelper.updateModalAwal(modal['id'], {
                      'nama_barang': editNamaController.text.trim(),
                      'harga_satuan': hargaSatuan,
                      'jumlah': jumlah,
                      'total': total,
                    });

                    if (result > 0) {
                      Navigator.pop(context);
                      _showSuccessSnackBar('Modal berhasil diperbarui.');
                      _loadModal();
                    } else {
                      _showErrorSnackBar('Gagal memperbarui modal.');
                    }
                  } catch (e) {
                    print('Error updating modal: $e');
                    _showErrorSnackBar('Gagal memperbarui modal: $e');
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );

    editNamaController.dispose();
    editHargaController.dispose();
    editJumlahController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modal Awal'),
        centerTitle: true,
      ),
      body: _isLoading && _modalList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total Modal Card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Modal Awal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(_totalModal),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form
                CustomCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        FormInputField(
                          controller: _namaBarangController,
                          labelText: 'Nama Barang',
                          prefixIcon: Icons.inventory,
                          validator: (value) => value?.trim().isEmpty == true ? 'Nama barang harus diisi' : null,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FormInputField(
                                controller: _hargaSatuanController,
                                labelText: 'Harga Satuan',
                                prefixIcon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.trim().isEmpty == true) return 'Harga harus diisi';
                                  final harga = int.tryParse(value!.trim());
                                  if (harga == null || harga <= 0) return 'Harga harus berupa angka positif';
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: FormInputField(
                                controller: _jumlahController,
                                labelText: 'Jumlah',
                                prefixIcon: Icons.format_list_numbered,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.trim().isEmpty == true) return 'Jumlah harus diisi';
                                  final jumlah = int.tryParse(value!.trim());
                                  if (jumlah == null || jumlah <= 0) return 'Jumlah harus berupa angka positif';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        PrimaryButton(
                          onPressed: _isLoading
                              ? () {}
                              : () {
                                  _addModal();
                                },
                          text: _isLoading ? 'Menyimpan...' : 'Tambah Modal',
                          icon: Icons.add,
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: _modalList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada data modal',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _modalList.length,
                          itemBuilder: (context, index) {
                            final item = _modalList[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(0xFF2E7D32),
                                  child: Text(
                                    '${item['jumlah']}',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  item['nama_barang'] ?? 'Tidak ada nama',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${CurrencyFormatter.format(item['harga_satuan'] ?? 0)} x ${item['jumlah'] ?? 0}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(item['total'] ?? 0),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _isLoading ? null : () => _showEditModalDialog(item),
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                    ),
                                    IconButton(
                                      onPressed: _isLoading ? null : () => _deleteModal(item['id']),
                                      icon: Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}