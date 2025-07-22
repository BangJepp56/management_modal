import 'package:flutter/material.dart';
import 'package:management_app/database/database_helper.dart';
import 'package:management_app/screens/laporan_screen.dart';
import 'package:management_app/screens/modal_awal_screen.dart';
import 'package:management_app/screens/pemasukan_screen.dart';
import 'package:management_app/screens/pengeluaran_screen.dart';
import 'package:management_app/utils/currency_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final dbHelper = DatabaseHelper();
  late Future<Map<String, dynamic>> _financialSummary;

  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
  }

  void _loadFinancialSummary() {
    setState(() {
      _financialSummary = dbHelper.getFinancialSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialSummary,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _financialSummary,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data.'));
          }

          final summary = snapshot.data!;
          return _buildDashboardContent(context, summary);
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: 24),
          Text(
            'Menu Utama',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: <Widget>[
              _buildDashboardItem(
                context,
                'Modal Awal',
                Icons.account_balance_wallet,
                () => _navigateTo(ModalAwalScreen()),
              ),
              _buildDashboardItem(
                context,
                'Pemasukan',
                Icons.arrow_upward,
                () => _navigateTo(PemasukanScreen()),
              ),
              _buildDashboardItem(
                context,
                'Pengeluaran',
                Icons.arrow_downward,
                () => _navigateTo(PengeluaranScreen()),
              ),
              _buildDashboardItem(
                context,
                'Laporan',
                Icons.bar_chart,
                () => _navigateTo(LaporanScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final labaRugi = summary['laba_rugi'] as int;
    final isProfit = labaRugi >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Keuangan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Modal', summary['total_modal']),
            _buildSummaryRow('Total Pemasukan', summary['total_pemasukan']),
            _buildSummaryRow('Total Pengeluaran', summary['total_pengeluaran']),
            const Divider(height: 24),
            _buildSummaryRow(
              'Laba / Rugi',
              labaRugi,
              color: isProfit ? Colors.green[700] : Colors.red[700],
            ),
            _buildSummaryRow(
              'Saldo Akhir',
              summary['saldo'],
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, int value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            CurrencyFormatter.format(value),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadFinancialSummary());
  }
}