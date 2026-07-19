import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // BUG FIX: Removed the global "EdgeX processing..." overlay pill.
    // The Chat screen's shimmer indicator is the sole canonical loading state.
    // The old overlay caused TWO loading indicators to appear simultaneously.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onTap(context, index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(
                      Icons.chat_bubble,
                      color: Color(0xFF8B5CF6),
                    ),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF8B5CF6),
                    ),
                    label: 'Vision',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(
                      Icons.analytics,
                      color: Color(0xFF8B5CF6),
                    ),
                    label: 'System',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}