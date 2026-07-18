import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/state/app_providers.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThinking = ref.watch(isThinkingProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF), Color(0xFFCFFAFE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            navigationShell,
            if (isThinking)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 0, right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), border: Border.all(color: Colors.white24)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))),
                            const SizedBox(width: 12),
                            const Text('loc.ai processing...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: -1.0, end: 0, curve: Curves.easeOutBack),
                ),
              ),
          ],
        ),
        bottomNavigationBar: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5)))),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onTap(context, index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF8B5CF6)), label: 'Chat'),
                  NavigationDestination(icon: Icon(Icons.image_search), selectedIcon: Icon(Icons.image_search, color: Color(0xFF8B5CF6)), label: 'Vision'),
                  NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics, color: Color(0xFF8B5CF6)), label: 'System'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}