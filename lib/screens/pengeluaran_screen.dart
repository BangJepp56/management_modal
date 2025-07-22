import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_card.dart';
import '../widgets/form_input_field.dart';
import '../widgets/primary_button.dart';

class PengeluaranScreen extends StatefulWidget {
  const PengeluaranScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PengeluaranScreenState createState() => _PengeluaranScreenState();
}

class _PengeluaranScreenState extends State<PengeluaranScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _jumlahController = TextEditingController();

  List<Map<String, dynamic>> _pengeluaranList = [];
  int _totalPengeluaran = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPengeluaran();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loadPengeluaran() async {
    try {
      final data = await _dbHelper.getPengeluaran();
      final total = await _dbHelper.getTotalPengeluaran();
      setState(() {
        _pengeluaranList = data;
        _totalPengeluaran = total as int;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data pengeluaran.');
    }
  }

  Future<void> _addPengeluaran() async {
    if (_formKey.currentState!.validate()) {
      final jumlah = int.tryParse(_jumlahController.text);

      if (jumlah == null) {
        _showErrorSnackBar('Pastikan jumlah adalah angka yang valid.');
        return;
      }

      try {
        await _dbHelper.insertPengeluaran({
          'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'keterangan': _keteranganController.text,
          'jumlah': jumlah,
        });

        _keteranganController.clear();
        _jumlahController.clear();
        _selectedDate = DateTime.now();
        _loadPengeluaran();
      } catch (e) {
        _showErrorSnackBar('Gagal menambahkan pengeluaran.');
      }
    }
  }

  Future<void> _deletePengeluaran(int id) async {
    try {
      await _dbHelper.deletePengeluaran(id);
      _loadPengeluaran();
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus pengeluaran.');
    }
  }

  Future<void> _showEditPengeluaranDialog(Map<String, dynamic> pengeluaran) async {
    _keteranganController.text = pengeluaran['keterangan'];
    _jumlahController.text = pengeluaran['jumlah'].toString();
    _selectedDate = DateTime.parse(pengeluaran['tanggal']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Pengeluaran'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _keteranganController,
                  decoration: InputDecoration(labelText: 'Keterangan'),
                  validator: (value) => value?.isEmpty == true ? 'Keterangan harus diisi' : null,
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
                  final jumlah = int.tryParse(_jumlahController.text);

                  if (jumlah == null) {
                    _showErrorSnackBar('Pastikan jumlah adalah angka yang valid.');
                    return;
                  }

                  try {
                    await _dbHelper.updatePengeluaran(pengeluaran['id'], {
                      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
                      'keterangan': _keteranganController.text,
                      'jumlah': jumlah,
                    });
                    Navigator.pop(context);
                    _loadPengeluaran();
                  } catch (e) {
                    _showErrorSnackBar('Gagal memperbarui pengeluaran.');
                  }
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
    _keteranganController.clear();
    _jumlahController.clear();
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
        title: Text('Pengeluaran'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total Pengeluaran Card
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Total Pengeluaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(_totalPengeluaran),
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
                  FormInputField(
                    controller: _keteranganController,
                    labelText: 'Keterangan',
                    prefixIcon: Icons.description,
                    validator: (value) => value?.isEmpty == true ? 'Keterangan harus diisi' : null,
                  ),
                  SizedBox(height: 12),
                  FormInputField(
                    controller: _jumlahController,
                    labelText: 'Jumlah',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Jumlah harus diisi' : null,
                  ),
                  SizedBox(height: 16),
                  PrimaryButton(
                    onPressed: _addPengeluaran,
                    text: 'Tambah Pengeluaran',
                    icon: Icons.add,
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _pengeluaranList.length,
              itemBuilder: (context, index) {
                final item = _pengeluaranList[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFD32F2F),
                      child: Icon(Icons.money_off, color: Colors.white),
                    ),
                    title: Text(item['keterangan'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal']))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(item['jumlah']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showEditPengeluaranDialog(item),
                          icon: Icon(Icons.edit, color: Colors.blue),
                        ),
                        IconButton(
                          onPressed: () => _deletePengeluaran(item['id']),
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