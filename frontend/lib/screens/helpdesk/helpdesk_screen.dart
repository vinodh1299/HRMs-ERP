import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class HelpdeskScreen extends ConsumerStatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  ConsumerState<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends ConsumerState<HelpdeskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;

  // Selected ticket for detailed split view (null means show list/summary tabs)
  Map<String, dynamic>? _selectedTicket;

  // Controllers
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _newTicketTitleController = TextEditingController();
  final TextEditingController _newTicketDescController = TextEditingController();

  // Raise ticket panel state
  bool _showRaisePanel = false;
  String _newTicketCategory = 'Select a category';

  // Selected filters for Tickets List tab
  String _activeTabFilter = 'Open Tickets';
  String _selectedPriority = 'Priority';
  String _selectedCategory = 'Category';
  String _selectedStatus = 'Ticket Status';
  String _selectedAssignee = 'Assigned To';
  String _selectedEscalation = 'Escalation Reason';
  String _searchQuery = '';

  late List<Map<String, dynamic>> _mockTickets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Set up high-fidelity mock data matching screenshots
    _mockTickets = [
      {
        'id': 9280,
        'subject': 'Request to update service schedules',
        'category': 'General Support',
        'sub_category': 'Operations',
        'raised_by': 'John Doe',
        'designation': 'Operations Coordinator',
        'phone': '9876543210',
        'location': 'Headquarters',
        'created_at': '25 Jun 2026',
        'priority': 'MEDIUM',
        'escalation_reason': 'Not Escalated',
        'last_responded_by': 'John Doe',
        'last_response_time': '3 hours ago',
        'assigned_to_name': 'Support Agent',
        'status': 'In Progress',
        'age': '4 days 10 hours 7 minutes',
        'overdue_days': 12,
        'followers': ['Jane Smith', 'Alex Rivera'],
        'messages': [
          {
            'sender': 'John Doe',
            'designation': 'Operations Coordinator',
            'content': 'Please add the updated service schedule details to the main organizational portal.',
            'time': '25 Jun 2026 at 11:30 am',
            'is_admin': false,
          },
          {
            'sender': 'Support Agent',
            'designation': 'Support Lead',
            'content': 'We have received your request. I am working on updating the resource files.',
            'time': '26 Jun 2026 at 09:15 am',
            'is_admin': true,
          }
        ]
      },
      {
        'id': 9270,
        'subject': 'Main Website Update',
        'category': 'Technical Queries',
        'sub_category': 'General Maintenance',
        'raised_by': 'Emily Chen',
        'designation': 'Administrator',
        'phone': '9876543211',
        'location': 'Regional Office',
        'created_at': '23 Jun 2026',
        'priority': 'MEDIUM',
        'escalation_reason': 'Not Escalated',
        'last_responded_by': 'Emily Chen',
        'last_response_time': '6 days ago',
        'assigned_to_name': 'Support Agent',
        'status': 'In Progress',
        'age': '4 days 21 hours 47 minutes',
        'overdue_days': 12,
        'followers': ['Jane Smith', 'Alex Rivera'],
        'messages': [
          {
            'sender': 'Emily Chen',
            'designation': 'Administrator',
            'content': 'These are the updated media layouts to be uploaded to the corporate landing page. Kindly update them at your earliest convenience.\n\nThank you.',
            'time': '03 Jul 2026 at 02:35 pm',
            'is_admin': false,
          },
          {
            'sender': 'Support Agent',
            'designation': 'Support Lead',
            'content': 'Dear Manager,\n\nI have made all the changes and updated the landing pages with the new assets as requested. Please review the changes and let me know if any further changes are needed.\n\nThank You.',
            'time': '04 Jul 2026 at 04:02 pm',
            'is_admin': true,
          },
          {
            'sender': 'Emily Chen',
            'designation': 'Administrator',
            'content': 'Sure, thank you.',
            'time': '07 Jul 2026 at 09:48 am',
            'is_admin': false,
          }
        ]
      }
    ];

    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replyController.dispose();
    _noteController.dispose();
    _newTicketTitleController.dispose();
    _newTicketDescController.dispose();
    super.dispose();
  }

  void _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final dbTickets = await _apiService.getTickets();
      if (mounted) {
        setState(() {
          _tickets = dbTickets.isNotEmpty ? dbTickets : _mockTickets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tickets = _mockTickets;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    // If a ticket is selected, display the detailed split ticket view screen instead of the summary/list tabs!
    if (_selectedTicket != null) {
      return _buildTicketDetailsView(context, _selectedTicket!, isDesktop);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.08), width: 1.5)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            tabs: const [
              Tab(text: 'SUMMARY'),
              Tab(text: 'TICKETS'),
              Tab(text: 'REPORTS'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(isDesktop),
                _buildTicketsTab(isDesktop),
                _buildReportsTab(),
              ],
            ),
    );
  }

  // --- 1. SUMMARY TAB ---
  Widget _buildSummaryTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Helpdesk dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 20),
          // Metrics Cards Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _buildMetricCard('Open Tickets', '${_tickets.length}', Icons.confirmation_number_outlined, AppTheme.accent, null),
              _buildMetricCard('Incoming today', '0', Icons.arrow_downward, AppTheme.primary, 'FROM YESTERDAY 0'),
              _buildMetricCard('Closed today', '0', Icons.done_all, AppTheme.secondary, 'FROM YESTERDAY 0'),
              _buildMetricCard('On Hold', '0', Icons.pause_circle_outline, Colors.orange, null),
            ],
          ),
          const SizedBox(height: 28),
          // Ticket Analysis Panel
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.primary.withOpacity(0.08), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ticket Analysis',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Row(
                        children: [
                          _buildMockDropdown('Media (Development)'),
                          const SizedBox(width: 10),
                          _buildMockDropdown('Last 7 days'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAnalysisColumn('Incoming', '${_tickets.length}'),
                      _buildAnalysisDivider(),
                      _buildAnalysisColumn('Closed', '0'),
                      _buildAnalysisDivider(),
                      _buildAnalysisColumn('First Response Time', 'N/A'),
                      _buildAnalysisDivider(),
                      _buildAnalysisColumn('Resolution Time', 'N/A'),
                      _buildAnalysisDivider(),
                      _buildAnalysisColumn('CSAT Score', '0'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _buildEmptyChartCard('Total Open v/s Closed Tickets')),
              const SizedBox(width: 16),
              Expanded(child: _buildEmptyChartCard('Top Category-wise Open Tickets')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color accentColor, String? subText) {
    return Container(
      decoration: AppTheme.glassDecoration(color: Colors.white, opacity: 0.90, borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      val,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    if (subText != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        subText,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAnalysisDivider() {
    return Container(
      height: 40,
      width: 1.5,
      color: AppTheme.borderGrey,
    );
  }

  Widget _buildMockDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard(String title) {
    return Container(
      height: 280,
      decoration: AppTheme.glassDecoration(color: Colors.white, opacity: 0.90, borderRadius: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_chart_outlined, size: 40, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'No data to display',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. TICKETS TAB LIST VIEW ---
  Widget _buildTicketsTab(bool isDesktop) {
    final filtered = _tickets.where((tk) {
      if (_activeTabFilter == 'Open Tickets' && tk['status'] != 'In Progress' && tk['status'] != 'Open') {
        return false;
      }
      if (_activeTabFilter == 'Closed Tickets' && tk['status'] != 'Closed') {
        return false;
      }
      if (_selectedPriority != 'Priority' && tk['priority'] != _selectedPriority.toUpperCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !tk['subject'].toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final ticketsBody = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildFilterPill('Open Tickets'),
              _buildFilterPill('Closed Tickets'),
              _buildFilterPill('Raised by me'),
              _buildFilterPill('Following'),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable Filter Tags Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateRangeFilter('13 Jun 2026 - 13 Jul 2026'),
                const SizedBox(width: 8),
                _buildDropdownFilter('Category', ['Category', 'IT Support', 'Payroll', 'Media (Development)'], (val) {
                  setState(() => _selectedCategory = val);
                }),
                const SizedBox(width: 8),
                _buildDropdownFilter('Priority', ['Priority', 'Low', 'Medium', 'High', 'Critical'], (val) {
                  setState(() => _selectedPriority = val);
                }),
                const SizedBox(width: 8),
                _buildDropdownFilter('Ticket Status', ['Ticket Status', 'Open', 'In Progress', 'On Hold', 'Closed'], (val) {
                  setState(() => _selectedStatus = val);
                }),
                const SizedBox(width: 8),
                _buildDropdownFilter('Assigned To', ['Assigned To', 'Support Agent', 'Administrator'], (val) {
                  setState(() => _selectedAssignee = val);
                }),
                const SizedBox(width: 8),
                _buildDropdownFilter('Escalation Reason', ['Escalation Reason', 'Not Escalated'], (val) {
                  setState(() => _selectedEscalation = val);
                }),
                const SizedBox(width: 8),
                Container(
                  width: 180,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.textMuted),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildActionButton(Icons.check_circle_outline, 'Close Tickets'),
                  const SizedBox(width: 10),
                  _buildActionButton(Icons.folder_open_outlined, 'Change Category'),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Total: ${filtered.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  // Show + New Ticket button only on "Raised by me" tab
                  if (_activeTabFilter == 'Raised by me') ...[  
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showRaisePanel = true),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // "Raised by me" section headers
          if (_activeTabFilter == 'Raised by me') ...[  
            const Text('Open Tickets', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(
              filtered.where((t) => t['status'] == 'Open' || t['status'] == 'In Progress').isEmpty
                  ? 'There are no open tickets yet to be addressed.'
                  : '',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
          ],
          // Interactive Table Panel
          Expanded(
            child: Container(
              decoration: AppTheme.glassDecoration(color: Colors.white, opacity: 0.90, borderRadius: 16),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowColor: MaterialStateProperty.all(AppTheme.bgLight),
                    dataRowHeight: 52,
                    columns: const [
                      DataColumn(label: SizedBox(width: 20)),
                      DataColumn(label: Text('TICKET NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('TICKET RAISED BY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('CREATED ON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('PRIORITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('ESCALATION REASON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('LAST RESPONDED BY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('ASSIGNED TO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('TICKET STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('TICKET AGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                      DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
                    ],
                    rows: List.generate(filtered.length, (idx) {
                      final tk = filtered[idx];
                      return DataRow(
                        cells: [
                          DataCell(Checkbox(value: false, onChanged: (_) {}, activeColor: AppTheme.primary)),
                          // Click to show Detail Split screen view!
                          DataCell(
                            InkWell(
                              onTap: () => setState(() => _selectedTicket = tk),
                              child: Text(
                                '#${tk['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 13),
                              ),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: () => setState(() => _selectedTicket = tk),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tk['subject'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tk['category']} | ${tk['sub_category'] ?? "General"}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tk['raised_by'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(tk['designation'] ?? 'Staff', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                          DataCell(Text(tk['created_at'], style: const TextStyle(fontSize: 12.5))),
                          DataCell(_buildPriorityChip(tk['priority'])),
                          DataCell(Text(tk['escalation_reason'] ?? 'Not Escalated', style: const TextStyle(fontSize: 12.5))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tk['last_responded_by'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(tk['last_response_time'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                          DataCell(Text(tk['assigned_to_name'] ?? 'Unassigned', style: const TextStyle(fontSize: 12.5))),
                          DataCell(_buildStatusChip(tk['status'])),
                          DataCell(Text(tk['age'] ?? '', style: const TextStyle(fontSize: 12))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.more_horiz, color: AppTheme.textMuted),
                              onPressed: () => setState(() => _selectedTicket = tk),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        ticketsBody,
        // Raise Ticket Side Panel overlay
        if (_showRaisePanel) ...[
          // Scrim backdrop
          GestureDetector(
            onTap: () => setState(() => _showRaisePanel = false),
            child: Container(
              color: Colors.black.withOpacity(0.35),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Slide-in panel from right
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 460,
            child: _buildRaiseTicketPanel(),
          ),
        ],
      ],
    );
  }

  // --- RAISE TICKET PANEL ---
  Widget _buildRaiseTicketPanel() {
    final categories = [
      'Select a category',
      'IT Support',
      'Payroll',
      'HR Policies',
      'Facilities',
      'Finance',
      'Media (Development)',
      'Other',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(-6, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raise a ticket',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can share any concern or seek help from your organisation.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                  onPressed: () => setState(() {
                    _showRaisePanel = false;
                    _newTicketTitleController.clear();
                    _newTicketDescController.clear();
                    _newTicketCategory = 'Select a category';
                  }),
                ),
              ],
            ),
          ),

          // Scrollable form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category dropdown
                  const Text(
                    'Need help regarding',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _newTicketCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textMuted),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontFamily: 'Inter'),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _newTicketCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title field
                  const Text(
                    'Title',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newTicketTitleController,
                    decoration: InputDecoration(
                      hintText: 'Enter ticket title',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.borderGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Description field with mock toolbar
                  const Text(
                    'Please share the assistance required',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Column(
                      children: [
                        // Formatting toolbar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            children: [
                              _toolbarBtn(Icons.format_bold, 'Bold'),
                              _toolbarBtn(Icons.format_italic, 'Italic'),
                              _toolbarBtn(Icons.format_underline, 'Underline'),
                              const SizedBox(width: 4),
                              Container(width: 1, height: 16, color: AppTheme.borderGrey),
                              const SizedBox(width: 4),
                              _toolbarBtn(Icons.format_list_bulleted, 'Bullets'),
                              _toolbarBtn(Icons.format_list_numbered, 'Numbered'),
                              const SizedBox(width: 4),
                              Container(width: 1, height: 16, color: AppTheme.borderGrey),
                              const SizedBox(width: 4),
                              _toolbarBtn(Icons.link, 'Link'),
                              _toolbarBtn(Icons.insert_emoticon_outlined, 'Emoji'),
                            ],
                          ),
                        ),
                        // Text area
                        TextField(
                          controller: _newTicketDescController,
                          maxLines: 7,
                          decoration: const InputDecoration(
                            hintText: 'Describe your issue…',
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Attach File
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderGrey, style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Attach File',
                            style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'Supported: PDF, DOC, PNG, JPG up to 10MB',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() {
                    _showRaisePanel = false;
                    _newTicketTitleController.clear();
                    _newTicketDescController.clear();
                    _newTicketCategory = 'Select a category';
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    side: BorderSide(color: AppTheme.borderGrey),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Submit ticket (stub)
                    final title = _newTicketTitleController.text.trim();
                    if (title.isEmpty || _newTicketCategory == 'Select a category') return;
                    // Add a mock ticket to the list for demo
                    setState(() {
                      _tickets.insert(0, {
                        'id': 'TKT-${(_tickets.length + 1).toString().padLeft(3, "0")}',
                        'subject': title,
                        'category': _newTicketCategory,
                        'sub_category': 'General',
                        'raised_by': 'Me',
                        'designation': 'Employee',
                        'created_at': 'Today',
                        'priority': 'MEDIUM',
                        'status': 'Open',
                        'escalation_reason': 'Not Escalated',
                        'assigned_to': 'Unassigned',
                        'description': _newTicketDescController.text.trim(),
                        'comments': [],
                      });
                      _showRaisePanel = false;
                      _newTicketTitleController.clear();
                      _newTicketDescController.clear();
                      _newTicketCategory = 'Select a category';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Raise Ticket', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarBtn(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String tabName) {
    final isSelected = _activeTabFilter == tabName;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ChoiceChip(
        label: Text(tabName),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _activeTabFilter = tabName);
        },
        selectedColor: AppTheme.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderGrey),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildDateRangeFilter(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String currentLabel, List<String> options, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(currentLabel) ? currentLabel : options.first,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          items: options.map((opt) {
            return DropdownMenuItem<String>(value: opt, child: Text(opt));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String prio) {
    Color bg = Colors.grey.withOpacity(0.1);
    Color txt = AppTheme.textDark;

    if (prio == 'HIGH' || prio == 'CRITICAL') {
      bg = AppTheme.accent.withOpacity(0.08);
      txt = AppTheme.accent;
    } else if (prio == 'MEDIUM') {
      bg = Colors.orange.withOpacity(0.08);
      txt = Colors.orange.shade800;
    } else if (prio == 'LOW') {
      bg = AppTheme.secondary.withOpacity(0.08);
      txt = AppTheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        prio,
        style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey.withOpacity(0.1);
    Color txt = AppTheme.textDark;

    if (status == 'Open') {
      bg = AppTheme.accent.withOpacity(0.08);
      txt = AppTheme.accent;
    } else if (status == 'In Progress') {
      bg = AppTheme.secondary.withOpacity(0.08);
      txt = AppTheme.primary;
    } else if (status == 'Closed') {
      bg = Colors.green.withOpacity(0.08);
      txt = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- 3. HIGH-FIDELITY TICKET DETAIL VIEW OVERHAUL ---
  Widget _buildTicketDetailsView(BuildContext context, Map<String, dynamic> tk, bool isDesktop) {
    final String overdueLabel = 'Overdue by ${tk['overdue_days'] ?? 12} days';
    final List<dynamic> msgList = tk['messages'] ?? [];
    final List<dynamic> followersList = tk['followers'] ?? [];

    final leftCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ticket Conversation Card Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${tk['id']} ${tk['subject']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const Spacer(),
                  // Overdue label tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                    ),
                    child: Text(
                      overdueLabel.toUpperCase(),
                      style: const TextStyle(color: AppTheme.accent, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status tag
                  _buildStatusChip(tk['status']),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderGrey),
              const SizedBox(height: 12),
              // Message History list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: msgList.length,
                itemBuilder: (context, idx) {
                  final msg = msgList[idx];
                  final bool isAdmin = msg['is_admin'] == true;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAdmin ? AppTheme.primary.withOpacity(0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdmin ? AppTheme.primary.withOpacity(0.08) : AppTheme.borderGrey,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: Text(
                                msg['sender'].substring(0, 1),
                                style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['sender'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                ),
                                Text(
                                  msg['designation'] ?? '',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              msg['time'],
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          msg['content'],
                          style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Live Reply Message Composer Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.description_outlined, size: 16, color: AppTheme.secondary),
                    label: const Text('Response Templates', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.format_bold, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.format_italic, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.format_underlined, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.format_list_bulleted, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.format_list_numbered, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.link, size: 18), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.image_outlined, size: 18), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replyController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                decoration: const InputDecoration(
                  hintText: 'To mention an employee or a role, simply type \'@\' followed by their name...',
                  fillColor: AppTheme.bgLight,
                  filled: true,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.attach_file, color: AppTheme.textMuted), onPressed: () {}),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_replyController.text.trim().isNotEmpty) {
                        setState(() {
                          msgList.add({
                            'sender': 'Support Agent',
                            'designation': 'Support Lead',
                            'content': _replyController.text.trim(),
                            'time': DateFormat('dd MMM yyyy \'at\' hh:mm a').format(DateTime.now()),
                            'is_admin': true,
                          });
                          _replyController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final rightCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Internal Notes
        _buildDetailSidebarCard(
          title: 'Internal Notes',
          child: Column(
            children: [
              TextField(
                controller: _noteController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Add a note for your team',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircleAvatar(radius: 12, child: Text('V', style: TextStyle(fontSize: 10))),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note added internally')));
                    _noteController.clear();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Card 2: Ticket raised info
        _buildDetailSidebarCard(
          title: 'Ticket raised on ${tk['created_at']} by ${tk['raised_by']}',
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.secondary.withOpacity(0.08),
                child: Text(tk['raised_by'].substring(0, 1), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tk['raised_by'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                    Text(tk['designation'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(tk['phone'] ?? '9188502554', style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(tk['location'] ?? 'Hosur', style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Card 3: Followers
        _buildDetailSidebarCard(
          title: 'Ticket followers',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...followersList.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primary.withOpacity(0.08),
                          child: Text(f.substring(0, 1), style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      )),
                  TextButton(
                    onPressed: () {},
                    child: const Text('+ Add', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Card 4: Ticket Details Dropdowns
        _buildDetailSidebarCard(
          title: 'Ticket details',
          action: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket metadata updated successfully')));
            },
            child: const Text('Update', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusDropdown(tk),
              const SizedBox(height: 12),
              _buildPriorityDropdown(tk),
              const SizedBox(height: 12),
              _buildDetailSelect('Category', tk['category']),
              const SizedBox(height: 12),
              _buildDetailSelect('Sub-category', tk['sub_category'] ?? 'Website Support'),
              const SizedBox(height: 14),
              const Text('Assigned to', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                tk['assigned_to_name'] ?? 'Support Agent',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Navigation Back strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _selectedTicket = null),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primary, size: 18),
                  label: const Text(
                    'Back to Tickets List',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        // Switch between ticket 9280 and 9270 in mock list!
                        final idx = _tickets.indexOf(tk);
                        if (idx > 0) {
                          setState(() => _selectedTicket = _tickets[idx - 1]);
                        }
                      },
                    ),
                    Text(
                      '${_tickets.indexOf(tk) + 1} of ${_tickets.length}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        final idx = _tickets.indexOf(tk);
                        if (idx < _tickets.length - 1) {
                          setState(() => _selectedTicket = _tickets[idx + 1]);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Split-pane layout
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: leftCol),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: rightCol),
                    ],
                  )
                : Column(
                    children: [
                      leftCol,
                      const SizedBox(height: 16),
                      rightCol,
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSidebarCard({required String title, Widget? action, required Widget child}) {
    return Container(
      decoration: AppTheme.glassDecoration(color: Colors.white, opacity: 0.90, borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Map<String, dynamic> tk) {
    final currentStatus = tk['status'] ?? 'Open';
    final options = ['Open', 'In Progress', 'On Hold', 'Closed'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentStatus) ? currentStatus : 'Open',
              isExpanded: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() {
                    tk['status'] = newVal;
                  });
                }
              },
              items: options.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown(Map<String, dynamic> tk) {
    final currentPriority = (tk['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final options = ['LOW', 'MEDIUM', 'HIGH'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentPriority) ? currentPriority : 'MEDIUM',
              isExpanded: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() {
                    tk['priority'] = newVal;
                  });
                }
              },
              items: options.map((v) {
                Color dotColor;
                String displayLabel;
                if (v == 'LOW') {
                  dotColor = Colors.grey;
                  displayLabel = 'Low';
                } else if (v == 'MEDIUM') {
                  dotColor = Colors.amber.shade700;
                  displayLabel = 'Medium';
                } else {
                  dotColor = Colors.orange.shade800;
                  displayLabel = 'High';
                }
                
                return DropdownMenuItem<String>(
                  value: v,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(displayLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSelect(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.06)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              onChanged: (_) {},
              items: [value].map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. REPORTS TAB ---
  Widget _buildReportsTab() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'Reports & Metrics (Phase 2)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Performance charts and analytical ticket reports will be enabled in the upcoming release.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
