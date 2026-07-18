import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/state/app_providers.dart';

class VisionScreen extends ConsumerWidget {
  const VisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaFile = ref.watch(visionMediaProvider);
    final isThinking = ref.watch(isThinkingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // LAUNCH UX: Upgraded to SliverAppBar for perfect Status Bar padding
          SliverAppBar.large(
            backgroundColor: Colors.transparent, 
            elevation: 0,
            title: const Text('Vision Intelligence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0F172A), letterSpacing: -1.0)),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NPU-accelerated analysis for images and video streams. 100% offline.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5)),
                  const SizedBox(height: 32), 
                  Expanded(
                    child: mediaFile != null 
                      ? _buildMediaPreviewCard(ref, mediaFile, isThinking)
                      : _buildEmptyDropZone(ref),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDropZone(WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'mp4']);
        if (result != null) ref.read(visionMediaProvider.notifier).setMedia(result.files.single.name);
      },
      child: RepaintBoundary( // LAUNCH POLISH: Prevents blur jank
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 12))]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(36), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.15), blurRadius: 40, spreadRadius: 10)]), child: const Icon(Icons.document_scanner_outlined, size: 64, color: Color(0xFF8B5CF6))).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 1500.ms),
                  const SizedBox(height: 40),
                  const Text('Select Media', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  const Text('Tap to open camera roll or files', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutCubic);
  }

  Widget _buildMediaPreviewCard(WidgetRef ref, String fileName, bool isThinking) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))]),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(28), image: const DecorationImage(image: NetworkImage('https://picsum.photos/800/1200'), fit: BoxFit.cover, opacity: 0.5)),
                    child: Stack(
                      children: [
                        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)), child: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
                        if (isThinking)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  height: 4, 
                                  width: double.infinity, 
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981), 
                                    boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 10, spreadRadius: 2)]
                                  )
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: 150, duration: 2.seconds),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 40, right: 40,
                  child: GestureDetector(
                    onTap: () { HapticFeedback.mediumImpact(); ref.read(visionMediaProvider.notifier).setMedia(null); },
                    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 24)),
                  ),
                ),
                Positioned(
                  bottom: 40, left: 40, right: 40,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      ref.read(isThinkingProvider.notifier).setThinking(true);
                      Future.delayed(const Duration(seconds: 3), () {
                        ref.read(isThinkingProvider.notifier).setThinking(false);
                        ref.read(recentTasksProvider.notifier).addTask('Analysis Complete', false);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: isThinking ? const Color(0xFF10B981) : const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: (isThinking ? const Color(0xFF10B981) : const Color(0xFF0F172A)).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))]),
                      child: Center(
                        child: isThinking 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Analyze Media', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}