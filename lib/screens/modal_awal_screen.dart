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

  @override
  void initState() {
    super.initState();
    _loadModal();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadModal() async {
    try {
      final data = await _dbHelper.getModalAwal();
      final total = await _dbHelper.getTotalModal();
      setState(() {
        _modalList = data;
        _totalModal = total;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data modal.');
    }
  }

  Future<void> _addModal() async {
    if (_formKey.currentState!.validate()) {
      final hargaSatuan = int.tryParse(_hargaSatuanController.text);
      final jumlah = int.tryParse(_jumlahController.text);

      if (hargaSatuan == null || jumlah == null) {
        _showErrorSnackBar('Pastikan harga dan jumlah adalah angka yang valid.');
        return;
      }

      final total = hargaSatuan * jumlah;

      try {
        await _dbHelper.insertModalAwal({
          'nama_barang': _namaBarangController.text,
          'harga_satuan': hargaSatuan,
          'jumlah': jumlah,
          'total': total,
        });

        _namaBarangController.clear();
        _hargaSatuanController.clear();
        _jumlahController.clear();
        _loadModal();
      } catch (e) {
        _showErrorSnackBar('Gagal menambahkan modal.');
      }
    }
  }

  Future<void> _deleteModal(int id) async {
    try {
      await _dbHelper.deleteModalAwal(id);
      _loadModal();
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus modal.');
    }
  }

  Future<void> _showEditModalDialog(Map<String, dynamic> modal) async {
    _namaBarangController.text = modal['nama_barang'];
    _hargaSatuanController.text = modal['harga_satuan'].toString();
    _jumlahController.text = modal['jumlah'].toString();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Modal'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaBarangController,
                  decoration: InputDecoration(labelText: 'Nama Barang'),
                  validator: (value) => value?.isEmpty == true ? 'Nama barang harus diisi' : null,
                ),
                TextFormField(
                  controller: _hargaSatuanController,
                  decoration: InputDecoration(labelText: 'Harga Satuan'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Harga harus diisi' : null,
                ),
                TextFormField(
                  controller: _jumlahController,
                  decoration: InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
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
                if (_formKey.currentState!.validate()) {
                  final hargaSatuan = int.tryParse(_hargaSatuanController.text);
                  final jumlah = int.tryParse(_jumlahController.text);

                  if (hargaSatuan == null || jumlah == null) {
                    _showErrorSnackBar('Pastikan harga dan jumlah adalah angka yang valid.');
                    return;
                  }

                  final total = hargaSatuan * jumlah;

                  try {
                    await _dbHelper.updateModalAwal(modal['id'], {
                      'nama_barang': _namaBarangController.text,
                      'harga_satuan': hargaSatuan,
                      'jumlah': jumlah,
                      'total': total,
                    });
                    Navigator.pop(context);
                    _loadModal();
                  } catch (e) {
                    _showErrorSnackBar('Gagal memperbarui modal.');
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
    _namaBarangController.clear();
    _hargaSatuanController.clear();
    _jumlahController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modal Awal'),
        centerTitle: true,
      ),
      body: Column(
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
                    validator: (value) => value?.isEmpty == true ? 'Nama barang harus diisi' : null,
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
                          validator: (value) => value?.isEmpty == true ? 'Harga harus diisi' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FormInputField(
                          controller: _jumlahController,
                          labelText: 'Jumlah',
                          prefixIcon: Icons.format_list_numbered,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: _addModal,
                    text: 'Tambah Modal',
                    icon: Icons.add,
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _modalList.length,
              itemBuilder: (context, index) {
                final item = _modalList[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF2E7D32),
                      child: Text('${item['jumlah']}', style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(item['nama_barang'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${CurrencyFormatter.format(item['harga_satuan'])} x ${item['jumlah']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(item['total']),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showEditModalDialog(item),
                          icon: Icon(Icons.edit, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () => _deleteModal(item['id']),
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