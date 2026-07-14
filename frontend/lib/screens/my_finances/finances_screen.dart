import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/finance.dart';
import '../../services/api_service.dart';

class MyFinancesScreen extends ConsumerStatefulWidget {
  const MyFinancesScreen({super.key});

  @override
  ConsumerState<MyFinancesScreen> createState() => _MyFinancesScreenState();
}

class _MyFinancesScreenState extends ConsumerState<MyFinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  FinancesSummary? _summary;
  List<Payslip> _payslips = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadFinanceData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _apiService.getFinancesSummary();
      final payslips = await _apiService.getPayslips();
      if (mounted) {
        setState(() {
          _summary = summary;
          _payslips = payslips;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'My Pay'),
              Tab(text: 'Manage Tax'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(context),
                _buildMyPayTab(context),
                _buildManageTaxTab(context),
              ],
            ),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    final bank = _summary?.bankDetails;
    final stat = _summary?.statutoryInfo;
    final identity = _summary?.identity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payslip / Payroll summary card
          if (_payslips.isNotEmpty) ...[
            _buildPayslipWidget(_payslips.first),
            const SizedBox(height: 16),
          ],

          // Payment Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Bank Name', bank?.bankName ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('Account Number', bank?.accountNo ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('IFSC Code', bank?.ifsc ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('Salary Disbursal Mode', 'Bank Transfer'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Identity Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identity Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  _buildSummaryRow('PAN Card', identity?.pan ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('Aadhaar Card', identity?.aadhaar ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('Date of Birth', identity?.dob ?? '--'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('Official Email', identity?.personalEmail ?? '--'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statutory Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statutory Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  _buildSummaryRow('PF Account Information', stat?.pfAccount ?? 'Not Provisioned'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('ESI Account Information', stat?.esiStatus ?? 'Not Provisioned'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('PT Details (State-Specific)', stat?.ptState ?? 'Not Provisioned'),
                  const Divider(color: AppTheme.borderGrey),
                  _buildSummaryRow('LWF Details', stat?.lwfStatus ?? 'Disabled'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipWidget(Payslip p) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final String monthName = months[p.month - 1];

    return Card(
      color: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAYSLIP - $monthName ${p.year}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Payslip Download'),
                        content: Text('Downloading payslip PDF: $monthName ${p.year} ... (simulated successful download)'),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE'))],
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, color: Colors.white, size: 18),
                  label: const Text('DOWNLOAD PDF', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPayslipAmountCol('Gross Earnings', '₹${p.gross}'),
                _buildPayslipAmountCol('Deductions', '₹${p.deductions}'),
                _buildPayslipAmountCol('Net Pay Disbursed', '₹${p.netPay}', isNet: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipAmountCol(String title, String val, {bool isNet = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          val,
          style: TextStyle(
            color: isNet ? AppTheme.accent : Colors.white,
            fontSize: isNet ? 20 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14))),
          Expanded(child: Text(val, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildMyPayTab(BuildContext context) {
    if (_payslips.isEmpty) {
      return const Center(child: Text('No historical payslips loaded.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payslips.length,
      separatorBuilder: (context, idx) => const Divider(color: AppTheme.borderGrey),
      itemBuilder: (context, index) {
        final p = _payslips[index];
        return ListTile(
          leading: const CircleAvatar(backgroundColor: AppTheme.bgLight, child: Icon(Icons.payments_outlined, color: AppTheme.primary)),
          title: Text('Salary Payslip Month ${p.month} ${p.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Gross: ₹${p.gross} | Deductions: ₹${p.deductions}'),
          trailing: Text('₹${p.netPay}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
        );
      },
    );
  }

  Widget _buildManageTaxTab(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, color: AppTheme.accent, size: 40),
              const SizedBox(height: 16),
              const Text('Manage Tax (Section 80C/80D)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text(
                'Verify investment declarations, old vs new regime calculations, and submit tax proofs. Stubs are configured on the backend.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('SUBMIT INVESTMENT PROOF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
