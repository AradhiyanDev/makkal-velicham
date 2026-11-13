import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/bookmarks/presentation/pages/bookmarks_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/news/presentation/widgets/notification_permission_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isNavVisible = false;
  Timer? _autoHideTimer;

  late final List<Widget> _pages = const [
    NewsPage(),
    ExplorePage(),
    BookmarksPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          NotificationPermissionDialog.checkAndShow(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _showNav() {
    if (_isNavVisible) {
      // reset auto-hide timer
      _scheduleAutoHide();
      return;
    }
    setState(() => _isNavVisible = true);
    _scheduleAutoHide();
  }

  void _hideNav() {
    if (!_isNavVisible) return;
    _autoHideTimer?.cancel();
    setState(() => _isNavVisible = false);
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _isNavVisible = false);
      }
    });
  }

  void _onTap() => _showNav();

  void _onPointerMove(PointerMoveEvent _) {
    // any drag/scroll immediately hides the bar
    if (_isNavVisible) _hideNav();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No persistent bottomNavigationBar — we animate it in Stack
      body: Listener(
        onPointerMove: _onPointerMove,
        // Use NotificationListener to also catch scrollables
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification && n.dragDetails != null) {
              _hideNav();
            }
            return false;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _onTap,
            child: Stack(
              children: [
                IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
                // Animated bottom bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSlide(
                    offset: _isNavVisible ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _isNavVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: NavigationBar(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (i) {
                          setState(() => _currentIndex = i);
                          _showNav(); // keep visible briefly after tab switch
                        },
                        height: 68,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home_rounded),
                            label: 'Home',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.explore_outlined),
                            selectedIcon: Icon(Icons.explore_rounded),
                            label: 'Explore',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.bookmark_border_rounded),
                            selectedIcon: Icon(Icons.bookmark_rounded),
                            label: 'Saved',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.person_outline_rounded),
                            selectedIcon: Icon(Icons.person_rounded),
                            label: 'Profile',
                          ),
                        ],
                      ),
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
