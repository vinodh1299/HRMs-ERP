import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/leave.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(context, employee?.fullName ?? 'Employee'),
          _buildWelcomeTab(context, employee?.fullName ?? 'Employee'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context, String employeeName) {
    final isDesktop = Responsive.isDesktop(context);

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWelcomeBanner(employeeName),
        const SizedBox(height: 16),
        _buildTimeTodayWidget(),
        const SizedBox(height: 16),
        _buildLeaveBalancesWidget(),
        const SizedBox(height: 16),
        _buildHolidaysWidget(),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnnouncementsFeed(),
        const SizedBox(height: 16),
        _buildCelebrationsWidget(),
        const SizedBox(height: 16),
        _buildPollsWidget(),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: isDesktop
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

    return Card(
      child: Padding(
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
      ),
    );
  }

  Widget _buildAnnouncementsFeed() {
    return Card(
      child: Padding(
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
      ),
    );
  }

  Widget _buildCelebrationsWidget() {
    return Card(
      child: Padding(
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
      ),
    );
  }

  Widget _buildPollsWidget() {
    return Card(
      child: Padding(
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
