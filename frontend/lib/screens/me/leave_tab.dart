import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/leave.dart';
import '../../providers/leave_provider.dart';

class LeaveTab extends ConsumerStatefulWidget {
  const LeaveTab({super.key});

  @override
  ConsumerState<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends ConsumerState<LeaveTab> {
  final _reasonController = TextEditingController();
  final _daysController = TextEditingController(text: '1');
  LeaveType? _selectedLeaveType;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaveProvider.notifier).fetchLeaveData();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _showApplyLeaveDialog(BuildContext context, List<LeaveType> types) {
    if (types.isNotEmpty && _selectedLeaveType == null) {
      _selectedLeaveType = types.first;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Apply for Leave'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Leave Type Dropdown
                    DropdownButtonFormField<LeaveType>(
                      value: _selectedLeaveType,
                      decoration: const InputDecoration(labelText: 'Leave Type'),
                      items: types.map((type) {
                        return DropdownMenuItem<LeaveType>(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLeaveType = val),
                    ),
                    const SizedBox(height: 12),
                    // From Date Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('From: ${DateFormat('yyyy-MM-dd').format(_fromDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fromDate,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime(2026, 12, 31),
                        );
                        if (picked != null) {
                          setState(() {
                            _fromDate = picked;
                            if (_toDate.isBefore(_fromDate)) {
                              _toDate = _fromDate;
                            }
                            _daysController.text = _toDate.difference(_fromDate).inDays.add(1).toString();
                          });
                        }
                      },
                    ),
                    // To Date Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('To: ${DateFormat('yyyy-MM-dd').format(_toDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _toDate,
                          firstDate: _fromDate,
                          lastDate: DateTime(2026, 12, 31),
                        );
                        if (picked != null) {
                          setState(() {
                            _toDate = picked;
                            _daysController.text = _toDate.difference(_fromDate).inDays.add(1).toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _daysController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Number of Days'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Reason for leave'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () async {
                    if (_reasonController.text.trim().isEmpty || _selectedLeaveType == null) return;
                    
                    final daysVal = double.tryParse(_daysController.text) ?? 1.0;

                    final ok = await ref.read(leaveProvider.notifier).applyLeave(
                          leaveTypeId: _selectedLeaveType!.id,
                          fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
                          toDate: DateFormat('yyyy-MM-dd').format(_toDate),
                          days: daysVal,
                          reason: _reasonController.text.trim(),
                        );

                    if (ok && mounted) {
                      Navigator.pop(ctx);
                      _reasonController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Leave application submitted successfully')),
                      );
                    }
                  },
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveProvider);
    final balances = leaveState.balances;
    final apps = leaveState.applications;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Leave Policy & History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ElevatedButton.icon(
                onPressed: () => _showApplyLeaveDialog(context, leaveState.leaveTypes),
                icon: const Icon(Icons.add),
                label: const Text('APPLY LEAVE'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balances cards
          if (leaveState.isLoading && balances.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: balances.map((b) {
                return Expanded(
                  child: Card(
                    margin: const EdgeInsets.only(right: 8),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.leaveTypeName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Text(
                            '${b.balance}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 4),
                          Text('Opening: ${b.opening} | Used: ${b.used}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const Text('Leave Application History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: leaveState.isLoading && apps.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : apps.isEmpty
                      ? const Center(child: Text('No leave applications submitted yet.'))
                      : ListView.separated(
                          itemCount: apps.length,
                          separatorBuilder: (context, idx) => const Divider(color: AppTheme.borderGrey, height: 1),
                          itemBuilder: (context, idx) {
                            final app = apps[idx];
                            Color statusColor = Colors.orange;
                            if (app.status == 'Approved') statusColor = AppTheme.accent;
                            if (app.status == 'Rejected') statusColor = Colors.red;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.1),
                                child: Icon(Icons.beach_access, color: statusColor),
                              ),
                              title: Text('${app.leaveTypeName} (${app.days} Days)'),
                              subtitle: Text('From ${app.fromDate} to ${app.toDate}\nReason: ${app.reason}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  app.status,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

extension IntExtension on int {
  int add(int other) => this + other;
}
