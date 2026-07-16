import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../core/date_parser_helper.dart';

class EmailMessage {
  final String id;
  final String sender;
  final String senderEmail;
  final String subject;
  final String snippet;
  final String body;
  final DateTime date;
  final bool isUnread;

  EmailMessage({
    required this.id,
    required this.sender,
    required this.senderEmail,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.date,
    this.isUnread = false,
  });
}

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  String _selectedFolder = 'Inbox';
  EmailMessage? _selectedEmail;
  final List<EmailMessage> _emails = [
    EmailMessage(
      id: '1',
      sender: 'Microsoft Entra',
      senderEmail: 'entra-noreply@microsoft.com',
      subject: 'Security Alert: New Sign-in Detected',
      snippet: 'A new sign-in was detected on your account from device Mac-Studio.',
      body: 'Hi Vinodh,\n\nWe detected a successful sign-in to your Microsoft Entra account from a new location or device.\n\nDevice: Mac Studio\nIP Address: 192.168.1.45\nTime: July 16, 2026 9:15 AM IST\n\nIf this was you, you do not need to take any action. If this was not you, please secure your account immediately.',
      date: DateTime.now().subtract(const Duration(minutes: 15)),
      isUnread: true,
    ),
    EmailMessage(
      id: '2',
      sender: 'John Doe (Media)',
      senderEmail: 'john.doe@acaindia.org',
      subject: 'Updated Video Stream Guidelines for Sunday',
      snippet: 'Please review the updated guidelines for streaming setup.',
      body: 'Hi Team,\n\nI have updated the Sunday stream configurations in the console. Please ensure the audio bitrate is locked to 192kbps and the camera feeds are balanced.\n\nOur next stream testing will happen on 13 sep 2026. Please prepare.\n\nBest regards,\nJohn',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isUnread: true,
    ),
    EmailMessage(
      id: '3',
      sender: 'HR Team',
      senderEmail: 'hr@acaindia.org',
      subject: 'Holiday Calendar 2026 Updates',
      snippet: 'The holiday schedule has been adjusted for the upcoming quarter.',
      body: 'Dear Employees,\n\nPlease find attached the revised holiday calendar for Q3 2026. The regional holiday for mid-August has been approved.\n\nThe annual day rehearsals start on 12 august. The setup planning begins tomorrow morning 10AM.\n\nYou can also check the upcoming holidays directly on your Portal Dashboard home page.\n\nWarm regards,\nHR Department',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (_emails.isNotEmpty) {
      _selectedEmail = _emails.first;
    }
  }

  void _composeNewEmail() {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.rate_review_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('New Email Message'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: toController,
                  decoration: const InputDecoration(
                    labelText: 'To (Recipient Email)',
                    hintText: 'e.g. colleague@acaindia.org or guest@gmail.com',
                    prefixIcon: Icon(Icons.alternate_email, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.title, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Compose Email',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (toController.text.isEmpty || subjectController.text.isEmpty) return;
                setState(() {
                  _emails.insert(
                    0,
                    EmailMessage(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      sender: 'Me',
                      senderEmail: 'vinodh@acaindia.org',
                      subject: subjectController.text,
                      snippet: bodyController.text.length > 60
                          ? '${bodyController.text.substring(0, 60)}...'
                          : bodyController.text,
                      body: bodyController.text,
                      date: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email Sent successfully via Microsoft SMTP simulation'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Send Mail', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    // Sidebar Folders Panel
    Widget foldersWidget() {
      return Container(
        color: AppTheme.bgLight,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _buildFolderItem('Inbox', Icons.inbox_outlined, unreadCount: _emails.where((e) => e.isUnread).length),
            _buildFolderItem('Sent Items', Icons.send_outlined),
            _buildFolderItem('Drafts', Icons.note_add_outlined),
            _buildFolderItem('Archive', Icons.archive_outlined),
            _buildFolderItem('Trash', Icons.delete_outline),
          ],
        ),
      );
    }

    // Email List Panel
    Widget emailListWidget() {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: AppTheme.borderGrey, width: 1)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search mail...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderGrey),
            Expanded(
              child: ListView.separated(
                itemCount: _emails.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderGrey),
                itemBuilder: (context, index) {
                  final email = _emails[index];
                  final isSelected = _selectedEmail?.id == email.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEmail = email;
                      });
                      if (isMobile) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Email Details'),
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              body: _buildEmailDetailBody(email),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      color: isSelected ? AppTheme.primary.withOpacity(0.06) : Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  email.sender,
                                  style: TextStyle(
                                    fontWeight: email.isUnread ? FontWeight.bold : FontWeight.w600,
                                    color: AppTheme.textDark,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${email.date.hour}:${email.date.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.subject,
                            style: TextStyle(
                              fontWeight: email.isUnread ? FontWeight.bold : FontWeight.normal,
                              color: AppTheme.textDark,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.snippet,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            maxLines: 2,
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workspace Mail', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppTheme.primary),
            tooltip: 'Sync Microsoft Mail',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synced successfully with Microsoft Entra ID'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined, color: AppTheme.primary),
            tooltip: 'New Email',
            onPressed: _composeNewEmail,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile
          ? emailListWidget()
          : Row(
              children: [
                // Folders panel
                Expanded(flex: 2, child: foldersWidget()),
                // Email items panel
                Expanded(flex: 4, child: emailListWidget()),
                // Email view details panel
                Expanded(
                  flex: 6,
                  child: _selectedEmail == null
                      ? const Center(child: Text('Select an email to view detail.'))
                      : _buildEmailDetailBody(_selectedEmail!),
                ),
              ],
            ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _composeNewEmail,
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.rate_review, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmailDetailBody(EmailMessage email) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(email.sender[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.sender,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark),
                    ),
                    Text(
                      email.senderEmail,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${email.date.day}/${email.date.month} ${email.date.hour}:${email.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppTheme.borderGrey),
          const SizedBox(height: 18),
          Text(
            email.subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, child) {
                  return DateParserHelper.buildClickableText(
                    context,
                    ref,
                    email.body,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.5),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(String title, IconData icon, {int? unreadCount}) {
    final isSelected = _selectedFolder == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedFolder = title;
          });
        },
        dense: true,
        leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.textDark,
            fontSize: 13,
          ),
        ),
        trailing: unreadCount != null && unreadCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }
}
