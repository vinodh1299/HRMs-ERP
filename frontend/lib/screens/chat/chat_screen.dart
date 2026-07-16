import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/date_parser_helper.dart';

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatTarget {
  final String name;
  final bool isChannel;
  final bool isOnline;
  final String status;

  ChatTarget({
    required this.name,
    required this.isChannel,
    this.isOnline = false,
    this.status = 'Offline',
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late ChatTarget _activeTarget;
  bool _isTyping = false;

  final List<ChatTarget> _targets = [
    ChatTarget(name: '#general', isChannel: true),
    ChatTarget(name: '#maintenance-updates', isChannel: true),
    ChatTarget(name: '#finance-reimbursements', isChannel: true),
    ChatTarget(name: 'Vinodh', isChannel: false, isOnline: true, status: 'Online'),
    ChatTarget(name: 'John Doe', isChannel: false, isOnline: true, status: 'Online'),
    ChatTarget(name: 'Jane Smith', isChannel: false, isOnline: true, status: 'Away'),
    ChatTarget(name: 'Alice Cooper', isChannel: false, isOnline: false, status: 'Offline'),
  ];

  final Map<String, List<ChatMessage>> _conversations = {
    '#general': [
      ChatMessage(sender: 'HR Team', text: 'Welcome to the new unified HRMS Portal! Have you synced your Microsoft Mail yet?', timestamp: DateTime.now().subtract(const Duration(hours: 5)), isMe: false),
      ChatMessage(sender: 'John Doe', text: 'Yes! Tapping "Sync Microsoft Mail" works immediately.', timestamp: DateTime.now().subtract(const Duration(hours: 4)), isMe: false),
    ],
    '#maintenance-updates': [
      ChatMessage(sender: 'System', text: 'Channel created for maintenance ticket logging and real-time updates.', timestamp: DateTime.now().subtract(const Duration(days: 2)), isMe: false),
    ],
    '#finance-reimbursements': [
      ChatMessage(sender: 'Accounts', text: 'Please upload bills before the 25th of this month.', timestamp: DateTime.now().subtract(const Duration(days: 1)), isMe: false),
    ],
    'Vinodh': [
      ChatMessage(sender: 'Vinodh', text: 'Hey there! How is the new navigation bar layout looking? Our review is on 13 sep 2026.', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), isMe: false),
      ChatMessage(sender: 'Me', text: 'Looking super clean! The More bottom sheet works great.', timestamp: DateTime.now().subtract(const Duration(minutes: 25)), isMe: true),
    ],
    'John Doe': [
      ChatMessage(sender: 'John Doe', text: 'Are we testing the attendance punches today? Let\'s test today afternoon 3pm.', timestamp: DateTime.now().subtract(const Duration(hours: 1)), isMe: false),
    ],
    'Jane Smith': [],
    'Alice Cooper': [],
  };

  @override
  void initState() {
    super.initState();
    _activeTarget = _targets.first;
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      sender: 'Me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _conversations[_activeTarget.name]!.add(newMessage);
      _msgController.clear();
    });

    _scrollToBottom();

    // Simulated auto-response/typing indicator logic
    if (!_activeTarget.isChannel) {
      setState(() {
        _isTyping = true;
      });
      _scrollToBottom();

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _conversations[_activeTarget.name]!.add(
            ChatMessage(
              sender: _activeTarget.name,
              text: 'Thanks for your message! This is a real-time simulated response from ${_activeTarget.name}.',
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        });
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(right: BorderSide(color: AppTheme.borderGrey, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Channels',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          ..._targets.where((t) => t.isChannel).map(_buildTargetTile),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Direct Messages',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: ListView(
              children: _targets.where((t) => !t.isChannel).map(_buildTargetTile).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel({required bool isMobile}) {
    final messages = _conversations[_activeTarget.name] ?? [];
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 1)),
            ),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                CircleAvatar(
                  backgroundColor: _activeTarget.isChannel
                      ? AppTheme.primary.withOpacity(0.12)
                      : (_activeTarget.isOnline ? Colors.green.withOpacity(0.12) : AppTheme.borderGrey),
                  child: Icon(
                    _activeTarget.isChannel ? Icons.tag : Icons.person,
                    color: _activeTarget.isChannel ? AppTheme.primary : Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeTarget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                      ),
                      if (!_activeTarget.isChannel)
                        Text(
                          _activeTarget.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: _activeTarget.status == 'Online' ? Colors.green : AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Message stream window
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          // Input Message area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams Chat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isMobile
          ? _buildLeftPanel()
          : Row(
              children: [
                Expanded(flex: 4, child: _buildLeftPanel()),
                Expanded(flex: 8, child: _buildRightPanel(isMobile: false)),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                msg.sender,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
              ),
              const SizedBox(width: 8),
              Text(
                '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isMe ? AppTheme.primary : AppTheme.bgLight,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: msg.isMe ? const Radius.circular(12) : Radius.zero,
                bottomRight: msg.isMe ? Radius.zero : const Radius.circular(12),
              ),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                return DateParserHelper.buildClickableText(
                  context,
                  ref,
                  msg.text,
                  style: TextStyle(
                    color: msg.isMe ? Colors.white : AppTheme.textDark,
                    fontSize: 13.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '${_activeTarget.name} is typing...',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetTile(ChatTarget target) {
    final isSelected = _activeTarget.name == target.name;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _activeTarget = target;
          });
          if (Responsive.isMobile(context)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: SafeArea(child: _buildRightPanel(isMobile: true)),
                ),
              ),
            );
          }
        },
        dense: true,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: target.isChannel ? AppTheme.primary.withOpacity(0.12) : AppTheme.borderGrey,
              child: Icon(
                target.isChannel ? Icons.tag : Icons.person,
                size: 16,
                color: target.isChannel ? AppTheme.primary : AppTheme.textDark,
              ),
            ),
            if (!target.isChannel)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: target.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          target.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.textDark,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
