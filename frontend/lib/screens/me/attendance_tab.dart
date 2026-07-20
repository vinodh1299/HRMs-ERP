import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/attendance.dart';
import '../../providers/attendance_provider.dart';
import '../../services/ai_service.dart';

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key});

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  final _reasonController = TextEditingController();
  final _checkInController = TextEditingController(text: '09:00:00');
  final _checkOutController = TextEditingController(text: '18:00:00');
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceProvider.notifier).fetchLogs();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  void _showRegularizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Apply Attendance Correction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2026, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _checkInController,
                      decoration: const InputDecoration(labelText: 'Requested Check-In (HH:MM:ss)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _checkOutController,
                      decoration: const InputDecoration(labelText: 'Requested Check-Out (HH:MM:ss)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason for regularization',
                        suffixIcon: TextButton.icon(
                          onPressed: () async {
                            final txt = _reasonController.text.trim();
                            if (txt.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please write a brief reason first (e.g. traffic delay).')),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rewriting with Gemini AI...')),
                            );
                            final justification = await GeminiService.generateJustification(txt);
                            _reasonController.text = justification;
                          },
                          icon: const Icon(Icons.psychology_outlined, size: 16),
                          label: const Text('AI Justify', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () async {
                    if (_reasonController.text.trim().isEmpty) return;
                    
                    final ok = await ref.read(attendanceProvider.notifier).regularize(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          _reasonController.text.trim(),
                          _checkInController.text,
                          _checkOutController.text,
                        );

                    if (ok && mounted) {
                      Navigator.pop(ctx);
                      _reasonController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Regularization request submitted successfully')),
                      );
                    }
                  },
                  child: const Text('APPLY'),
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
    final attState = ref.watch(attendanceProvider);
    final logs = attState.logs;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with apply buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ElevatedButton.icon(
                onPressed: () => _showRegularizationDialog(context),
                icon: const Icon(Icons.edit_calendar),
                label: const Text('REQUEST CORRECTION'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timings widgets summary cards
          MediaQuery.of(context).size.width < 600
              ? Column(
                  children: [
                    _buildSummaryCard('Avg Hours/Day', '8h 15m', Icons.timer_outlined, Colors.blue),
                    const SizedBox(height: 8),
                    _buildSummaryCard('On-Time Arrival %', '92%', Icons.check_circle_outline, AppTheme.accent),
                    const SizedBox(height: 8),
                    _buildSummaryCard('Regularization Pending', '${attState.regularizations.where((r) => r.status == 'Pending').length}', Icons.pending_actions, Colors.orange),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Avg Hours/Day', '8h 15m', Icons.timer_outlined, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('On-Time Arrival %', '92%', Icons.check_circle_outline, AppTheme.accent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('Regularization Pending', '${attState.regularizations.where((r) => r.status == 'Pending').length}', Icons.pending_actions, Colors.orange)),
                  ],
                ),
          const SizedBox(height: 20),
          // Logs Table
          Expanded(
            child: Card(
              child: attState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : logs.isEmpty
                      ? const Center(child: Text('No attendance logs registered for this month.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Check-In', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Check-Out', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Hours', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: logs.map((log) {
                                // Calculate total hours
                                String hrs = '--';
                                if (log.checkIn != null && log.checkOut != null) {
                                  try {
                                    final inTime = DateFormat('HH:mm:ss').parse(log.checkIn!);
                                    final outTime = DateFormat('HH:mm:ss').parse(log.checkOut!);
                                    final diff = outTime.difference(inTime);
                                    hrs = '${diff.inHours}h ${diff.inMinutes % 60}m';
                                  } catch (_) {}
                                }
                                return DataRow(
                                  cells: [
                                    DataCell(Text(log.date)),
                                    DataCell(Text(log.checkIn ?? '--')),
                                    DataCell(Text(log.checkOut ?? '--')),
                                    DataCell(Text(hrs)),
                                    DataCell(Text(log.source)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
