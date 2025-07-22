
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';

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

  Future<void> _loadModal() async {
    final data = await _dbHelper.getModalAwal();
    final total = await _dbHelper.getTotalModal();
    setState(() {
      _modalList = data;
      _totalModal = total;
    });
  }

  Future<void> _addModal() async {
    if (_formKey.currentState!.validate()) {
      final hargaSatuan = int.parse(_hargaSatuanController.text);
      final jumlah = int.parse(_jumlahController.text);
      final total = hargaSatuan * jumlah;

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
    }
  }

  Future<void> _deleteModal(int id) async {
    await _dbHelper.deleteModalAwal(id);
    _loadModal();
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
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _namaBarangController,
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Nama barang harus diisi' : null,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hargaSatuanController,
                          decoration: InputDecoration(
                            labelText: 'Harga Satuan',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Harga harus diisi' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _jumlahController,
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addModal,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Modal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
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