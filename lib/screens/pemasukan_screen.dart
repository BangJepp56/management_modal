// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_card.dart';
import '../widgets/form_input_field.dart';
import '../widgets/primary_button.dart';

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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadPemasukan() async {
    try {
      final data = await _dbHelper.getPemasukan();
      final total = await _dbHelper.getTotalPemasukan();
      setState(() {
        _pemasukanList = data;
        _totalPemasukan = total;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data pemasukan.');
    }
  }

  Future<void> _addPemasukan() async {
    if (_formKey.currentState!.validate()) {
      final jumlahTransaksi = int.tryParse(_jumlahTransaksiController.text);
      final totalHarga = int.tryParse(_totalHargaController.text);

      if (jumlahTransaksi == null || totalHarga == null) {
        _showErrorSnackBar('Pastikan jumlah transaksi dan total harga adalah angka yang valid.');
        return;
      }

      try {
        await _dbHelper.insertPemasukan({
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'jenis_layanan': _jenisLayananController.text,
          'jumlah_transaksi': jumlahTransaksi,
          'total_harga': totalHarga,
        });

        _jenisLayananController.clear();
        _jumlahTransaksiController.clear();
        _totalHargaController.clear();
        _selectedDate = DateTime.now();
        _loadPemasukan();
      } catch (e) {
        _showErrorSnackBar('Gagal menambahkan pemasukan.');
      }
    }
  }

  Future<void> _deletePemasukan(int id) async {
    try {
      await _dbHelper.deletePemasukan(id);
      _loadPemasukan();
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus pemasukan.');
    }
  }

  Future<void> _showEditPemasukanDialog(Map<String, dynamic> pemasukan) async {
    _jenisLayananController.text = pemasukan['jenis_layanan'];
    _jumlahTransaksiController.text = pemasukan['jumlah_transaksi'].toString();
    _totalHargaController.text = pemasukan['total_harga'].toString();
    _selectedDate = DateTime.parse(pemasukan['tanggal']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Pemasukan'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Jenis Layanan'),
                  value: _jenisLayananController.text,
                  items: _jenisLayananOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _jenisLayananController.text = value;
                      });
                    }
                  },
                  validator: (value) => value == null ? 'Pilih jenis layanan' : null,
                ),
                TextFormField(
                  controller: _jumlahTransaksiController,
                  decoration: InputDecoration(labelText: 'Jumlah Transaksi'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                ),
                TextFormField(
                  controller: _totalHargaController,
                  decoration: InputDecoration(labelText: 'Total Harga'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Total harga harus diisi' : null,
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
                  final jumlahTransaksi = int.tryParse(_jumlahTransaksiController.text);
                  final totalHarga = int.tryParse(_totalHargaController.text);

                  if (jumlahTransaksi == null || totalHarga == null) {
                    _showErrorSnackBar('Pastikan jumlah transaksi dan total harga adalah angka yang valid.');
                    return;
                  }

                  try {
                    await _dbHelper.updatePemasukan(pemasukan['id'], {
                      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
                      'jenis_layanan': _jenisLayananController.text,
                      'jumlah_transaksi': jumlahTransaksi,
                      'total_harga': totalHarga,
                    });
                    Navigator.pop(context);
                    _loadPemasukan();
                  } catch (e) {
                    _showErrorSnackBar('Gagal memperbarui pemasukan.');
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
    _jenisLayananController.clear();
    _jumlahTransaksiController.clear();
    _totalHargaController.clear();
    _selectedDate = DateTime.now();
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
          CustomCard(
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
                        child: FormInputField(
                          controller: _jumlahTransaksiController,
                          labelText: 'Jumlah Transaksi',
                          prefixIcon: Icons.format_list_numbered,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: FormInputField(
                          controller: _totalHargaController,
                          labelText: 'Total Harga',
                          prefixIcon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Total harga harus diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: _addPemasukan,
                    text: 'Tambah Pemasukan',
                    icon: Icons.add,
                    backgroundColor: Color(0xFF1976D2),
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
                          onPressed: () => _showEditPemasukanDialog(item),
                          icon: Icon(Icons.edit, color: Colors.blue),
                        ),
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