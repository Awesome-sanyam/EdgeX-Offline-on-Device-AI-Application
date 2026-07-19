import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

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
        color: EdgeXTheme.background,
        // Optional: very subtle gradient mesh if you don't want solid color
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            Color(0xFF1E293B), // Slightly lighter top right
            EdgeXTheme.background,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: EdgeXTheme.background.withValues(alpha: 0.7),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onTap(context, index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: EdgeXTheme.cyanAccent.withValues(alpha: 0.15),
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline, color: EdgeXTheme.textSecondary),
                    selectedIcon: Icon(Icons.chat_bubble, color: EdgeXTheme.cyanAccent),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined, color: EdgeXTheme.textSecondary),
                    selectedIcon: Icon(Icons.auto_awesome, color: EdgeXTheme.cyanAccent),
                    label: 'Vision',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined, color: EdgeXTheme.textSecondary),
                    selectedIcon: Icon(Icons.analytics, color: EdgeXTheme.cyanAccent),
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