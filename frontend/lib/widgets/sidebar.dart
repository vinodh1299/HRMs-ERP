import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String path;

  const NavItem({
    required this.title,
    required this.icon,
    required this.path,
  });
}

class NavigationShell extends ConsumerWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  static const List<NavItem> _navItems = [
    NavItem(title: 'Home', icon: Icons.home_outlined, path: '/'),
    NavItem(title: 'Me', icon: Icons.person_outline, path: '/me'),
    NavItem(title: 'Inbox', icon: Icons.inbox_outlined, path: '/inbox'),
    NavItem(title: 'My Team', icon: Icons.people_outline, path: '/myteam'),
    NavItem(title: 'My Finances', icon: Icons.account_balance_wallet_outlined, path: '/myfinances'),
    NavItem(title: 'Org', icon: Icons.corporate_fare_outlined, path: '/org'),
    NavItem(title: 'Engage', icon: Icons.campaign_outlined, path: '/engage'),
    NavItem(title: 'Helpdesk', icon: Icons.help_outline, path: '/helpdesk'),
  ];

  static const List<NavItem> _stubItems = [
    NavItem(title: 'Performance', icon: Icons.speed, path: '/stubs/performance'),
    NavItem(title: 'Recruitment', icon: Icons.work_outline, path: '/stubs/recruitment'),
    NavItem(title: 'Expenses', icon: Icons.receipt_long_outlined, path: '/stubs/expenses'),
    NavItem(title: 'Assets', icon: Icons.devices, path: '/stubs/assets'),
    NavItem(title: 'Reports', icon: Icons.bar_chart_outlined, path: '/stubs/reports'),
  ];

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    // Exact matching for main items
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path || location.startsWith('${_navItems[i].path}/')) {
        return i;
      }
    }
    
    // For stub items, return a negative index or map if needed
    for (int i = 0; i < _stubItems.length; i++) {
      if (location == _stubItems[i].path) {
        return _navItems.length + i;
      }
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index < _navItems.length) {
      context.go(_navItems[index].path);
    } else {
      final stubIndex = index - _navItems.length;
      context.go(_stubItems[stubIndex].path);
    }
  }

  int _getMobileSelectedIndex(String location) {
    if (location == '/' || location.startsWith('/stubs/dashboard')) return 0;
    if (location.startsWith('/me')) return 1;
    if (location.startsWith('/inbox')) return 2;
    if (location.startsWith('/helpdesk')) return 3;
    return 4; // 'More'
  }

  void _onMobileItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/me');
        break;
      case 2:
        context.go('/inbox');
        break;
      case 3:
        context.go('/helpdesk');
        break;
      case 4:
        _showMobileMoreSheet(context);
        break;
    }
  }

  void _showMobileMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar indicator
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'More Modules',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _buildMoreGridItem(context, 'My Team', Icons.people_outline, Colors.orange, '/myteam'),
                    _buildMoreGridItem(context, 'Finances', Icons.account_balance_wallet_outlined, Colors.green, '/myfinances'),
                    _buildMoreGridItem(context, 'Org', Icons.corporate_fare_outlined, AppTheme.primary, '/org'),
                    _buildMoreGridItem(context, 'Engage', Icons.campaign_outlined, AppTheme.secondary, '/engage'),
                    _buildMoreGridItem(context, 'Performance', Icons.speed, Colors.teal, '/stubs/performance'),
                    _buildMoreGridItem(context, 'Recruitment', Icons.work_outline, Colors.blue, '/stubs/recruitment'),
                    _buildMoreGridItem(context, 'Expenses', Icons.receipt_long_outlined, Colors.purple, '/stubs/expenses'),
                    _buildMoreGridItem(context, 'Assets', Icons.devices, Colors.indigo, '/stubs/assets'),
                    _buildMoreGridItem(context, 'Reports', Icons.bar_chart_outlined, Colors.red, '/stubs/reports'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreGridItem(BuildContext context, String title, IconData icon, Color color, String path) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close sheet
          context.go(path); // Navigate
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.12), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Top Header bar containing Profile Avatar & Org Info
    final AppBar appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 1)),
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderGrey, width: 1),
            ),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Text(
            'Asian Christian Academy',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                onPressed: () {},
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textMuted, size: 18),
                onPressed: () {},
              ),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') ref.read(authProvider.notifier).logout();
            },
            offset: const Offset(0, 44),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white24,
                  child: Text('V', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
              ]),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      final location = GoRouterState.of(context).matchedLocation;
      final mobileSelectedIndex = _getMobileSelectedIndex(location);

      return Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          currentIndex: mobileSelectedIndex,
          onTap: (index) => _onMobileItemTapped(context, index),
          selectedLabelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10.5),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Me',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outline),
              activeIcon: Icon(Icons.help),
              label: 'Helpdesk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            Container(
              color: AppTheme.sidebarBg,
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIconTheme: const IconThemeData(color: AppTheme.sidebarSelected),
                unselectedIconTheme: IconThemeData(color: AppTheme.sidebarText.withOpacity(0.5)),
                selectedLabelTextStyle: const TextStyle(color: AppTheme.sidebarSelected, fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelTextStyle: TextStyle(color: AppTheme.sidebarText.withOpacity(0.6), fontSize: 12),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  ..._navItems.map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.title),
                      )),
                  ..._stubItems.map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.title),
                      )),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(context, index),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderGrey),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Desktop: Left Sidebar — dark navy
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: appBar,
      body: Row(
        children: [
          Container(
            width: 235,
            decoration: const BoxDecoration(
              gradient: AppTheme.navGradient,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'CORE MODULES',
                          style: TextStyle(
                            color: AppTheme.sidebarText.withOpacity(0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      ...List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isSelected = selectedIndex == index;
                        return _buildSidebarButton(context, item, isSelected, () => _onItemTapped(context, index));
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'OTHER MODULES',
                          style: TextStyle(
                            color: AppTheme.sidebarText.withOpacity(0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      ...List.generate(_stubItems.length, (index) {
                        final item = _stubItems[index];
                        final globalIndex = _navItems.length + index;
                        final isSelected = selectedIndex == globalIndex;
                        return _buildSidebarButton(context, item, isSelected, () => _onItemTapped(context, globalIndex));
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: AppTheme.bgLight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(BuildContext context, NavItem item, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: Colors.white.withOpacity(0.10), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.06),
          splashColor: Colors.white.withOpacity(0.08),
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                // Selected indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: isSelected ? 22 : 0,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sidebarSelected,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.sidebarSelected.withOpacity(0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  item.icon,
                  color: isSelected
                      ? AppTheme.sidebarSelected
                      : AppTheme.sidebarText.withOpacity(0.55),
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.sidebarText.withOpacity(0.70),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
