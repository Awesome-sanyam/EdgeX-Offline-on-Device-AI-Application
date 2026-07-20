import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

// ─────────────────────────────────────────────────
// VISION SCREEN — Functional Multimodal Interface
// ─────────────────────────────────────────────────
class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  String? _selectedImagePath;
  bool _isAnalysing = false;
  String? _analysisResult;

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImagePath = result.files.single.path;
        _analysisResult = null;
        _isAnalysing = false;
      });
    }
  }

  Future<void> _analyseImage() async {
    if (_selectedImagePath == null) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isAnalysing = true;
      _analysisResult = null;
    });

    // Prepare a multimodal prompt describing the image
    final fileName = _selectedImagePath!.split('/').last;
    final prompt =
        'I am sending you an image named "$fileName". Describe what you see in detail: '
        'identify objects, colors, context, and any text visible. Then provide useful '
        'insights about this image.';

    // Wire into the chat provider which handles the model inference
    ref.read(chatProvider.notifier).sendMessage(prompt, _selectedImagePath);
    ref.read(visionMediaProvider.notifier).setMedia(fileName);

    // Listen for the result — when thinking stops, pull last AI message
    ref.listenManual(isThinkingProvider, (prev, next) {
      if (prev == true && next == false) {
        final chat = ref.read(chatProvider);
        if (chat.isNotEmpty && !chat.last.isUser) {
          if (mounted) {
            setState(() {
              _isAnalysing = false;
              _analysisResult = chat.last.text;
            });
            HapticFeedback.heavyImpact();
          }
        }
      }
    });
  }

  void _sendToChat() {
    if (_selectedImagePath == null) return;
    HapticFeedback.selectionClick();
    ref.read(chatAttachmentProvider.notifier).setAttachment(_selectedImagePath);
    context.go('/chat');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image attached to chat — ask your question!'),
        backgroundColor: EdgeXTheme.emeraldAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = ref.watch(isThinkingProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Vision',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: EdgeXTheme.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: EdgeXTheme.purpleAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EdgeXTheme.purpleAccent.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: EdgeXTheme.purpleAccent),
                        SizedBox(width: 8),
                        Text(
                          'Image never leaves your device',
                          style: TextStyle(
                            color: EdgeXTheme.purpleAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Image area
                  if (_selectedImagePath == null)
                    _ImagePickerCard(onTap: _pickImage)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.1, end: 0)
                  else ...[
                    _ImagePreview(
                      imagePath: _selectedImagePath!,
                      onClear: () => setState(() {
                        _selectedImagePath = null;
                        _analysisResult = null;
                        _isAnalysing = false;
                      }),
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 16),
                    _ActionButtonsRow(
                      isAnalysing: _isAnalysing || isThinking,
                      onAnalyse: _analyseImage,
                      onSendToChat: _sendToChat,
                    ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                  ],

                  // Analysis result
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 24),
                    _AnalysisResultCard(result: _analysisResult!)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],

                  // Loading state
                  if (_isAnalysing || isThinking) ...[
                    const SizedBox(height: 24),
                    _AnalysingCard()
                        .animate()
                        .fadeIn(duration: 300.ms),
                  ],

                  const SizedBox(height: 40),

                  // Capabilities section
                  if (_selectedImagePath == null) _CapabilitiesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── IMAGE PICKER CARD ───
class _ImagePickerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ImagePickerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          color: EdgeXTheme.surface2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: EdgeXTheme.purpleAccent.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EdgeXTheme.purpleAccent.withValues(alpha: 0.08),
                border: Border.all(color: EdgeXTheme.purpleAccent.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded, size: 40, color: EdgeXTheme.purpleAccent),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.05, duration: 2000.ms, curve: Curves.easeInOut),
            const SizedBox(height: 20),
            const Text(
              'Add Image',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EdgeXTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'JPG, PNG, HEIC — 100% private',
              style: TextStyle(fontSize: 13, color: EdgeXTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── IMAGE PREVIEW ───
class _ImagePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onClear;

  const _ImagePreview({required this.imagePath, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EdgeXTheme.purpleAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: EdgeXTheme.purpleAccent.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),
          // Dark gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ),
          // Clear button
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onClear,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ACTION BUTTONS ───
class _ActionButtonsRow extends StatelessWidget {
  final bool isAnalysing;
  final VoidCallback onAnalyse;
  final VoidCallback onSendToChat;

  const _ActionButtonsRow({
    required this.isAnalysing,
    required this.onAnalyse,
    required this.onSendToChat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _PrimaryButton(
            icon: isAnalysing ? null : Icons.auto_awesome_rounded,
            label: isAnalysing ? 'Analysing...' : 'Analyse Image',
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            ),
            isLoading: isAnalysing,
            onTap: isAnalysing ? null : onAnalyse,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _PrimaryButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Send to Chat',
            gradient: LinearGradient(
              colors: [EdgeXTheme.surface2, EdgeXTheme.surfaceHighlight],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            onTap: onSendToChat,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final LinearGradient gradient;
  final Border? border;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.gradient,
    this.border,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: onTap != null && !isLoading
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 16, color: Colors.white),
              if (icon != null || isLoading) const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ANALYSIS RESULT ───
class _AnalysisResultCard extends StatelessWidget {
  final String result;
  const _AnalysisResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EdgeXTheme.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EdgeXTheme.emeraldAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: EdgeXTheme.emeraldAccent.withValues(alpha: 0.06), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EdgeXTheme.emeraldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 14, color: EdgeXTheme.emeraldAccent),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Analysis',
                style: TextStyle(fontWeight: FontWeight.w800, color: EdgeXTheme.emeraldAccent, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: result));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Analysis copied'),
                    backgroundColor: EdgeXTheme.emeraldAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: const Icon(Icons.content_copy_rounded, size: 16, color: EdgeXTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result,
            style: const TextStyle(
              color: EdgeXTheme.textPrimary,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ANALYSING LOADING CARD ───
class _AnalysingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EdgeXTheme.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EdgeXTheme.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: EdgeXTheme.purpleAccent),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Analysing image...', style: TextStyle(fontWeight: FontWeight.w700, color: EdgeXTheme.textPrimary)),
              SizedBox(height: 2),
              Text('Neural network processing', style: TextStyle(color: EdgeXTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CAPABILITIES ───
class _CapabilitiesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final caps = [
      {'icon': Icons.search_rounded, 'title': 'Object Detection', 'desc': 'Identifies objects, people, and scenes with precision'},
      {'icon': Icons.text_snippet_outlined, 'title': 'OCR & Text Extraction', 'desc': 'Reads and transcribes text from images or documents'},
      {'icon': Icons.palette_outlined, 'title': 'Color & Style Analysis', 'desc': 'Describes colours, artistic styles, and compositions'},
      {'icon': Icons.send_rounded, 'title': 'Chat Integration', 'desc': 'Send any image as context directly into the AI chat'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CAPABILITIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: EdgeXTheme.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...caps.asMap().entries.map((e) {
          final cap = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EdgeXTheme.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EdgeXTheme.purpleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cap['icon'] as IconData, size: 18, color: EdgeXTheme.purpleAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cap['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: EdgeXTheme.textPrimary, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(cap['desc'] as String,
                          style: const TextStyle(color: EdgeXTheme.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (80 * e.key).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
        }),
      ],
    );
  }
}