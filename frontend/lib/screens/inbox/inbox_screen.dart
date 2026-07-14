import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../models/leave.dart';
import '../../providers/inbox_provider.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxProvider.notifier).fetchPendingApprovals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);

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
              Tab(text: 'Take Action'),
              Tab(text: 'Notifications'),
              Tab(text: 'Archive'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTakeActionTab(context, inboxState),
          _buildPlaceholderTab('Notifications (0 pending)'),
          _buildPlaceholderTab('Archive (All historical reviews)'),
        ],
      ),
    );
  }

  Widget _buildTakeActionTab(BuildContext context, InboxState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaves = state.pendingLeaves;
    final regularizations = state.pendingRegularizations;

    if (leaves.isEmpty && regularizations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.accent.withOpacity(0.5), size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Pending Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are all caught up!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (leaves.isNotEmpty) ...[
          const Text('Leave Approval Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...leaves.map((app) => _buildLeaveApprovalCard(context, app)),
          const SizedBox(height: 24),
        ],
        if (regularizations.isNotEmpty) ...[
          const Text('Attendance Correction Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...regularizations.map((reg) => _buildRegularizationApprovalCard(context, reg)),
        ],
      ],
    );
  }

  Widget _buildLeaveApprovalCard(BuildContext context, LeaveApplication app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    app.employeeName != null ? app.employeeName!.substring(0, 1) : 'E',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.employeeName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(app.employeeCode ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Leave Request', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppTheme.borderGrey),
            ),
            Text('Leave Type: ${app.leaveTypeName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Dates: ${app.fromDate} to ${app.toDate} (${app.days} Days)'),
            const SizedBox(height: 4),
            Text('Reason: ${app.reason}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _processLeave(app.id, 'Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('REJECT'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _processLeave(app.id, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularizationApprovalCard(BuildContext context, RegularizationRequest reg) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    reg.employeeName != null ? reg.employeeName!.substring(0, 1) : 'E',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reg.employeeName ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(reg.employeeCode ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text('Regularization', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppTheme.borderGrey),
            ),
            Text('Date to correct: ${reg.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Requested Timings: ${reg.requestedIn ?? '--'} to ${reg.requestedOut ?? '--'}'),
            const SizedBox(height: 4),
            Text('Reason: ${reg.reason}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _processRegularization(reg.id, 'Rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('REJECT'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _processRegularization(reg.id, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processLeave(int id, String status) async {
    final ok = await ref.read(inboxProvider.notifier).processLeave(id, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave request successfully $status')));
    }
  }

  void _processRegularization(int id, String status) async {
    final ok = await ref.read(inboxProvider.notifier).processRegularization(id, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance regularization successfully $status')));
    }
  }

  Widget _buildPlaceholderTab(String text) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
    );
  }
}
