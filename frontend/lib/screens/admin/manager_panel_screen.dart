import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/employee.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class ManagerPanelScreen extends ConsumerStatefulWidget {
  const ManagerPanelScreen({super.key});

  @override
  ConsumerState<ManagerPanelScreen> createState() => _ManagerPanelScreenState();
}

class _ManagerPanelScreenState extends ConsumerState<ManagerPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Employee> _deptEmployees = [];
  List<Map<String, dynamic>> _allTickets = [];
  bool _isLoading = false;
  int? _expandedEmployeeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final managerEmp = authState.employee;
      final deptId = managerEmp?.departmentId ?? 1; // Default to 1 (Media)

      // Get all employees in manager's department (excluding the manager herself)
      final allEmp = await _apiService.searchEmployees(dept: deptId);
      final deptEmployees = allEmp.where((e) => e.id != managerEmp?.id).toList();

      // Get all tickets for this department
      final tickets = await _apiService.getTickets();
      final deptTickets = tickets.where((t) => t['category'] == 'Media').toList();

      setState(() {
        _deptEmployees = deptEmployees;
        _allTickets = deptTickets;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange;
      case 'On Hold':
        return Colors.blue;
      case 'Open':
        return Colors.green;
      case 'Not Attended':
        return Colors.grey;
      case 'Closed':
        return Colors.black54;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'In Progress':
        return 'Working On';
      case 'Open':
        return 'Ready / Available';
      case 'On Hold':
        return 'On Hold';
      case 'Not Attended':
        return 'Not Attended';
      case 'Closed':
        return 'Closed';
      default:
        return status;
    }
  }

  Widget _buildAssignmentsTab() {
    if (_allTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.confirmation_number_outlined, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('No tickets found for your department.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allTickets.length,
      itemBuilder: (context, index) {
        final tk = _allTickets[index];
        final currentAssigneeId = tk['assigned_to'] as int?;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.borderGrey),
          ),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(tk['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(tk['status']),
                        style: TextStyle(
                          color: _getStatusColor(tk['status']),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'TKT-${tk['id']}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tk['subject'] ?? 'No Subject',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                if (tk['description'] != null && tk['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    tk['description'],
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RAISED BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text('${tk['raised_by']} (${tk['designation']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ASSIGN TO EMPLOYEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: DropdownButton<int?>(
                            value: currentAssigneeId,
                            hint: const Text('Unassigned', style: TextStyle(fontSize: 12)),
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Unassigned'),
                              ),
                              ..._deptEmployees.map((emp) {
                                return DropdownMenuItem<int?>(
                                  value: emp.id,
                                  child: Text(emp.fullName),
                                );
                              }).toList()
                            ],
                            onChanged: (newEmpId) async {
                              setState(() => _isLoading = true);
                              await _apiService.assignTicket(tk['id'], newEmpId);
                              await _reloadData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(newEmpId == null
                                        ? 'Ticket unassigned successfully.'
                                        : 'Ticket successfully assigned to employee.'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkloadTab() {
    if (_deptEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('No team members found reporting to you.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deptEmployees.length,
      itemBuilder: (context, index) {
        final emp = _deptEmployees[index];
        final isExpanded = _expandedEmployeeId == emp.id;

        // Find tickets assigned to this employee
        final empTickets = _allTickets.where((t) => t['assigned_to'] == emp.id).toList();
        final activeTicket = empTickets.firstWhere(
          (t) => t['status'] == 'In Progress',
          orElse: () => {},
        );

        final hasActive = activeTicket.isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.borderGrey),
          ),
          elevation: 0,
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    '${emp.firstName[0]}${emp.lastName[0]}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  emp.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp.designationTitle ?? 'Media Staff', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('ACTIVE TICKET: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        if (hasActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activeTicket['subject'],
                              style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          const Text('None / Idle', style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${empTickets.length} Assigned', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${empTickets.where((t) => t['status'] == 'Closed').length} Closed',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.textMuted),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedEmployeeId = isExpanded ? null : emp.id;
                  });
                },
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                Container(
                  color: AppTheme.bgLight,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSIGNED TICKET QUEUE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 12),
                      if (empTickets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No tickets currently assigned.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: empTickets.length,
                          itemBuilder: (context, idx) {
                            final t = empTickets[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderGrey),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(t['status']).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(t['status']),
                                      style: TextStyle(
                                        color: _getStatusColor(t['status']),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['subject'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Priority: ${t['priority']} | Raised by: ${t['raised_by']}',
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final managerEmp = authState.employee;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manager Control Panel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Department: ${managerEmp?.departmentName ?? "Media"} | Manager: ${managerEmp?.fullName ?? "Jane Smith"}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('TICKET ASSIGNMENTS'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 18),
                      SizedBox(width: 8),
                      Text('TEAM WORKLOAD'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(),
                _buildWorkloadTab(),
              ],
            ),
    );
  }
}
