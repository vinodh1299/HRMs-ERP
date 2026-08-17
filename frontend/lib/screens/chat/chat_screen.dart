import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/date_parser_helper.dart';
import '../../services/chat_service.dart';
import '../../services/voice_helper.dart';

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
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _activeTarget = ChatService.targets.first;
    ChatService.messageNotifier.addListener(_onMessagesUpdated);
  }

  @override
  void dispose() {
    ChatService.messageNotifier.removeListener(_onMessagesUpdated);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final newMessage = TeamChatMessage(
      sender: 'Me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      ChatService.addMessage(_activeTarget.name, newMessage);
      _msgController.clear();
    });

    _scrollToBottom();

    if (_activeTarget.name == 'Gemini AI Assistant') {
      setState(() {
        _isTyping = true;
      });
      _scrollToBottom();

      Future.microtask(() async {
        final assistantReply = await ChatService.processAiPrompt(text);
        if (!mounted) return;

        setState(() {
          _isTyping = false;
          ChatService.addMessage(
            'Gemini AI Assistant',
            TeamChatMessage(
              sender: 'Gemini AI Assistant',
              text: assistantReply,
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        });
        VoiceHelper.speak(assistantReply);
        _scrollToBottom();
      });
    } else if (!_activeTarget.isChannel) {
      setState(() {
        _isTyping = true;
      });
      _scrollToBottom();

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          ChatService.addMessage(
            _activeTarget.name,
            TeamChatMessage(
              sender: _activeTarget.name,
              text: 'Thanks for reaching out! I will check and get back to you shortly.',
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        });
        _scrollToBottom();
      });
    }
  }

  void _toggleVoiceRecording() {
    if (_isListening) {
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listening... speak now!'), duration: Duration(seconds: 2)),
    );

    VoiceHelper.startRecognition(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _msgController.text = text;
        });
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $err')),
        );
      },
      onEnd: () {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final messages = ChatService.getMessages(_activeTarget.name);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Teams Chat', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 1,
        ),
        body: _buildLeftPanel(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Row(
        children: [
          // Left sidebar panel (channels & DMs)
          SizedBox(
            width: 280,
            child: _buildLeftPanel(),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderGrey),
          // Main Chat panel
          Expanded(
            child: _buildRightPanel(messages: messages),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'My Teams Chat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Channels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                ),
                ...ChatService.targets.where((t) => t.isChannel).map((t) => _buildTargetTile(t)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Direct Messages', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                ),
                ...ChatService.targets.where((t) => !t.isChannel).map((t) => _buildTargetTile(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel({required List<TeamChatMessage> messages, bool isMobile = false}) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 1)),
          ),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              CircleAvatar(
                radius: 18,
                backgroundColor: _activeTarget.name == 'Gemini AI Assistant'
                    ? AppTheme.secondary.withValues(alpha: 0.15)
                    : AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  _activeTarget.isChannel
                      ? Icons.tag
                      : (_activeTarget.name == 'Gemini AI Assistant' ? Icons.psychology : Icons.person),
                  color: _activeTarget.name == 'Gemini AI Assistant'
                      ? AppTheme.secondary
                      : AppTheme.primary,
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
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderGrey, width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_outlined,
                  color: _isListening ? Colors.red : AppTheme.textMuted,
                ),
                tooltip: 'Voice Input',
                onPressed: _toggleVoiceRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }

  Widget _buildMessageBubble(TeamChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: msg.isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: msg.isMe ? null : Border.all(color: AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMe) ...[
              Text(
                msg.sender,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : AppTheme.textDark,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!msg.isMe)
                  InkWell(
                    onTap: () => VoiceHelper.speak(msg.text),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: const [
                          Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('Listen', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  DateParserHelper.formatTime(msg.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: msg.isMe ? Colors.white70 : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              '${_activeTarget.name} is typing...',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTile(ChatTarget target) {
    final isSelected = _activeTarget.name == target.name;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        onTap: () {
          setState(() {
            _activeTarget = target;
          });
          if (Responsive.isMobile(context)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: SafeArea(
                    child: _buildRightPanel(messages: ChatService.getMessages(target.name), isMobile: true),
                  ),
                ),
              ),
            );
          }
        },
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: target.name == 'Gemini AI Assistant'
              ? AppTheme.secondary.withValues(alpha: 0.15)
              : AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(
            target.isChannel
                ? Icons.tag
                : (target.name == 'Gemini AI Assistant' ? Icons.psychology : Icons.person),
            color: target.name == 'Gemini AI Assistant'
                ? AppTheme.secondary
                : AppTheme.primary,
            size: 14,
          ),
        ),
        title: Text(
          target.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.textDark,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
