import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

// ─────────────────────────────────────────────────
// DOCUMENT VIEWER SCREEN
// A functional PDF context screen wired to chatProvider
// ─────────────────────────────────────────────────
class DocumentScreen extends ConsumerStatefulWidget {
  final String filePath;
  const DocumentScreen({super.key, required this.filePath});

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  String get _fileName => widget.filePath.split('/').last;

  @override
  void initState() {
    super.initState();
    // Wire the attachment into the chat provider on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatAttachmentProvider.notifier).setAttachment(widget.filePath);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _askQuestion() {
    final text = _queryController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendMessage(text, widget.filePath);
    _queryController.clear();
    // Navigate back to chat
    context.go('/chat');
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = ref.watch(isThinkingProvider);

    return Scaffold(
      backgroundColor: EdgeXTheme.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: EdgeXTheme.background.withValues(alpha: 0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: EdgeXTheme.textPrimary),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(chatAttachmentProvider.notifier).setAttachment(null);
                  context.pop();
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document',
                    style: TextStyle(
                      color: EdgeXTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EdgeXTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EdgeXTheme.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file_rounded, size: 12, color: EdgeXTheme.cyanAccent),
                      SizedBox(width: 4),
                      Text('PDF', style: TextStyle(color: EdgeXTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _contentScrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: EdgeXTheme.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: EdgeXTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, size: 28, color: EdgeXTheme.errorRed),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: EdgeXTheme.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getFileSize(),
                                style: const TextStyle(
                                  color: EdgeXTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Instruction card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EdgeXTheme.cyanAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: EdgeXTheme.cyanAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The AI will read the full content of this document. '
                            'Ask any question and it will answer based on the document.',
                            style: TextStyle(
                              color: EdgeXTheme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 28),

                  // Suggested questions
                  const Text(
                    'SUGGESTED QUESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: EdgeXTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSuggestedQuestions(),
                ],
              ),
            ),
          ),

          // Input area
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: EdgeXTheme.surface,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      decoration: BoxDecoration(
                        color: EdgeXTheme.surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _queryController,
                        maxLines: null,
                        style: const TextStyle(color: EdgeXTheme.textPrimary, fontSize: 15, height: 1.4),
                        decoration: const InputDecoration(
                          hintText: 'Ask about this document...',
                          hintStyle: TextStyle(color: EdgeXTheme.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _askQuestion(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _askQuestion,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isThinking
                            ? null
                            : const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                        color: isThinking ? EdgeXTheme.surface2 : null,
                        shape: BoxShape.circle,
                        boxShadow: isThinking
                            ? null
                            : [const BoxShadow(color: EdgeXTheme.purpleGlow, blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: isThinking
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: EdgeXTheme.cyanAccent),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSize() {
    try {
      final file = File(widget.filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } catch (_) {
      return 'PDF Document';
    }
  }

  List<Widget> _buildSuggestedQuestions() {
    final questions = [
      'Summarize this document in 3 key points',
      'What are the main conclusions?',
      'Extract all action items or tasks',
      'What is the most important section?',
    ];

    return questions.asMap().entries.map((e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _queryController.text = e.value;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: EdgeXTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: EdgeXTheme.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      color: EdgeXTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: EdgeXTheme.textMuted),
              ],
            ),
          ),
        ),
      ).animate(delay: (60 * e.key).ms).fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
    }).toList();
  }
}