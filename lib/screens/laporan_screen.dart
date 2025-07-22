// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LaporanScreenState createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  String _selectedFilter = 'Hari Ini';
  final List<String> _filterOptions = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];
  
  int _totalModal = 0;
  int _totalPengeluaran = 0;
  int _totalPemasukan = 0;
  List<Map<String, dynamic>> _detailPengeluaran = [];
  List<Map<String, dynamic>> _detailPemasukan = [];

  @override
  void initState() {
    super.initState();
    _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    final modal = await _dbHelper.getTotalModal();
    final pengeluaranData = await _dbHelper.getPengeluaran();
    final pemasukanData = await _dbHelper.getPemasukan();

    // Filter data berdasarkan periode yang dipilih
    final filteredPengeluaran = _filterDataByPeriod(pengeluaranData);
    final filteredPemasukan = _filterDataByPeriod(pemasukanData);

    int totalPengeluaran = 0;
    int totalPemasukan = 0;

    for (var item in filteredPengeluaran) {
      totalPengeluaran += item['jumlah'] as int;
    }

    for (var item in filteredPemasukan) {
      totalPemasukan += item['total_harga'] as int;
    }

    setState(() {
      _totalModal = modal;
      _totalPengeluaran = totalPengeluaran;
      _totalPemasukan = totalPemasukan;
      _detailPengeluaran = filteredPengeluaran;
      _detailPemasukan = filteredPemasukan;
    });
  }

  List<Map<String, dynamic>> _filterDataByPeriod(List<Map<String, dynamic>> data) {
    if (_selectedFilter == 'Semua') return data;

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedFilter) {
      case 'Hari Ini':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Bulan Ini':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        return data;
    }

    return data.where((item) {
      final itemDate = DateTime.parse(item['tanggal']);
      return itemDate.isAfter(startDate.subtract(Duration(days: 1))) && 
             itemDate.isBefore(now.add(Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final labaRugi = _totalPemasukan - _totalModal - _totalPengeluaran;

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Keuangan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Dropdown
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                underline: Container(),
                icon: Icon(Icons.arrow_drop_down),
                items: _filterOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    _loadLaporan();
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            // Summary Cards
            Text(
              'Ringkasan $_selectedFilter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Modal Awal',
                    CurrencyFormatter.format(_totalModal),
                    Color(0xFF2E7D32),
                    Icons.account_balance_wallet,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pengeluaran',
                    CurrencyFormatter.format(_totalPengeluaran),
                    Color(0xFFD32F2F),
                    Icons.money_off,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pemasukan',
                    CurrencyFormatter.format(_totalPemasukan),
                    Color(0xFF1976D2),
                    Icons.monetization_on,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    labaRugi >= 0 ? 'Laba' : 'Rugi',
                    CurrencyFormatter.format(labaRugi.abs()),
                    labaRugi >= 0 ? Color(0xFF388E3C) : Color(0xFFD32F2F),
                    labaRugi >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Detail Pengeluaran
            _buildSectionHeader('Detail Pengeluaran', Color(0xFFD32F2F)),
            SizedBox(height: 8),
            _detailPengeluaran.isEmpty
                ? _buildEmptyState('Tidak ada data pengeluaran')
                : Column(
                    children: _detailPengeluaran.map((item) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFFD32F2F),
                            child: Icon(Icons.money_off, color: Colors.white, size: 20),
                          ),
                          title: Text(item['keterangan'], style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal']))),
                          trailing: Text(
                            CurrencyFormatter.format(item['jumlah']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            SizedBox(height: 20),
            // Detail Pemasukan
            _buildSectionHeader('Detail Pemasukan', Color(0xFF1976D2)),
            SizedBox(height: 8),
            _detailPemasukan.isEmpty
                ? _buildEmptyState('Tidak ada data pemasukan')
                : Column(
                    children: _detailPemasukan.map((item) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF1976D2),
                            child: Icon(Icons.monetization_on, color: Colors.white, size: 20),
                          ),
                          title: Text(item['jenis_layanan'], style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal']))),
                              Text('${item['jumlah_transaksi']} transaksi'),
                            ],
                          ),
                          trailing: Text(
                            CurrencyFormatter.format(item['total_harga']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}