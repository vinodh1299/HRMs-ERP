import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../models/employee.dart';

class TicketDetailsDialog extends ConsumerStatefulWidget {
  final int ticketId;
  final VoidCallback onRefresh;

  const TicketDetailsDialog({
    super.key,
    required this.ticketId,
    required this.onRefresh,
  });

  @override
  ConsumerState<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends ConsumerState<TicketDetailsDialog> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _ticket = {};
  List<Map<String, dynamic>> _publicMessages = [];
  List<Map<String, dynamic>> _internalMessages = [];
  List<Employee> _mediaEmployees = [];
  bool _isLoading = false;
  int? _selectedAssigneeId;

  final TextEditingController _publicMsgController = TextEditingController();
  final TextEditingController _internalMsgController = TextEditingController();
  
  // States for approval request popup/builder
  bool _isApprovalRequestMode = false;
  String? _selectedMockImageUrl;
  final TextEditingController _captionController = TextEditingController();

  // Suggestion textfield per message index
  int? _activeSuggestionIndex;
  final TextEditingController _suggestionController = TextEditingController();

  final List<String> _mockImages = [
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=400&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=400&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _publicMsgController.dispose();
    _internalMsgController.dispose();
    _captionController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await _apiService.getTickets();
      final tk = tickets.firstWhere((t) => t['id'] == widget.ticketId, orElse: () => {});
      final publicMsgs = await _apiService.getPublicMessages(widget.ticketId);
      final internalMsgs = await _apiService.getInternalMessages(widget.ticketId);

      // Load media employees for assignment dropdown
      final allEmp = await _apiService.searchEmployees(dept: 1); // 1 = Media
      final mediaEmployees = allEmp.where((e) => e.reportingManagerId == 2 || e.id == 1).toList();

      setState(() {
        _ticket = tk;
        _publicMessages = publicMsgs;
        _internalMessages = internalMsgs;
        _mediaEmployees = mediaEmployees;
        _selectedAssigneeId = tk['assigned_to'] as int?;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPublicMessage() async {
    final text = _publicMsgController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    final senderName = authState.employee?.fullName ?? 'User';

    await _apiService.sendPublicMessage(widget.ticketId, {
      'sender': senderName,
      'content': text,
    });

    _publicMsgController.clear();
    _loadTicketDetails();
    widget.onRefresh();
  }

  Future<void> _sendInternalMessage() async {
    final text = _internalMsgController.text.trim();
    if (text.isEmpty && _selectedMockImageUrl == null) return;

    final authState = ref.read(authProvider);
    final senderName = authState.employee?.fullName ?? 'User';

    await _apiService.sendInternalMessage(widget.ticketId, {
      'sender': senderName,
      'content': text,
      'is_approval_request': _isApprovalRequestMode,
      'image': _selectedMockImageUrl,
      'caption': _selectedMockImageUrl != null ? _captionController.text.trim() : null,
    });

    _internalMsgController.clear();
    _captionController.clear();
    setState(() {
      _isApprovalRequestMode = false;
      _selectedMockImageUrl = null;
    });

    _loadTicketDetails();
    widget.onRefresh();
  }

  Future<void> _handleApprovalAction(int index, String status, {String? suggestion}) async {
    await _apiService.updateApprovalStatus(widget.ticketId, index, status, suggestion: suggestion);
    setState(() {
      _activeSuggestionIndex = null;
      _suggestionController.clear();
    });
    _loadTicketDetails();
    widget.onRefresh();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _ticket.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_ticket.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Ticket not found.')),
      );
    }

    final authState = ref.watch(authProvider);
    final isManager = authState.user?.role == 'Manager';
    final isEmployee = authState.user?.role == 'Employee';

    final dialogContent = SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: AppTheme.primary,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TKT-${_ticket['id']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_ticket['status']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getStatusColor(_ticket['status'])),
                            ),
                            child: Text(
                              _ticket['status'].toString().toUpperCase(),
                              style: TextStyle(color: _getStatusColor(_ticket['status']), fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ticket['subject'] ?? 'No Subject',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Raised by: ${_ticket['raised_by']} (${_ticket['designation']})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Split Area
          Expanded(
            child: Row(
              children: [
                // LEFT SIDE (70%): Public chat
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: AppTheme.borderGrey)),
                    ),
                    child: Column(
                      children: [
                        // Public chat header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: AppTheme.bgLight,
                          child: Row(
                            children: const [
                              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text(
                                'Public Chat (Visible to sender)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        // Public messages list
                        Expanded(
                          child: _publicMessages.isEmpty
                              ? const Center(child: Text('No public messages yet. Type below to start.', style: TextStyle(color: AppTheme.textMuted)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _publicMessages.length,
                                  itemBuilder: (context, idx) {
                                    final m = _publicMessages[idx];
                                    final isMe = m['sender'] == (authState.employee?.fullName ?? 'User');
                                    return Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? AppTheme.primary.withOpacity(0.08) : AppTheme.bgLight,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(12),
                                            topRight: const Radius.circular(12),
                                            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                                          ),
                                          border: Border.all(color: AppTheme.borderGrey),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              m['sender'],
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isMe ? AppTheme.primary : AppTheme.textDark),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              m['content'],
                                              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              m['time'],
                                              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(height: 1),
                        // Public Input
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _publicMsgController,
                                  decoration: InputDecoration(
                                    hintText: 'Type a message to the raised person...',
                                    hintStyle: const TextStyle(fontSize: 13),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onSubmitted: (_) => _sendPublicMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                  onPressed: _sendPublicMessage,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT SIDE (30%): Assign Option & Internal Private Chat
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Assignment / Status Action Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isManager) ...[
                              const Text(
                                'ASSIGN TICKET',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.1),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderGrey),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _selectedAssigneeId,
                                    hint: const Text('Unassigned', style: TextStyle(fontSize: 12)),
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Unassigned', style: TextStyle(fontSize: 12)),
                                      ),
                                      ..._mediaEmployees.map((emp) {
                                        return DropdownMenuItem<int?>(
                                          value: emp.id,
                                          child: Text(emp.fullName, style: const TextStyle(fontSize: 12)),
                                        );
                                      })
                                    ],
                                    onChanged: (newEmpId) {
                                      setState(() {
                                        _selectedAssigneeId = newEmpId;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() => _isLoading = true);
                                    await _apiService.assignTicket(widget.ticketId, _selectedAssigneeId);
                                    await _loadTicketDetails();
                                    widget.onRefresh();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket assignment updated successfully.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Update Assignment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ] else if (isEmployee) ...[
                              const Text(
                                'UPDATE STATUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1.1),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Working', style: TextStyle(fontSize: 10)),
                                      selected: _ticket['status'] == 'In Progress',
                                      onSelected: (val) async {
                                        if (val) {
                                          await _apiService.updateTicketStatus(widget.ticketId, 'In Progress');
                                          _loadTicketDetails();
                                          widget.onRefresh();
                                        }
                                      },
                                      selectedColor: Colors.orange.shade100,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Hold', style: TextStyle(fontSize: 10)),
                                      selected: _ticket['status'] == 'On Hold',
                                      onSelected: (val) async {
                                        if (val) {
                                          await _apiService.updateTicketStatus(widget.ticketId, 'On Hold');
                                          _loadTicketDetails();
                                          widget.onRefresh();
                                        }
                                      },
                                      selectedColor: Colors.blue.shade100,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Text('Closed', style: TextStyle(fontSize: 10)),
                                      selected: _ticket['status'] == 'Closed',
                                      onSelected: (val) async {
                                        if (val) {
                                          await _apiService.updateTicketStatus(widget.ticketId, 'Closed');
                                          _loadTicketDetails();
                                          widget.onRefresh();
                                        }
                                      },
                                      selectedColor: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ],
                        ),
                      ),
                      
                      // People involvement details with image above internal chat
                      _buildPeopleDetailsWidget(),
                      
                      const Spacer(),
                      
                      // INTERNAL PRIVATE CHAT
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withOpacity(0.05),
                          border: Border(top: BorderSide(color: AppTheme.borderGrey)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.amber.shade50,
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 14, color: Colors.amber.shade800),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Internal Chat (Manager & Staff Only)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                            // Message stream (small chat section: fixed height of 180)
                            SizedBox(
                              height: 180,
                              child: _internalMessages.isEmpty
                                  ? const Center(child: Text('No internal notes/chat.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)))
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _internalMessages.length,
                                      itemBuilder: (context, idx) {
                                        final m = _internalMessages[idx];
                                        final isApproval = m['is_approval_request'] == true;
                                        final isPendingApproval = m['approval_status'] == 'Pending';

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    m['sender'],
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textDark),
                                                  ),
                                                  Text(
                                                    m['time'],
                                                    style: const TextStyle(fontSize: 8, color: AppTheme.textMuted),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              if (m['content'] != null && m['content'].toString().isNotEmpty)
                                                Text(
                                                  m['content'],
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              if (m['image'] != null) ...[
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.network(
                                                    m['image'],
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: crop,
                                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                                                  ),
                                                ),
                                                if (m['caption'] != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    m['caption'],
                                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                                                  ),
                                                ],
                                              ],

                                              // Approval Request options/badge
                                              if (isApproval) ...[
                                                const SizedBox(height: 10),
                                                const Divider(height: 1),
                                                const SizedBox(height: 8),
                                                if (isPendingApproval) ...[
                                                  if (isManager) ...[
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () => _handleApprovalAction(idx, 'Approved'),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green,
                                                              foregroundColor: Colors.white,
                                                              padding: EdgeInsets.zero,
                                                              minimumSize: const Size(0, 28),
                                                            ),
                                                            child: const Text('Approve', style: TextStyle(fontSize: 10)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () => _handleApprovalAction(idx, 'Rejected'),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.red,
                                                              foregroundColor: Colors.white,
                                                              padding: EdgeInsets.zero,
                                                              minimumSize: const Size(0, 28),
                                                            ),
                                                            child: const Text('Reject', style: TextStyle(fontSize: 10)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                _activeSuggestionIndex = idx;
                                                              });
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.orange,
                                                              foregroundColor: Colors.white,
                                                              padding: EdgeInsets.zero,
                                                              minimumSize: const Size(0, 28),
                                                            ),
                                                            child: const Text('Suggest', style: TextStyle(fontSize: 10)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (_activeSuggestionIndex == idx) ...[
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: _suggestionController,
                                                        decoration: const InputDecoration(
                                                          hintText: 'Enter suggestion...',
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                        ),
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          final txt = _suggestionController.text.trim();
                                                          if (txt.isNotEmpty) {
                                                            _handleApprovalAction(idx, 'Suggestion', suggestion: txt);
                                                          }
                                                        },
                                                        child: const Text('Submit Suggestion', style: TextStyle(fontSize: 10)),
                                                      ),
                                                    ]
                                                  ] else ...[
                                                    Row(
                                                      children: const [
                                                        Icon(Icons.hourglass_empty, color: Colors.orange, size: 14),
                                                        SizedBox(width: 4),
                                                        Text('Pending Approval Request', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                                                      ],
                                                    )
                                                  ]
                                                ] else ...[
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        m['approval_status'] == 'Approved'
                                                            ? Icons.check_circle_outline
                                                            : Icons.highlight_off,
                                                        color: m['approval_status'] == 'Approved' ? Colors.green : Colors.red,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Status: ${m['approval_status']}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: m['approval_status'] == 'Approved' ? Colors.green : Colors.red,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ]
                                              ]
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const Divider(height: 1),
                            // Image/Request attachment helper builder UI
                            if (_selectedMockImageUrl != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.shade100,
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(_selectedMockImageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _captionController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter image caption...',
                                          hintStyle: TextStyle(fontSize: 11),
                                          border: InputBorder.none,
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        setState(() => _selectedMockImageUrl = null);
                                      },
                                    )
                                  ],
                                ),
                              ),
                            // Input section
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              color: Colors.amber.shade50.withOpacity(0.3),
                              child: Row(
                                children: [
                                  // Mock attach image trigger
                                  IconButton(
                                    icon: const Icon(Icons.image_outlined, size: 20, color: Colors.blueGrey),
                                    tooltip: 'Attach Image',
                                    onPressed: () {
                                      setState(() {
                                        // Pick a mock image url sequentially
                                        _selectedMockImageUrl = _mockImages[(_internalMessages.length) % _mockImages.length];
                                      });
                                    },
                                  ),
                                  // Approval mode toggle
                                  IconButton(
                                    icon: Icon(
                                      _isApprovalRequestMode ? Icons.verified_user : Icons.verified_user_outlined,
                                      size: 20,
                                      color: _isApprovalRequestMode ? Colors.orange : Colors.grey,
                                    ),
                                    tooltip: 'Approval Request',
                                    onPressed: () {
                                      setState(() {
                                        _isApprovalRequestMode = !_isApprovalRequestMode;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _internalMsgController,
                                      decoration: InputDecoration(
                                        hintText: _isApprovalRequestMode ? 'Ask for approval...' : 'Internal message/note...',
                                        hintStyle: const TextStyle(fontSize: 11),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                      onSubmitted: (_) => _sendInternalMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: AppTheme.primary, size: 18),
                                    onPressed: _sendInternalMessage,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: dialogContent,
      ),
    );
  }

  String _getAvatarUrlForName(String? name) {
    if (name == null || name.isEmpty) {
      return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80';
    }
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('jane') || lowercaseName.contains('smith')) {
      return 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('liam') || lowercaseName.contains('neeson')) {
      return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('sophia') || lowercaseName.contains('loren')) {
      return 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('john') || lowercaseName.contains('doe')) {
      return 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('emma') || lowercaseName.contains('watson')) {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('robert') || lowercaseName.contains('downey')) {
      return 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('alex') || lowercaseName.contains('rivera')) {
      return 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80';
    }
    if (lowercaseName.contains('suresh')) {
      return 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80';
  }

  Widget _buildPeopleDetailsWidget() {
    final raisedBy = _ticket['raised_by'] ?? '';
    final designation = _ticket['designation'] ?? 'Staff';
    final assignedToName = _ticket['assigned_to_name'] ?? 'Unassigned';
    final isUnassigned = assignedToName == 'Unassigned' || _ticket['assigned_to'] == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderGrey),
          bottom: BorderSide(color: AppTheme.borderGrey),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TICKET INVOLVEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Raised By column
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(_getAvatarUrlForName(raisedBy)),
                      backgroundColor: AppTheme.bgLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RAISED BY',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            raisedBy,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            designation,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnassigned) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 36,
                  color: AppTheme.borderGrey,
                ),
                const SizedBox(width: 8),
                // Assigned To column
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(_getAvatarUrlForName(assignedToName)),
                        backgroundColor: AppTheme.bgLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED TO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignedToName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Media Team',
                              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Fallback constant for Image fit parameter
  static const BoxFit crop = BoxFit.cover;
}
