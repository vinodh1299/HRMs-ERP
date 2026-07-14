import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'attendance_tab.dart';
import 'leave_tab.dart';
import '../stubs/empty_state_screen.dart';

class MeDashboardScreen extends StatefulWidget {
  const MeDashboardScreen({super.key});

  @override
  State<MeDashboardScreen> createState() => _MeDashboardScreenState();
}

class _MeDashboardScreenState extends State<MeDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Tab(text: 'Attendance'),
              Tab(text: 'Leave'),
              Tab(text: 'Performance'),
              Tab(text: 'Expenses & Travel'),
              Tab(text: 'Helpdesk'),
              Tab(text: 'Apps'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AttendanceTab(),
          LeaveTab(),
          EmptyStateScreen(moduleName: 'Me -> Performance'),
          EmptyStateScreen(moduleName: 'Me -> Expenses & Travel'),
          EmptyStateScreen(moduleName: 'Me -> Helpdesk'),
          EmptyStateScreen(moduleName: 'Me -> Apps'),
        ],
      ),
    );
  }
}
