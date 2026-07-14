import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';

class OrgScreen extends ConsumerStatefulWidget {
  const OrgScreen({super.key});

  @override
  ConsumerState<OrgScreen> createState() => _OrgScreenState();
}

class _OrgScreenState extends ConsumerState<OrgScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDeptId;
  int? _selectedLocId;
  int? _expandedEmployeeId; // Tapping a card in Org Tree expands subordinates

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).fetchMetadata();
      ref.read(employeeProvider.notifier).fetchEmployees();
      ref.read(employeeProvider.notifier).fetchOrgTree();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(employeeProvider.notifier).fetchEmployees(
          search: _searchController.text.trim(),
          dept: _selectedDeptId,
          loc: _selectedLocId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final empState = ref.watch(employeeProvider);

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
              Tab(text: 'Directory'),
              Tab(text: 'Organization Tree'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectoryTab(context, empState),
          _buildOrgTreeTab(context, empState),
        ],
      ),
    );
  }

  Widget _buildDirectoryTab(BuildContext context, EmployeeState state) {
    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search employee...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (v) => _triggerSearch(),
                ),
              ),
              const SizedBox(width: 12),
              // Department Filter
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedDeptId,
                  decoration: const InputDecoration(labelText: 'Department', contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All')),
                    ...state.departments.map((d) {
                      return DropdownMenuItem<int?>(value: d['id'], child: Text(d['name']));
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedDeptId = val);
                    _triggerSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Location Filter
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedLocId,
                  decoration: const InputDecoration(labelText: 'Location', contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All')),
                    ...state.locations.map((l) {
                      return DropdownMenuItem<int?>(value: l['id'], child: Text(l['name']));
                    }),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedLocId = val);
                    _triggerSearch();
                  },
                ),
              ),
            ],
          ),
        ),
        // Employee List
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.employees.isEmpty
                  ? const Center(child: Text('No employees found matching filter.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 1024
                            ? 3
                            : MediaQuery.of(context).size.width > 600
                                ? 2
                                : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: state.employees.length,
                      itemBuilder: (context, index) {
                        final emp = state.employees[index];
                        return _buildEmployeeCard(context, emp);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee emp) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEmployeeDetailsDialog(context, emp),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.08),
                child: Text(emp.firstName.substring(0, 1), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emp.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emp.designationTitle ?? 'Staff',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emp.departmentName ?? 'General',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(emp.locationName ?? 'Chennai', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeeDetailsDialog(BuildContext context, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(emp.fullName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Employee Code', emp.employeeCode),
              _buildDetailItem('Email', emp.personalEmail),
              _buildDetailItem('Phone', emp.phone),
              _buildDetailItem('Date of Joining', emp.dateOfJoining),
              _buildDetailItem('Employment Type', emp.employmentType),
              _buildDetailItem('Department', emp.departmentName ?? '--'),
              _buildDetailItem('Designation', emp.designationTitle ?? '--'),
              _buildDetailItem('Reporting Manager', emp.managerName ?? 'None (Top of Hierarchy)'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgTreeTab(BuildContext context, EmployeeState state) {
    final list = state.orgTreeData;
    if (list.isEmpty) {
      return const Center(child: Text('No hierarchy tree data loaded.'));
    }

    // Identify roots (reporting_manager_id == null or not matching any employee ID)
    final rootEmployees = list.where((x) {
      final mgrId = x['reporting_manager_id'];
      if (mgrId == null) return true;
      return !list.any((y) => y['id'] == mgrId);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Visual Reporting Line Hierarchy',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Click on a manager card to view their reporting subordinates in the organization tree.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        ...rootEmployees.map((root) => _buildTreeNode(root, list, 0)),
      ],
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> emp, List<Map<String, dynamic>> allEmployees, int depth) {
    final int empId = emp['id'];
    final subordinates = allEmployees.where((x) => x['reporting_manager_id'] == empId).toList();
    final bool isExpanded = _expandedEmployeeId == empId;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (depth > 0)
                const Icon(Icons.subdirectory_arrow_right, color: AppTheme.borderGrey, size: 16),
              const SizedBox(width: 4),
              // Employee Card in tree
              Expanded(
                child: Card(
                  color: isExpanded ? AppTheme.primary.withOpacity(0.02) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isExpanded ? AppTheme.primary : AppTheme.borderGrey,
                      width: isExpanded ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    onTap: subordinates.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _expandedEmployeeId = isExpanded ? null : empId;
                            });
                          },
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        (emp['first_name'] ?? 'E').substring(0, 1),
                        style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      '${emp['first_name']} ${emp['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${emp['designation_title'] ?? 'Staff'} | ${emp['department_name'] ?? 'Engineering'}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: subordinates.isEmpty
                        ? null
                        : Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Recurse for subordinates if expanded
          if (isExpanded && subordinates.isNotEmpty) ...[
            ...subordinates.map((sub) => _buildTreeNode(sub, allEmployees, depth + 1)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
