import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/date_parser_helper.dart';
import '../../models/leave.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/events_provider.dart';
import '../../services/api_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _polls = [];
  String _selectedWorkMode = 'Office';
  late Timer _timer;
  String _currentTime = '';
  final List<Map<String, String>> _recentTickets = [
    {
      'dept': 'Maintenance',
      'service': 'Light bulb change',
      'desc': 'Please replace the faulty tube light in classroom 3B by 13 sep 2026.',
      'status': 'Pending'
    },
    {
      'dept': 'Media',
      'service': 'Live stream setup',
      'desc': 'Audio mixer testing scheduled for tomorrow morning 10AM.',
      'status': 'In Progress'
    }
  ];

  bool _isChatOpen = false;
  bool _isAiTyping = false;
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Live Clock timer
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _loadDashboardData() {
    ref.read(attendanceProvider.notifier).fetchLogs();
    ref.read(leaveProvider.notifier).fetchLeaveData();
    _fetchAnnouncementsAndPolls();
  }

  void _fetchAnnouncementsAndPolls() async {
    try {
      final ann = await _apiService.getAnnouncements();
      final pl = await _apiService.getPolls();
      if (mounted) {
        setState(() {
          _announcements = ann;
          _polls = pl;
        });
      }
    } catch (_) {}
  }

  Widget _buildDepartmentPortalsRow() {
    final list = [
      {'name': 'Media', 'icon': Icons.video_camera_back_outlined, 'color': Colors.blue},
      {'name': 'Maintenance', 'icon': Icons.build_outlined, 'color': Colors.amber},
      {'name': 'Finance', 'icon': Icons.account_balance_wallet_outlined, 'color': Colors.green},
      {'name': 'CPD', 'icon': Icons.school_outlined, 'color': Colors.purple},
      {'name': 'HR', 'icon': Icons.badge_outlined, 'color': Colors.pink},
      {'name': 'Inventory', 'icon': Icons.inventory_2_outlined, 'color': Colors.teal},
      {'name': 'HOB', 'icon': Icons.cookie_outlined, 'color': Colors.orange},
      {'name': 'IT', 'icon': Icons.computer_outlined, 'color': Colors.indigo},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'DEPARTMENT PORTALS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final dept = list[index];
              final name = dept['name'] as String;
              final icon = dept['icon'] as IconData;
              final color = dept['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 95,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderGrey, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openDepartmentSheet(context, name, icon, color),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDepartmentSheet(BuildContext context, String deptName, IconData icon, Color color) {
    final Map<String, List<String>> services = {
      'Media': ['Video editing request', 'Livestream setup', 'AV equipment request', 'Photography booking'],
      'Maintenance': ['Light bulb change', 'Plumbing repair', 'Carpentry fix', 'AC maintenance', 'Electrical issues'],
      'Finance': ['Expense reimbursement', 'Invoice processing request', 'Salary discrepancy query', 'Tax declaration support'],
      'CPD': ['Register for workshop', 'Course material request', 'Certificate collection', 'Training log approval'],
      'HR': ['Leave policy query', 'Address proof request', 'Update bank details', 'Provident fund issue'],
      'Inventory': ['Request laptop accessories', 'Stationary requisition', 'Office chair replacement'],
      'HOB': ['Event catering order', 'Bread order placement', 'Pantry issue report', 'Kitchen cleaning request'],
      'IT': ['Software installation request', 'Hardware troubleshooting', 'Network & VPN access', 'Email / account setup'],
    };

    final Map<String, List<Map<String, dynamic>>> presence = {
      'Media': [
        {
          'name': 'Ananya Hari',
          'role': 'Graphic Designer',
          'location': 'Home',
          'email': 'ananya.hari@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Athul Jospeh Alex',
          'role': 'Sound Engineer',
          'location': 'Home',
          'email': 'athul.alex@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Bevan Thomson',
          'role': 'Audio Visual Specialist',
          'location': 'Home',
          'email': 'bevan.thomson@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Vinodhkumar Lakshmanan',
          'role': 'Full-Stack Developer',
          'location': 'Home',
          'email': 'vinodhkumar@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'Maintenance': [
        {
          'name': 'Peter Parker',
          'role': 'Plumber',
          'location': 'Office',
          'email': 'peter.parker@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Robert Bruce',
          'role': 'Electrician',
          'location': 'Home',
          'email': 'robert.bruce@acaindia.org',
          'status': 'OUT',
          'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Tony Stark',
          'role': 'HVAC Specialist',
          'location': 'Office',
          'email': 'tony.stark@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'Finance': [
        {
          'name': 'Grace Hopper',
          'role': 'Accountant',
          'location': 'Office',
          'email': 'grace.hopper@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Charles Babbage',
          'role': 'Financial Controller',
          'location': 'Home',
          'email': 'charles.babbage@acaindia.org',
          'status': 'OUT',
          'avatar': 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'CPD': [
        {
          'name': 'James Gosling',
          'role': 'Training Lead',
          'location': 'Office',
          'email': 'james.gosling@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Ada Lovelace',
          'role': 'CPD Coordinator',
          'location': 'Home',
          'email': 'ada.lovelace@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'HR': [
        {
          'name': 'Emma Watson',
          'role': 'HR Operations Manager',
          'location': 'Office',
          'email': 'emma.watson@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Paul Rudd',
          'role': 'Talent Recruiter',
          'location': 'Home',
          'email': 'paul.rudd@acaindia.org',
          'status': 'OUT',
          'avatar': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'Inventory': [
        {
          'name': 'Wilson Fisk',
          'role': 'Asset Auditor',
          'location': 'Office',
          'email': 'wilson.fisk@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Steven Rogers',
          'role': 'Inventory Clerk',
          'location': 'Home',
          'email': 'steven.rogers@acaindia.org',
          'status': 'OUT',
          'avatar': 'https://images.unsplash.com/photo-1489980508314-941910ded1f4?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'HOB': [
        {
          'name': 'Chef Pierre',
          'role': 'Head Chef',
          'location': 'Office',
          'email': 'chef.pierre@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Assistant Jean',
          'role': 'Sous Chef',
          'location': 'Office',
          'email': 'assistant.jean@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=150&auto=format&fit=crop&q=80',
        },
      ],
      'IT': [
        {
          'name': 'Linus Torvalds',
          'role': 'IT Support Specialist',
          'location': 'Office',
          'email': 'linus.torvalds@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1547037579-f0fc020ac3be?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Steve Wozniak',
          'role': 'Systems Admin',
          'location': 'Office',
          'email': 'steve.wozniak@acaindia.org',
          'status': 'IN',
          'avatar': 'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=150&auto=format&fit=crop&q=80',
        },
        {
          'name': 'Guido van Rossum',
          'role': 'IT Architect',
          'location': 'Home',
          'email': 'guido.rossum@acaindia.org',
          'status': 'OUT',
          'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
        },
      ],
    };

    final deptServices = services[deptName] ?? ['General Support Request'];
    final deptPresence = presence[deptName] ?? [];

    String selectedService = deptServices.first;
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '$deptName Portal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Section 1: Team Presence
                  Text(
                    'TEAM PRESENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (deptPresence.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No team presence information listed.'),
                    )
                  else
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: deptPresence.length,
                        itemBuilder: (context, index) {
                          return _buildStaffCard(deptPresence[index], deptName);
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Section 2: Helpdesk Ticket
                  Text(
                    'RAISE SERVICE TICKET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedService,
                    decoration: const InputDecoration(
                      labelText: 'Select Service Required',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: deptServices.map((String service) {
                      return DropdownMenuItem<String>(
                        value: service,
                        child: Text(service, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedService = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / Remarks',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final desc = descController.text.trim();
                      if (desc.isEmpty) return;
                      
                      setState(() {
                        _recentTickets.insert(0, <String, String>{
                          'dept': deptName,
                          'service': selectedService,
                          'desc': desc,
                          'status': 'Pending'
                        });
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ticket created successfully for $deptName ($selectedService)'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Submit Ticket Request',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.borderGrey),
                  const SizedBox(height: 16),
                  Text(
                    'RECENT TICKETS FOR $deptName',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._recentTickets.where((t) => t['dept'] == deptName).map((t) {
                    return Card(
                      color: AppTheme.bgLight,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t['service']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t['status'] == 'Pending' ? Colors.amber.withOpacity(0.12) : Colors.blue.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t['status']!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: t['status'] == 'Pending' ? Colors.amber[800] : Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            DateParserHelper.buildClickableText(
                              context,
                              ref,
                              t['desc']!,
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textBody),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff, String deptName) {
    final name = staff['name'] as String;
    final role = staff['role'] as String;
    final location = staff['location'] as String;
    final email = staff['email'] as String;
    final isIN = staff['status'] == 'IN';
    final avatarUrl = staff['avatar'] as String;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderGrey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            location == 'Home' ? Icons.laptop_mac_rounded : Icons.apartment_rounded,
                            size: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Location : $location',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department : $deptName',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email : $email',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: isIN ? const Color(0xFF84CC16) : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isIN ? 'IN' : 'OUT',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final employee = authState.employee;
    
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
              Tab(text: 'Dashboard'),
              Tab(text: 'Welcome Onboarding'),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(context, employee?.fullName ?? 'Employee'),
              _buildWelcomeTab(context, employee?.fullName ?? 'Employee'),
            ],
          ),
          if (_isChatOpen)
            Positioned(
              right: 20,
              bottom: 80,
              child: _buildChatDrawerWidget(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isChatOpen = !_isChatOpen;
            if (_isChatOpen && _chatMessages.isEmpty) {
              _chatMessages.add({
                'sender': 'assistant',
                'text': 'Hello! I am your ACA Portal AI Assistant. I can help you check employee presence (e.g. "Is Vinodh in today?") or raise a ticket (e.g. "Raise a ticket to IT to change the light bulb in the auditorium"). What can I do for you today?',
                'time': DateTime.now(),
              });
            }
          });
        },
        backgroundColor: AppTheme.primary,
        child: Icon(_isChatOpen ? Icons.close_rounded : Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context, String employeeName) {
    final isDesktop = Responsive.isDesktop(context);

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'TIME & ATTENDANCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.1,
            ),
          ),
        ),
        _buildTimeTodayWidget(),
        const SizedBox(height: 16),
        const InteractiveCalendarWidget(),
        const SizedBox(height: 16),
        _buildHolidaysWidget(),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDepartmentPortalsRow(),
        const SizedBox(height: 16),
        _buildAnnouncementsFeed(),
        const SizedBox(height: 16),
        _buildCelebrationsWidget(),
        const SizedBox(height: 16),
        _buildPollsWidget(),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeBanner(employeeName),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: rightColumn),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: leftColumn),
                  ],
                )
              : Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 16),
                    rightColumn,
                  ],
                ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildWelcomeBanner(String employeeName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.secondary],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Subtle dot-grid texture painted across the whole banner
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            // Decorative soft glow blobs for depth
            Positioned(
              right: -40, top: -50,
              child: _blob(180, AppTheme.secondaryLight.withOpacity(0.35)),
            ),
            Positioned(
              right: 60, bottom: -70,
              child: _blob(160, AppTheme.accent.withOpacity(0.22)),
            ),
            Positioned(
              left: -30, bottom: -60,
              child: _blob(140, Colors.white.withOpacity(0.08)),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_greeting()}, $employeeName!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Have a productive day today. Make sure to complete your checklist.',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    // ImageFiltered blurs the shape's own rendering (soft glow edges),
    // unlike BackdropFilter which only blurs content *behind* it.
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildTimeTodayWidget() {
    final attState = ref.watch(attendanceProvider);
    final todayLog = attState.todayLog;
    final isCheckedIn = todayLog != null && todayLog.checkIn != null;
    final isCheckedOut = todayLog != null && todayLog.checkOut != null;
    final String todayStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    final Color statusColor = isCheckedOut
        ? const Color(0xFF059669)
        : (isCheckedIn ? Colors.orange : AppTheme.primary);
    final String statusLabel = isCheckedOut ? 'Day Complete' : isCheckedIn ? 'Working' : 'Not Checked In';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title + work mode ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text('Time Today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedWorkMode,
                    isDense: true,
                    onChanged: isCheckedIn ? null : (val) => setState(() => _selectedWorkMode = val!),
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 12, fontWeight: FontWeight.w600),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textMuted),
                    items: ['Office', 'Work From Home', 'On Duty'].map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── Time + status + button in one clean row ───────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(todayStr, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    if (isCheckedIn) ...[  
                      const SizedBox(height: 6),
                      Text(
                        isCheckedOut
                            ? '${todayLog!.checkIn}  →  ${todayLog.checkOut}'
                            : 'Clocked in at ${todayLog!.checkIn}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isCheckedOut ? AppTheme.textMuted : statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Status + button stacked
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(statusLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                    ]),
                  ),
                  if (!isCheckedOut) ...[  
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!isCheckedIn) {
                          final ok = await ref.read(attendanceProvider.notifier).checkIn(source: _selectedWorkMode);
                          if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked In ✓')));
                        } else {
                          final ok = await ref.read(attendanceProvider.notifier).checkOut();
                          if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked Out ✓')));
                        }
                      },
                      icon: Icon(isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 15),
                      label: Text(
                        isCheckedIn ? 'Clock Out' : 'Clock In',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCheckedIn ? Colors.orange : AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalancesWidget() {
    final leaveState = ref.watch(leaveProvider);
    final balances = leaveState.balances;

    final List<Color> _dotColors = [
      const Color(0xFF003471),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF00AEEF),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text('Leave Balances', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ]),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Leave list rows
          if (leaveState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (balances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No leave balances available.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            )
          else
            ...List.generate(balances.length, (index) {
              final b = balances[index];
              final val = double.tryParse('${b.balance}') ?? 0.0;
              final total = 15.0;
              final used = (total - val).clamp(0.0, total);
              final fraction = (val / total).clamp(0.0, 1.0);
              final color = _dotColors[index % _dotColors.length];

              return Padding(
                padding: EdgeInsets.only(bottom: index < balances.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    // Colour dot
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    // Leave type name
                    SizedBox(
                      width: 110,
                      child: Text(
                        b.leaveTypeName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Progress bar
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: color.withOpacity(0.10),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Balance
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${b.balance} d',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHolidaysWidget() {
    final leaveState = ref.watch(leaveProvider);
    final holidays = leaveState.holidays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Holidays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          if (holidays.isEmpty)
            const Text('No holidays listed.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holidays.length > 3 ? 3 : holidays.length,
              separatorBuilder: (context, idx) => const Divider(color: AppTheme.borderGrey),
              itemBuilder: (context, idx) {
                final h = holidays[idx];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.celebration, color: AppTheme.primary),
                  title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(h.date),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsFeed() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          if (_announcements.isEmpty)
            const Text('No company announcements posted.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _announcements.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final a = _announcements[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              a['category'] ?? 'General',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['content'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCelebrationsWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Celebrations Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: const Text('SR', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suresh Raina', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Birthday Today!', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollsWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pulse Polls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          if (_polls.isEmpty)
            const Text('No polls currently active.')
          else
            ..._polls.map((p) {
              final List options = p['options'] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...options.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for voting!')));
                        },
                        child: Text(opt.toString()),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildWelcomeTab(BuildContext context, String employeeName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: AppTheme.glassDecoration(
            color: Colors.white,
            opacity: 0.85,
            borderRadius: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Gradient Panel
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF0F2D59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, $employeeName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your onboarding checklist status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Checklist Content Padding
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildChecklistItem('Verify Bank Account details under My Finances', true),
                    _buildChecklistItem('Provide PAN & Aadhaar details to HR', true),
                    _buildChecklistItem('Complete IT Asset checklist allocation', false),
                    _buildChecklistItem('Read and Acknowledge Organization Policy doc', false),
                    _buildChecklistItem('Verify Emergency Contact details', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isDone) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? Colors.grey.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? Colors.grey.withOpacity(0.12) : AppTheme.primary.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: isDone
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDone ? AppTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDone ? AppTheme.accent : AppTheme.textMuted.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.check,
              size: 16,
              color: isDone ? Colors.white : Colors.transparent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? AppTheme.textMuted : AppTheme.textDark,
                fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDrawerWidget() {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 500;
    final drawerWidth = isSmall ? width - 40 : 360.0;
    final drawerHeight = isSmall ? 420.0 : 500.0;

    return Container(
      width: drawerWidth,
      height: drawerHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'ACA Portal AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Secure Domain Guardrail Active',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _isChatOpen = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppTheme.bgLight,
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _chatMessages.length + (_isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatMessages.length && _isAiTyping) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(color: AppTheme.borderGrey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI is typing...',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = _chatMessages[index];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: drawerWidth * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                        ),
                        border: isUser ? null : Border.all(color: AppTheme.borderGrey),
                        boxShadow: isUser
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.015),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppTheme.textDark,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
              border: Border(
                top: BorderSide(color: AppTheme.borderGrey),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ask about staff presence or raising a ticket...',
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (val) {
                      final txt = val.trim();
                      if (txt.isNotEmpty) {
                        _chatController.clear();
                        _processAgentMessage(txt);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary, size: 20),
                  onPressed: () {
                    final txt = _chatController.text.trim();
                    if (txt.isNotEmpty) {
                      _chatController.clear();
                      _processAgentMessage(txt);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _checkIfAppRelated(String text) {
    final keywords = [
      'ticket', 'raise', 'create', 'submit', 'issue', 'request', 'reimburse',
      'it', 'maintenance', 'finance', 'cpd', 'hr', 'inventory', 'hob', 'media',
      'attendance', 'clock', 'check', 'in', 'out', 'leave', 'holiday',
      'vinodh', 'ananya', 'athul', 'bevan', 'presence', 'staff', 'employee',
      'suresh', 'linus', 'steve', 'guido', 'chef pierre', 'assistant jean',
      'peter parker', 'tony stark', 'robert bruce', 'grace hopper',
      'ada lovelace', 'emma watson', 'paul rudd', 'wilson fisk', 'steven rogers',
      'bulb', 'light', 'mixer', 'software', 'install', 'rehearsal', 'annual',
      'work from home', 'office', 'help', 'onboarding', 'support', 'mix'
    ];
    
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  void _processAgentMessage(String userText) {
    final text = userText.trim().toLowerCase();
    
    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'text': userText,
        'time': DateTime.now(),
      });
      _isAiTyping = true;
    });
    _scrollToBottom();

    try {
      final isAppRelated = _checkIfAppRelated(text);
      if (!isAppRelated) {
        _addAssistantReply("I am only authorized to assist with ACA HRMs-ERP application operations, such as checking staff presence, raising department tickets, or portal info. Please ask a question related to this app.");
        return;
      }

      if (text.contains('ticket') || text.contains('raise') || text.contains('create') || text.contains('change') || text.contains('issue') || text.contains('reimburse') || text.contains('request')) {
        _handleTicketCreationIntent(userText);
        return;
      }

      if (text.contains('presence') || text.contains('is ') || text.contains('status') || text.contains('in today') || text.contains('out today') || text.contains('here')) {
        _handlePresenceQueryIntent(text);
        return;
      }

      _addAssistantReply("I can help you with two main actions:\n1. **Raise a ticket**: Ask me to 'Raise a ticket to IT to change the light bulb in the auditorium'.\n2. **Check staff presence**: Ask me 'Is Vinodh from Media in today?'");
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
        });
      }
      _addAssistantReply("Apologies, I encountered an error processing that request. Please try again.");
    }
  }

  void _handleTicketCreationIntent(String originalText) {
    final text = originalText.toLowerCase();
    String deptName = 'IT';
    String serviceName = 'Support request';
    
    if (text.contains('maintenance') || text.contains('bulb') || text.contains('light') || text.contains('plumb') || text.contains('repair')) {
      deptName = 'Maintenance';
      serviceName = 'Light bulb change';
    } else if (text.contains('hr') || text.contains('leave') || text.contains('policy')) {
      deptName = 'HR';
      serviceName = 'Leave policy query';
    } else if (text.contains('finance') || text.contains('reimburse') || text.contains('salary') || text.contains('invoice')) {
      deptName = 'Finance';
      serviceName = 'Expense reimbursement';
    } else if (text.contains('cpd') || text.contains('training') || text.contains('workshop')) {
      deptName = 'CPD';
      serviceName = 'Register for workshop';
    } else if (text.contains('inventory') || text.contains('laptop') || text.contains('chair') || text.contains('accessory')) {
      deptName = 'Inventory';
      serviceName = 'Request laptop accessories';
    } else if (text.contains('hob') || text.contains('catering') || text.contains('food') || text.contains('pantry')) {
      deptName = 'HOB';
      serviceName = 'Event catering order';
    } else if (text.contains('media') || text.contains('video') || text.contains('stream') || text.contains('photography') || text.contains('mixer')) {
      deptName = 'Media';
      serviceName = 'Live stream setup';
    } else {
      deptName = 'IT';
      if (text.contains('software')) {
        serviceName = 'Software installation request';
      } else if (text.contains('hardware')) {
        serviceName = 'Hardware troubleshooting';
      } else if (text.contains('vpn') || text.contains('network') || text.contains('internet')) {
        serviceName = 'Network & VPN access';
      } else {
        serviceName = 'Email / account setup';
      }
    }

    // Clean up request phrases
    String cleanDesc = originalText;
    cleanDesc = cleanDesc.replaceAll(RegExp(r'(?i)raise\s+a\s+ticket(?:\s+to\s+(?:it|hr|maintenance|finance|cpd|inventory|hob|media))?', caseSensitive: false), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'(?i)\bcan\s+u\b', caseSensitive: false), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'(?i)\bplease\b', caseSensitive: false), '');
    cleanDesc = cleanDesc.trim();
    if (cleanDesc.toLowerCase().startsWith('to ')) {
      cleanDesc = cleanDesc.substring(3).trim();
    }
    if (cleanDesc.isNotEmpty) {
      cleanDesc = cleanDesc[0].toUpperCase() + cleanDesc.substring(1);
    } else {
      cleanDesc = "Requested support service.";
    }

    final authState = ref.read(authProvider);
    final employeeName = authState.employee?.fullName ?? 'Employee';
    final formattedDesc = "Dear Sir,\n\n$cleanDesc\n\nWith Regards,\n$employeeName.";

    setState(() {
      _recentTickets.insert(0, <String, String>{
        'dept': deptName,
        'service': serviceName,
        'desc': formattedDesc,
        'status': 'Pending'
      });
    });

    _addAssistantReply("I have automatically raised a **$deptName** ticket for you! 🎫\n\n"
        "* **Service**: $serviceName\n"
        "* **Details**:\n$formattedDesc\n"
        "* **Status**: Pending\n\n"
        "You can track this instantly in the **$deptName Department Portal** under recent tickets!");
  }

  void _handlePresenceQueryIntent(String text) {
    final staffList = [
      {'name': 'Ananya Hari', 'dept': 'Media', 'role': 'Graphic Designer', 'location': 'Home', 'email': 'ananya.hari@acaindia.org', 'status': 'IN'},
      {'name': 'Athul Jospeh Alex', 'dept': 'Media', 'role': 'Sound Engineer', 'location': 'Home', 'email': 'athul.alex@acaindia.org', 'status': 'IN'},
      {'name': 'Bevan Thomson', 'dept': 'Media', 'role': 'Audio Visual Specialist', 'location': 'Home', 'email': 'bevan.thomson@acaindia.org', 'status': 'IN'},
      {'name': 'Vinodhkumar Lakshmanan', 'dept': 'Media', 'role': 'Full-Stack Developer', 'location': 'Home', 'email': 'vinodhkumar@acaindia.org', 'status': 'IN'},
      {'name': 'Peter Parker', 'dept': 'Maintenance', 'role': 'Plumber', 'location': 'Office', 'email': 'peter.parker@acaindia.org', 'status': 'IN'},
      {'name': 'Robert Bruce', 'dept': 'Maintenance', 'role': 'Electrician', 'location': 'Home', 'email': 'robert.bruce@acaindia.org', 'status': 'OUT'},
      {'name': 'Tony Stark', 'dept': 'Maintenance', 'role': 'HVAC Specialist', 'location': 'Office', 'email': 'tony.stark@acaindia.org', 'status': 'IN'},
      {'name': 'Grace Hopper', 'dept': 'Finance', 'role': 'Accountant', 'location': 'Office', 'email': 'grace.hopper@acaindia.org', 'status': 'IN'},
      {'name': 'Charles Babbage', 'dept': 'Finance', 'role': 'Financial Controller', 'location': 'Home', 'email': 'charles.babbage@acaindia.org', 'status': 'OUT'},
      {'name': 'James Gosling', 'dept': 'CPD', 'role': 'Training Lead', 'location': 'Office', 'email': 'james.gosling@acaindia.org', 'status': 'IN'},
      {'name': 'Ada Lovelace', 'dept': 'CPD', 'role': 'CPD Coordinator', 'location': 'Home', 'email': 'ada.lovelace@acaindia.org', 'status': 'IN'},
      {'name': 'Emma Watson', 'dept': 'HR', 'role': 'HR Operations Manager', 'location': 'Office', 'email': 'emma.watson@acaindia.org', 'status': 'IN'},
      {'name': 'Paul Rudd', 'dept': 'HR', 'role': 'Talent Recruiter', 'location': 'Home', 'email': 'paul.rudd@acaindia.org', 'status': 'OUT'},
      {'name': 'Wilson Fisk', 'dept': 'Inventory', 'role': 'Asset Auditor', 'location': 'Office', 'email': 'wilson.fisk@acaindia.org', 'status': 'IN'},
      {'name': 'Steven Rogers', 'dept': 'Inventory', 'role': 'Inventory Clerk', 'location': 'Home', 'email': 'steven.rogers@acaindia.org', 'status': 'OUT'},
      {'name': 'Chef Pierre', 'dept': 'HOB', 'role': 'Head Chef', 'location': 'Office', 'email': 'chef.pierre@acaindia.org', 'status': 'IN'},
      {'name': 'Assistant Jean', 'dept': 'HOB', 'role': 'Sous Chef', 'location': 'Office', 'email': 'assistant.jean@acaindia.org', 'status': 'IN'},
      {'name': 'Linus Torvalds', 'dept': 'IT', 'role': 'IT Support Specialist', 'location': 'Office', 'email': 'linus.torvalds@acaindia.org', 'status': 'IN'},
      {'name': 'Steve Wozniak', 'dept': 'IT', 'role': 'Systems Admin', 'location': 'Office', 'email': 'steve.wozniak@acaindia.org', 'status': 'IN'},
      {'name': 'Guido van Rossum', 'dept': 'IT', 'role': 'IT Architect', 'location': 'Home', 'email': 'guido.rossum@acaindia.org', 'status': 'OUT'},
    ];

    Map<String, dynamic>? foundStaff;
    for (final staff in staffList) {
      final nameParts = staff['name']!.toLowerCase().split(' ');
      for (final part in nameParts) {
        if (part.length > 2 && text.contains(part)) {
          foundStaff = staff;
          break;
        }
      }
      if (foundStaff != null) break;
    }

    if (foundStaff != null) {
      final name = foundStaff['name'];
      final status = foundStaff['status'];
      final role = foundStaff['role'];
      final dept = foundStaff['dept'];
      final location = foundStaff['location'];
      final email = foundStaff['email'];
      
      _addAssistantReply("Let me check employee presence... 🔍\n\n"
          "**$name** is **$status** today.\n"
          "* **Role**: $role\n"
          "* **Department**: $dept\n"
          "* **Work Location**: $location\n"
          "* **Email**: $email");
    } else {
      _addAssistantReply("I couldn't find that employee in the presence directory. Please check the name (e.g. 'Vinodh', 'Ananya', 'Linus').");
    }
  }

  void _addAssistantReply(String text) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isAiTyping = false;
          _chatMessages.add({
            'sender': 'assistant',
            'text': text,
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// Paints a subtle, evenly-spaced dot grid used as texture over the
/// welcome banner's gradient background — purely procedural, no image asset.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.07);
    const spacing = 22.0;
    const radius = 1.4;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Interactive Calendar & Blinking Event Widgets ────────────────────────────

class PulsatingEventContainer extends StatefulWidget {
  final Widget child;
  const PulsatingEventContainer({required this.child, super.key});

  @override
  State<PulsatingEventContainer> createState() => _PulsatingEventContainerState();
}

class _PulsatingEventContainerState extends State<PulsatingEventContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.15 + (_glowAnimation.value * 0.2)),
                blurRadius: 4 + (_glowAnimation.value * 6),
                spreadRadius: _glowAnimation.value * 1.5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class InteractiveCalendarCell extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const InteractiveCalendarCell({required this.child, required this.onTap, super.key});

  @override
  State<InteractiveCalendarCell> createState() => _InteractiveCalendarCellState();
}

class _InteractiveCalendarCellState extends State<InteractiveCalendarCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.animateTo(0.9, curve: Curves.easeOutCubic);
        },
        onTapUp: (_) {
          _controller.animateTo(1.0, curve: Curves.elasticOut);
          widget.onTap();
        },
        onTapCancel: () {
          _controller.animateTo(1.0, curve: Curves.easeOutCubic);
        },
        child: ScaleTransition(
          scale: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}

class InteractiveCalendarWidget extends ConsumerStatefulWidget {
  const InteractiveCalendarWidget({super.key});

  @override
  ConsumerState<InteractiveCalendarWidget> createState() => _InteractiveCalendarWidgetState();
}

class _InteractiveCalendarWidgetState extends ConsumerState<InteractiveCalendarWidget> with TickerProviderStateMixin {
  late DateTime _currentMonth;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _staggerController.forward(from: 0.0);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _staggerController.forward(from: 0.0);
  }

  int _daysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  String _shortEventTitle(String title) {
    if (title.length <= 8) return title;
    final words = title.split(' ');
    if (words.length > 1) {
      final lastWord = words.last.trim();
      if (lastWord.length <= 8) return lastWord;
      final firstWord = words.first.trim();
      if (firstWord.length <= 8) return firstWord;
    }
    return title.length > 8 ? '${title.substring(0, 7)}…' : title;
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final now = DateTime.now();
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final totalDays = _daysInMonth(_currentMonth);
    final startOffset = firstDayOfMonth.weekday % 7;

    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _prevMonth,
              ),
              Text(
                monthName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 28,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + totalDays,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final dayNum = index - startOffset + 1;
              final targetDate = DateTime(year, month, dayNum);
              final isToday = targetDate.year == now.year &&
                  targetDate.month == now.month &&
                  targetDate.day == now.day;

              final dayEvents = events.where((e) {
                return e.date.year == targetDate.year &&
                    e.date.month == targetDate.month &&
                    e.date.day == targetDate.day;
              }).toList();

              final hasEvents = dayEvents.isNotEmpty;

              final cellAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _staggerController,
                  curve: Interval(
                    ((index - startOffset) * 0.012).clamp(0.0, 0.6),
                    (((index - startOffset) * 0.012) + 0.35).clamp(0.0, 1.0),
                    curve: Curves.easeOutBack,
                  ),
                ),
              );

              Widget dayCell = Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primary : (hasEvents ? const Color(0xFFFEF3C7) : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? null
                      : Border.all(
                          color: hasEvents ? const Color(0xFFF59E0B) : Colors.transparent,
                          width: 1,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Colors.white
                            : (hasEvents ? const Color(0xFFB45309) : AppTheme.textDark),
                      ),
                    ),
                    if (hasEvents)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text(
                          _shortEventTitle(dayEvents.first.title),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              );

              if (hasEvents) {
                dayCell = PulsatingEventContainer(child: dayCell);
              }

              dayCell = ScaleTransition(
                scale: cellAnimation,
                child: FadeTransition(
                  opacity: cellAnimation,
                  child: dayCell,
                ),
              );

              return InteractiveCalendarCell(
                onTap: () {
                  if (hasEvents) {
                    _showDayEventsDialog(context, targetDate, dayEvents);
                  } else {
                    _showAddEventDirectDialog(context, targetDate);
                  }
                },
                child: dayCell,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDayEventsDialog(BuildContext context, DateTime date, List<CalendarEvent> dayEvents) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Scheduled Events',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              ...dayEvents.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.title,
                          style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddEventDirectDialog(context, date);
              },
              child: const Text('Add Event'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDirectDialog(BuildContext context, DateTime date) {
    final textController = TextEditingController();
    final dateStr = DateFormat('d MMMM yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Schedule Event',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: $dateStr',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Event Details',
                  hintText: 'e.g. Annual day rehearsals',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final title = textController.text.trim();
                if (title.isNotEmpty) {
                  ref.read(eventsProvider.notifier).addEvent(date, title);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Scheduled "$title" on $dateStr!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Save Event'),
            ),
          ],
        );
      },
    );
  }
}
