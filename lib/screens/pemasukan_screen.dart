// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class PemasukanScreen extends StatefulWidget {
  const PemasukanScreen({super.key});

  @override
  _PemasukanScreenState createState() => _PemasukanScreenState();
}

class _PemasukanScreenState extends State<PemasukanScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _jenisLayananController = TextEditingController();
  final _jumlahTransaksiController = TextEditingController();
  final _totalHargaController = TextEditingController();

  List<Map<String, dynamic>> _pemasukanList = [];
  int _totalPemasukan = 0;
  DateTime _selectedDate = DateTime.now();

  final List<String> _jenisLayananOptions = [
    'Print',
    'Fotokopi',
    'Scan',
    'Jilid',
    'Laminating',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadPemasukan();
  }

  Future<void> _loadPemasukan() async {
    final data = await _dbHelper.getPemasukan();
    final total = await _dbHelper.getTotalPemasukan();
    setState(() {
      _pemasukanList = data;
      _totalPemasukan = total;
    });
  }

  Future<void> _addPemasukan() async {
    if (_formKey.currentState!.validate()) {
      await _dbHelper.insertPemasukan({
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'jenis_layanan': _jenisLayananController.text,
        'jumlah_transaksi': int.parse(_jumlahTransaksiController.text),
        'total_harga': int.parse(_totalHargaController.text),
      });

      _jenisLayananController.clear();
      _jumlahTransaksiController.clear();
      _totalHargaController.clear();
      _selectedDate = DateTime.now();
      _loadPemasukan();
    }
  }

  Future<void> _deletePemasukan(int id) async {
    await _dbHelper.deletePemasukan(id);
    _loadPemasukan();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pemasukan'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total Pemasukan Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Total Pemasukan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(_totalPemasukan),
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
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today),
                          SizedBox(width: 12),
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                          Spacer(),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Jenis Layanan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.business_center),
                    ),
                    items: _jenisLayananOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        _jenisLayananController.text = value;
                      }
                    },
                    validator: (value) => value == null ? 'Pilih jenis layanan' : null,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _jumlahTransaksiController,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Transaksi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _totalHargaController,
                          decoration: InputDecoration(
                            labelText: 'Total Harga',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Total harga harus diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addPemasukan,
                      icon: Icon(Icons.add),
                      label: Text('Tambah Pemasukan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1976D2),
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
              itemCount: _pemasukanList.length,
              itemBuilder: (context, index) {
                final item = _pemasukanList[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF1976D2),
                      child: Icon(Icons.monetization_on, color: Colors.white),
                    ),
                    title: Text(item['jenis_layanan'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal']))),
                        Text('${item['jumlah_transaksi']} transaksi'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(item['total_harga']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deletePemasukan(item['id']),
                          icon: Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    isThreeLine: true,
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