import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../models/leave.dart';
import '../../providers/employee_provider.dart';
import '../../providers/inbox_provider.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).fetchMetadata();
      ref.read(employeeProvider.notifier).fetchEmployees();
      ref.read(employeeProvider.notifier).fetchAuditLogs();
      ref.read(inboxProvider.notifier).fetchPendingApprovals();
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
        );
  }

  @override
  Widget build(BuildContext context) {
    final empState = ref.watch(employeeProvider);
    final inboxState = ref.watch(inboxProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Staff Management'),
                  Tab(text: 'Departments'),
                  Tab(text: 'Approvals'),
                  Tab(text: 'Audit Logs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStaffTab(empState),
          _buildDepartmentsTab(empState),
          _buildApprovalsTab(inboxState),
          _buildAuditLogsTab(empState),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAFF TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStaffTab(EmployeeState state) {
    return Column(
      children: [
        // Top Filter & Action Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search employee by name or code...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (v) => _triggerSearch(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedDeptId,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
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
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddStaffDialog(context, state),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Staff Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        // Staff Grid/List
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.employees.isEmpty
                  ? const Center(child: Text('No employee profiles found.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: state.employees.length,
                      itemBuilder: (context, index) {
                        final emp = state.employees[index];
                        return _buildStaffProfileCard(emp, state);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStaffProfileCard(Employee emp, EmployeeState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary.withOpacity(0.08),
              child: Text(
                emp.firstName.substring(0, 1),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
                  const SizedBox(height: 2),
                  Text(
                    '${emp.designationTitle ?? 'Staff'} • ${emp.employeeCode}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emp.departmentName ?? 'General',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditStaffDialog(context, emp, state),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit Details', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _showDocumentVault(context, emp),
                        icon: const Icon(Icons.folder_open_outlined, size: 14),
                        label: const Text('Documents', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.successGreen,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DEPARTMENTS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDepartmentsTab(EmployeeState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE DEPARTMENTS',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddDepartmentDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Create Department'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: state.departments.length,
              itemBuilder: (context, index) {
                final dept = state.departments[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.borderGrey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.corporate_fare_outlined, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dept['name'] ?? 'General',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text('Budget: Active', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // APPROVALS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildApprovalsTab(InboxState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaves = state.pendingLeaves;
    final regularizations = state.pendingRegularizations;

    if (leaves.isEmpty && regularizations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 48),
            const SizedBox(height: 16),
            Text(
              'No Pending Leave or Regularization Approvals',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (leaves.isNotEmpty) ...[
          const Text('PENDING LEAVE APPLICATIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...leaves.map((app) => _buildLeaveApprovalCard(app)),
          const SizedBox(height: 24),
        ],
        if (regularizations.isNotEmpty) ...[
          const Text('PENDING ATTENDANCE REGULARIZATIONS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...regularizations.map((reg) => _buildRegularizationApprovalCard(reg)),
        ],
      ],
    );
  }

  Widget _buildLeaveApprovalCard(LeaveApplication app) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderGrey),
      ),
      child: ListTile(
        title: Text('${app.employeeName} (${app.leaveTypeName})'),
        subtitle: Text('Dates: ${app.fromDate} to ${app.toDate} (${app.days} days)\nReason: ${app.reason}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorRed),
              onPressed: () => _handleLeaveAction(app.id, 'Rejected'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
              onPressed: () => _handleLeaveAction(app.id, 'Approved'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularizationApprovalCard(RegularizationRequest reg) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderGrey),
      ),
      child: ListTile(
        title: Text('${reg.employeeName} (Date: ${reg.date})'),
        subtitle: Text('Expected: ${reg.requestedIn} - ${reg.requestedOut}\nReason: ${reg.reason}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorRed),
              onPressed: () => _handleRegularizationAction(reg.id, 'Rejected'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
              onPressed: () => _handleRegularizationAction(reg.id, 'Approved'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLeaveAction(int id, String status) async {
    final ok = await ref.read(inboxProvider.notifier).processLeave(id, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave successfully $status')));
      ref.read(employeeProvider.notifier).fetchAuditLogs();
    }
  }

  void _handleRegularizationAction(int id, String status) async {
    final ok = await ref.read(inboxProvider.notifier).processRegularization(id, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Regularization successfully $status')));
      ref.read(employeeProvider.notifier).fetchAuditLogs();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AUDIT LOGS TAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAuditLogsTab(EmployeeState state) {
    final logs = state.auditLogs;
    if (logs.isEmpty) {
      return const Center(child: Text('No administrative modifications recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderGrey),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppTheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log['action'] ?? 'Modification', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(log['details'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(log['timestamp'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODALS & DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  void _showAddStaffDialog(BuildContext context, EmployeeState state) {
    _showAnimatedStaffForm(context: context, state: state);
  }

  void _showEditStaffDialog(BuildContext context, Employee emp, EmployeeState state) {
    _showAnimatedStaffForm(context: context, state: state, existingEmployee: emp);
  }

  void _showAnimatedStaffForm({
    required BuildContext context,
    required EmployeeState state,
    Employee? existingEmployee,
  }) {
    final formKey = GlobalKey<FormState>();
    final isEdit = existingEmployee != null;

    final Map<String, dynamic> data = {
      'first_name': existingEmployee?.firstName ?? '',
      'last_name': existingEmployee?.lastName ?? '',
      'dob': existingEmployee?.dob ?? '1995-01-01',
      'gender': existingEmployee?.gender ?? 'Male',
      'personal_email': existingEmployee?.personalEmail ?? '',
      'phone': existingEmployee?.phone ?? '',
      'department_id': existingEmployee?.departmentId ?? (state.departments.isNotEmpty ? state.departments.first['id'] : 1),
      'designation_id': existingEmployee?.designationId ?? (state.designations.isNotEmpty ? state.designations.first['id'] : 1),
      'date_of_joining': existingEmployee?.dateOfJoining ?? '2026-07-18',
      'employment_type': existingEmployee?.employmentType ?? 'Full-Time',
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.9 + 0.1 * curve,
          child: Opacity(
            opacity: anim1.value,
            child: Align(
              alignment: Alignment.center,
              child: Dialog(
                elevation: 24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: MediaQuery.of(ctx).size.width > 680 ? 640 : MediaQuery.of(ctx).size.width * 0.92,
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEdit ? Icons.edit_document : Icons.person_add_alt_1,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isEdit ? 'Edit Staff Profile' : 'Add New Staff Profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Form Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: formKey,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final useTwoCols = constraints.maxWidth > 500;
                                return Column(
                                  children: [
                                    _buildFormRow(
                                      useTwoCols,
                                      _buildTextField(
                                        label: 'First Name',
                                        icon: Icons.person_outline,
                                        initialValue: data['first_name'],
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        onSaved: (v) => data['first_name'] = v,
                                      ),
                                      _buildTextField(
                                        label: 'Last Name',
                                        icon: Icons.person_outline,
                                        initialValue: data['last_name'],
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        onSaved: (v) => data['last_name'] = v,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFormRow(
                                      useTwoCols,
                                      _buildTextField(
                                        label: 'Personal Email',
                                        icon: Icons.mail_outlined,
                                        initialValue: data['personal_email'],
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                        onSaved: (v) => data['personal_email'] = v,
                                      ),
                                      _buildTextField(
                                        label: 'Phone Number',
                                        icon: Icons.phone_outlined,
                                        initialValue: data['phone'],
                                        onSaved: (v) => data['phone'] = v,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFormRow(
                                      useTwoCols,
                                      _buildDropdownField<String>(
                                        label: 'Gender',
                                        icon: Icons.wc_outlined,
                                        value: data['gender'],
                                        items: const ['Male', 'Female', 'Other'],
                                        onChanged: (v) => data['gender'] = v,
                                      ),
                                      _buildDropdownField<String>(
                                        label: 'Employment Type',
                                        icon: Icons.work_outline,
                                        value: data['employment_type'],
                                        items: const ['Full-Time', 'Part-Time', 'Contract'],
                                        onChanged: (v) => data['employment_type'] = v,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFormRow(
                                      useTwoCols,
                                      _buildDropdownFieldMap<int>(
                                        label: 'Department',
                                        icon: Icons.corporate_fare_outlined,
                                        value: data['department_id'],
                                        items: state.departments.map((d) => MapEntry(d['id'] as int, d['name'] as String)).toList(),
                                        onChanged: (v) => data['department_id'] = v,
                                      ),
                                      _buildDropdownFieldMap<int>(
                                        label: 'Designation',
                                        icon: Icons.badge_outlined,
                                        value: data['designation_id'],
                                        items: state.designations.map((d) => MapEntry(d['id'] as int, d['title'] as String)).toList(),
                                        onChanged: (v) => data['designation_id'] = v,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // Actions Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: AppTheme.bgLight,
                          border: Border(top: BorderSide(color: AppTheme.borderGrey)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.borderGrey),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  final ok = isEdit
                                      ? await ref.read(employeeProvider.notifier).editEmployee(existingEmployee!.id, data)
                                      : await ref.read(employeeProvider.notifier).addEmployee(data);
                                  if (ok && mounted) {
                                    Navigator.pop(ctx);
                                    ref.read(employeeProvider.notifier).fetchAuditLogs();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit ? 'Staff profile successfully updated.' : 'Staff profile successfully created.',
                                        ),
                                        backgroundColor: AppTheme.successGreen,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                isEdit ? 'UPDATE PROFILE' : 'SAVE PROFILE',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormRow(bool useTwoCols, Widget child1, Widget child2) {
    if (useTwoCols) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 16),
          Expanded(child: child2),
        ],
      );
    } else {
      return Column(
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? initialValue,
    String? Function(String?)? validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      validator: validator,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.6), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.6), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownFieldMap<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<MapEntry<T, String>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items.map((entry) {
        return DropdownMenuItem<T>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.6), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _showAddDepartmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> data = {'name': ''};

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Department'),
          content: Form(
            key: formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Department Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => data['name'] = v,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final ok = await ref.read(employeeProvider.notifier).addDepartment(data);
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    ref.read(employeeProvider.notifier).fetchAuditLogs();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Department "${data['name']}" created successfully.')));
                  }
                }
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentVault(BuildContext context, Employee emp) {
    ref.read(employeeProvider.notifier).fetchEmployeeDocuments(emp.id);

    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, refWatch, child) {
            final empState = refWatch.watch(employeeProvider);
            final docs = empState.employeeDocuments;

            return AlertDialog(
              title: Text('Document Vault: ${emp.fullName}'),
              content: SizedBox(
                width: 500,
                height: 350,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Upload New Document:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ElevatedButton.icon(
                          onPressed: () => _showUploadDocumentForm(context, emp.id),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: const Text('Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: empState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : docs.isEmpty
                              ? const Center(child: Text('No documents uploaded yet.'))
                              : ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, idx) {
                                    final doc = docs[idx];
                                    return Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: AppTheme.borderGrey),
                                      ),
                                      child: ListTile(
                                        leading: const Icon(Icons.description, color: AppTheme.primary),
                                        title: Text(doc['fileName'] ?? 'Document.pdf', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        subtitle: Text('${doc['fileType']} • ${doc['size']} • ${doc['uploadDate']}', style: const TextStyle(fontSize: 11)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                                          onPressed: () async {
                                            final ok = await ref.read(employeeProvider.notifier).deleteDocument(emp.id, doc['id']);
                                            if (ok && mounted) {
                                              ref.read(employeeProvider.notifier).fetchAuditLogs();
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
              ],
            );
          },
        );
      },
    );
  }

  void _showUploadDocumentForm(BuildContext context, int employeeId) {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> docData = {
      'fileName': '',
      'fileType': 'ID Proof',
      'size': '1.5 MB',
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Upload Document Info'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'File Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => docData['fileName'] = v,
                ),
                DropdownButtonFormField<String>(
                  value: docData['fileType'],
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: const [
                    DropdownMenuItem(value: 'ID Proof', child: Text('ID Proof')),
                    DropdownMenuItem(value: 'Offer Letter', child: Text('Offer Letter')),
                    DropdownMenuItem(value: 'Degree Certificate', child: Text('Degree Certificate')),
                    DropdownMenuItem(value: 'Experience Certificate', child: Text('Experience Certificate')),
                  ],
                  onChanged: (v) => docData['fileType'] = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final ok = await ref.read(employeeProvider.notifier).uploadDocument(employeeId, docData);
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    ref.read(employeeProvider.notifier).fetchAuditLogs();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully.')));
                  }
                }
              },
              child: const Text('UPLOAD'),
            ),
          ],
        );
      },
    );
  }
}
