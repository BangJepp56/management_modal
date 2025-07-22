import 'package:flutter/material.dart';
import 'package:management_app/database/database_helper.dart';
import 'package:management_app/utils/currency_formatter.dart';

class ModalAwalScreen extends StatefulWidget {
  const ModalAwalScreen({super.key});

  @override
  State<ModalAwalScreen> createState() => _ModalAwalScreenState();
}

class _ModalAwalScreenState extends State<ModalAwalScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _modalList;

  @override
  void initState() {
    super.initState();
    _loadModalList();
  }

  void _loadModalList() {
    setState(() {
      _modalList = dbHelper.getTotalModal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modal Awal'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _modalList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data modal awal.'));
          }

          final modalList = snapshot.data!;
          return ListView.builder(
            itemCount: modalList.length,
            itemBuilder: (context, index) {
              final item = modalList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item['nama_barang']),
                  subtitle: Text(
                      '${item['jumlah']} x ${CurrencyFormatter.format(item['harga_satuan'])}'),
                  trailing: Text(CurrencyFormatter.format(item['total'])),
                  onTap: () => _showFormDialog(context, item: item),
                  onLongPress: () => _deleteModal(context, item['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFormDialog(BuildContext context, {Map<String, dynamic>? item}) {
    final formKey = GlobalKey<FormState>();
    final namaBarangController = TextEditingController(text: item?['nama_barang']);
    final hargaSatuanController =
        TextEditingController(text: item?['harga_satuan']?.toString());
    final jumlahController = TextEditingController(text: item?['jumlah']?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Tambah Modal Awal' : 'Edit Modal Awal'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaBarangController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama barang tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: hargaSatuanController,
                  decoration: const InputDecoration(
                    labelText: 'Harga Satuan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga satuan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: jumlahController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final data = {
                    'nama_barang': namaBarangController.text,
                    'harga_satuan': int.parse(hargaSatuanController.text),
                    'jumlah': int.parse(jumlahController.text),
                    'total': int.parse(hargaSatuanController.text) *
                        int.parse(jumlahController.text),
                  };

                  if (item == null) {
                    dbHelper.insertModalAwal(data);
                  } else {
                    dbHelper.updateModalAwal(item['id'], data);
                  }

                  _loadModalList();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteModal(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Modal'),
          content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                dbHelper.deleteModalAwal(id);
                _loadModalList();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}