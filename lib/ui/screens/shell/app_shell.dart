import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

class AppShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isThinking = ref.watch(isThinkingProvider);
    final currentIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        gradient: EdgeXTheme.shellBackground,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: _EdgeXNavBar(
          currentIndex: currentIndex,
          isThinking: isThinking,
          onTap: (i) => _onTap(context, i),
        ),
      ),
    );
  }
}

class _EdgeXNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isThinking;
  final ValueChanged<int> onTap;

  const _EdgeXNavBar({
    required this.currentIndex,
    required this.isThinking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: EdgeXTheme.background.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: safeBottom),
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
                onTap: onTap,
                showThinkingRing: isThinking && currentIndex == 0,
                accentColor: EdgeXTheme.cyanAccent,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: 'Vision',
                onTap: onTap,
                accentColor: EdgeXTheme.purpleAccent,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
                label: 'System',
                onTap: onTap,
                accentColor: EdgeXTheme.emeraldAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;
  final Color accentColor;
  final bool showThinkingRing;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.accentColor,
    this.showThinkingRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thinking ring — pulses when AI is generating on Chat tab
                    if (showThinkingRing)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: EdgeXTheme.cyanAccent.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scaleXY(end: 1.4, duration: 1200.ms, curve: Curves.easeOut)
                          .fadeOut(begin: 1.0, duration: 1200.ms),

                    // Indicator pill behind icon when active
                    if (isActive)
                      Container(
                        width: 40,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.8, end: 1.0),

                    Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? accentColor : EdgeXTheme.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? accentColor : EdgeXTheme.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}