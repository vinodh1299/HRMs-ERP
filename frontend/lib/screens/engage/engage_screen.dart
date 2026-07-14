import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class EngageScreen extends StatefulWidget {
  const EngageScreen({super.key});

  @override
  State<EngageScreen> createState() => _EngageScreenState();
}

class _EngageScreenState extends State<EngageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _polls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final ann = await _apiService.getAnnouncements();
      final pl = await _apiService.getPolls();
      if (mounted) {
        setState(() {
          _announcements = ann;
          _polls = pl;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
              Tab(text: 'Announcements'),
              Tab(text: 'Polls'),
              Tab(text: 'Articles'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnnouncementsTab(),
                _buildPollsTab(),
                _buildArticlesTab(),
              ],
            ),
    );
  }

  Widget _buildAnnouncementsTab() {
    if (_announcements.isEmpty) {
      return const Center(child: Text('No announcements found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final a = _announcements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        a['category']?.toUpperCase() ?? 'GENERAL',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Text(a['published_at']?.split('T')[0] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text(a['content'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, color: AppTheme.primary, size: 18),
                    SizedBox(width: 4),
                    Text('12 Likes', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.comment_outlined, color: AppTheme.primary, size: 18),
                    SizedBox(width: 4),
                    Text('2 Comments', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollsTab() {
    if (_polls.isEmpty) {
      return const Center(child: Text('No active polls.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _polls.length,
      itemBuilder: (context, index) {
        final p = _polls[index];
        final List options = p['options'] ?? [];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.poll, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Live Survey', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(p['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vote casted!')));
                      },
                      child: Text(opt.toString()),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticlesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chrome_reader_mode_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Knowledge Base & Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Publish internal wikis, policy directories, and employee guidebooks. Stub is configured.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
