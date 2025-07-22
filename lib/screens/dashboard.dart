// lib/screens/dashboard_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_formatter.dart';
import '../screens/modal_awal_screen.dart';
import '../screens/pengeluaran_screen.dart';
import '../screens/pemasukan_screen.dart';
import '../screens/laporan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _totalModal = 0;
  int _totalPengeluaran = 0;
  int _totalPemasukan = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final modal = await _dbHelper.getTotalModal();
    final pengeluaran = await _dbHelper.getTotalPengeluaran();
    final pemasukan = await _dbHelper.getTotalPemasukan();

    setState(() {
      _totalModal = modal as int;
      _totalPengeluaran = pengeluaran as int;
      _totalPemasukan = pemasukan as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labaRugi = _totalPemasukan - _totalModal - _totalPengeluaran;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Keuangan'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Modal',
                      CurrencyFormatter.format(_totalModal),
                      Color(0xFF2E7D32),
                      Icons.account_balance_wallet,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Pengeluaran',
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
                      'Total Pemasukan',
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
              // Menu Cards
              _buildMenuCard(
                'Modal Awal',
                'Kelola barang modal awal',
                Icons.inventory,
                Color(0xFF2E7D32),
                () => _navigateToScreen(ModalAwalScreen()),
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                'Pengeluaran',
                'Catat pengeluaran harian',
                Icons.receipt_long,
                Color(0xFFD32F2F),
                () => _navigateToScreen(PengeluaranScreen()),
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                'Pemasukan',
                'Catat transaksi pemasukan',
                Icons.point_of_sale,
                Color(0xFF1976D2),
                () => _navigateToScreen(PemasukanScreen()),
              ),
              SizedBox(height: 12),
              _buildMenuCard(
                'Laporan',
                'Lihat laporan keuangan',
                Icons.bar_chart,
                Color(0xFF7B1FA2),
                () => _navigateToScreen(LaporanScreen()),
              ),
            ],
          ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _loadSummary();
  }
}