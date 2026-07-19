import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VisionScreen extends StatelessWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Vision',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero badge
                _ComingSoonBadge()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 32),

                // Hero description
                const Text(
                  'NPU-accelerated visual intelligence — analyze images, scan documents, and understand scenes entirely on-device.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 40),

                // Feature cards
                _FeatureCard(
                  icon: Icons.document_scanner_outlined,
                  title: 'OCR Document Scanner',
                  subtitle:
                      'Extract text from PDFs, receipts, and handwritten notes with neural precision.',
                  statusLabel: 'Q3 2025',
                  gradientColors: const [
                    Color(0xFF8B5CF6),
                    Color(0xFFA78BFA),
                  ],
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 16),

                _FeatureCard(
                  icon: Icons.image_search_outlined,
                  title: 'Scene Understanding',
                  subtitle:
                      'Describe, classify, and reason about photos and images using a local vision model.',
                  statusLabel: 'Q4 2025',
                  gradientColors: const [
                    Color(0xFF0EA5E9),
                    Color(0xFF38BDF8),
                  ],
                ).animate(delay: 220.ms).fadeIn(duration: 400.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 16),

                _FeatureCard(
                  icon: Icons.center_focus_strong_outlined,
                  title: 'Real-Time Object Detection',
                  subtitle:
                      'Live camera feed analysis using a lightweight MobileNet model. Zero cloud latency.',
                  statusLabel: '2026',
                  gradientColors: const [
                    Color(0xFF10B981),
                    Color(0xFF34D399),
                  ],
                ).animate(delay: 290.ms).fadeIn(duration: 400.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
                const SizedBox(height: 40),

                // Bottom info card
                _InfoCard()
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                const Color(0xFF6366F1).withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Color(0xFF8B5CF6),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.06, duration: 2000.ms, curve: Curves.easeInOut),
              const SizedBox(height: 24),
              const Text(
                'Vision Intelligence',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 800.ms),
                    const SizedBox(width: 8),
                    const Text(
                      'In Development',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusLabel;
  final List<Color> gradientColors;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '100% Private by Design',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Vision processing will run entirely on-device. No images ever leave your phone.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}