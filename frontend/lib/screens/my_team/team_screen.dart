import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';

class MyTeamScreen extends ConsumerStatefulWidget {
  const MyTeamScreen({super.key});

  @override
  ConsumerState<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends ConsumerState<MyTeamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeProvider.notifier).fetchEmployees();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Tab(text: 'Summary'),
              Tab(text: 'Peers'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(context, empState.employees),
          _buildPeersTab(context, empState.employees),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, List<Employee> employees) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryStatCard('Who Is Off Today', '1', Icons.no_accounts_outlined, Colors.red),
              _buildSummaryStatCard('On Time Today', '2', Icons.task_alt_outlined, AppTheme.accent),
              _buildSummaryStatCard('Late Arrivals', '0', Icons.alarm_off, Colors.orange),
              _buildSummaryStatCard('Working Remotely', '0', Icons.home_work_outlined, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          // Off details list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On Leave Today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Text('SR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    title: const Text('Suresh Raina'),
                    subtitle: const Text('Sick Leave | Reports to Vinodh Raj'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Team Calendar mockup card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team Calendar (July 2026)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderGrey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Interactive Team Monthly Attendance Grid (Phase 2)', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeersTab(BuildContext context, List<Employee> employees) {
    if (employees.isEmpty) {
      return const Center(child: Text('No peer records available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.08),
              child: Text(emp.firstName.substring(0, 1), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${emp.designationTitle ?? 'Staff'} | ${emp.departmentName ?? 'General'}\nEmail: ${emp.personalEmail}'),
            trailing: Chip(
              label: Text(
                emp.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: emp.status == 'Active' ? AppTheme.accent : Colors.red,
                ),
              ),
              backgroundColor: emp.status == 'Active' ? AppTheme.accent.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatCard(String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ],
        ),
      ),
    );
  }
}
