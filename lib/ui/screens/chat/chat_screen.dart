import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/state/app_providers.dart';
import '../../core/theme.dart';

// ─────────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasInput = false;
  late String _currentQuote;

  static const List<String> _welcomeQuotes = [
    'Your local intelligence is ready.\nWhat shall we build today?',
    'Offline, secure, and private.\nHow can I assist you?',
    'Neural Engine engaged.\nReady for your commands.',
  ];

  static const List<Map<String, dynamic>> _quickPrompts = [
    {'icon': Icons.code_rounded, 'text': 'Write a Python function to sort a list'},
    {'icon': Icons.lightbulb_outline_rounded, 'text': 'Explain quantum computing simply'},
    {'icon': Icons.edit_note_rounded, 'text': 'Help me draft a professional email'},
  ];

  @override
  void initState() {
    super.initState();
    _currentQuote = _welcomeQuotes[Random().nextInt(_welcomeQuotes.length)];
    _textController.addListener(() {
      final hasInput = _textController.text.trim().isNotEmpty;
      if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning.';
    if (hour >= 12 && hour < 17) return 'Good Afternoon.';
    if (hour >= 17 && hour < 22) return 'Good Evening.';
    return 'Good Night.';
  }

  void _handleSend() {
    final text = _textController.text.trim();
    final attachmentPath = ref.read(chatAttachmentProvider);
    if (text.isEmpty && attachmentPath == null) return;

    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendMessage(text, attachmentPath);
    _textController.clear();
    ref.read(chatAttachmentProvider.notifier).setAttachment(null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _handleMicPress() async {
    final voiceState = ref.read(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    if (voiceState.isListening) {
      HapticFeedback.lightImpact();
      voiceNotifier.stopListening();
    } else {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        HapticFeedback.mediumImpact();
        voiceNotifier.startListening((words) {
          _textController.text = words;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission required for voice input.'),
            backgroundColor: EdgeXTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleAttachFile() async {
    HapticFeedback.mediumImpact();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      ref.read(chatAttachmentProvider.notifier).setAttachment(result.files.single.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatProvider);
    final attachedFilePath = ref.watch(chatAttachmentProvider);
    final isThinking = ref.watch(isThinkingProvider);
    final voiceState = ref.watch(voiceProvider);
    final canSend = _hasInput || attachedFilePath != null;

    ref.listen(isThinkingProvider, (_, next) {
      if (next) _scrollToBottom();
      if (!next && chatHistory.isNotEmpty) {
        // Haptic when AI finishes
        HapticFeedback.mediumImpact();
      }
    });

    ref.listen(chatProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      drawer: _buildHistoryDrawer(context, ref),
      appBar: _buildAppBar(context, ref),
      body: Column(
        children: [
          Expanded(
            child: chatHistory.isEmpty && !isThinking
                ? _buildEmptyState()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.05, end: 0)
                : _buildMessageList(chatHistory, isThinking),
          ),
          if (voiceState.isListening)
            _VoiceWaveformBar()
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.5, end: 0),
          _buildInputBar(context, ref, attachedFilePath, canSend, voiceState),
        ],
      ),
    );
  }

  // ─── HISTORY DRAWER ───
  Widget _buildHistoryDrawer(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: EdgeXTheme.surface.withValues(alpha: 0.92),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EdgeXTheme.purpleAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.history_rounded, color: EdgeXTheme.purpleAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Chat History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: EdgeXTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: EdgeXTheme.purpleAccent),
                          tooltip: 'New Chat',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ref.read(chatProvider.notifier).createNewChat();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 40, color: EdgeXTheme.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('No previous chats.',
                                    style: TextStyle(color: EdgeXTheme.textSecondary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: sessions.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, indent: 20, endIndent: 20,
                                    color: Colors.white.withValues(alpha: 0.04)),
                            itemBuilder: (context, i) {
                              final session = sessions[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: EdgeXTheme.purpleAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded,
                                      size: 16, color: EdgeXTheme.purpleAccent),
                                ),
                                title: Text(
                                  session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14, color: EdgeXTheme.textPrimary),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      size: 18, color: EdgeXTheme.errorRed.withValues(alpha: 0.7)),
                                  onPressed: () {
                                    HapticFeedback.heavyImpact();
                                    ref.read(sessionsProvider.notifier).deleteSession(session.id);
                                  },
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref.read(chatProvider.notifier).loadChat(session.id);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ───
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AppBar(
            backgroundColor: EdgeXTheme.background.withValues(alpha: 0.6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: EdgeXTheme.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              children: [
                const Text(
                  'EdgeX',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: EdgeXTheme.textPrimary,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 8),
                _LiveBadge(),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: EdgeXTheme.textSecondary),
                tooltip: 'Export to PDF',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final messenger = ScaffoldMessenger.of(context);
                  final path = await ref.read(chatProvider.notifier).exportChatToPDF();
                  if (path != null) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Saved: ${path.split('/').last}'),
                      backgroundColor: EdgeXTheme.emeraldAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: EdgeXTheme.purpleAccent),
                tooltip: 'New Chat',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(chatProvider.notifier).createNewChat();
                },
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/settings');
                },
                child: Container(
                  height: 36,
                  width: 36,
                  margin: const EdgeInsets.only(right: 16, left: 4),
                  decoration: BoxDecoration(
                    color: EdgeXTheme.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18, color: EdgeXTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ───
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated orb
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EdgeXTheme.purpleAccent.withValues(alpha: 0.3),
                    EdgeXTheme.cyanAccent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EdgeXTheme.purpleAccent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: EdgeXTheme.purpleAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 42, color: EdgeXTheme.purpleAccent),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.06, duration: 2500.ms, curve: Curves.easeInOut),
            const SizedBox(height: 28),
            Text(
              _getDynamicGreeting(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: EdgeXTheme.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentQuote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: EdgeXTheme.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            // Quick prompt chips
            ..._quickPrompts.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuickPromptChip(
                  icon: e.value['icon'] as IconData,
                  text: e.value['text'] as String,
                  onTap: () {
                    _textController.text = e.value['text'] as String;
                    setState(() => _hasInput = true);
                    _focusNode.requestFocus();
                  },
                ),
              ).animate(delay: (100 * e.key).ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
            }),
          ],
        ),
      ),
    );
  }

  // ─── MESSAGE LIST ───
  Widget _buildMessageList(List<ChatMessage> chatHistory, bool isThinking) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
        bottom: 24,
      ),
      itemCount: chatHistory.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < chatHistory.length) {
          return _MessageBubble(
            msg: chatHistory[index],
            isLastAi: !chatHistory[index].isUser && index == chatHistory.length - 1,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
        }
        return _ThinkingIndicator()
            .animate()
            .fadeIn(duration: 300.ms);
      },
    );
  }

  // ─── INPUT BAR ───
  Widget _buildInputBar(
    BuildContext context,
    WidgetRef ref,
    String? attachedFilePath,
    bool canSend,
    VoiceState voiceState,
  ) {
    final selectedModel = ref.watch(selectedModelProvider);
    final displayFileName = attachedFilePath?.split('/').last;
    final downloadedModels = ref
        .watch(modelsProvider)
        .where((m) => m.isDownloaded)
        .map((m) => m.title)
        .toList();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: EdgeXTheme.surface.withValues(alpha: 0.7),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model selector
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: _ModelSelectorChip(
                  selectedModel: selectedModel,
                  downloadedModels: downloadedModels,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    ref.read(selectedModelProvider.notifier).setModel(val);
                  },
                ),
              ),

              // Attachment preview
              if (attachedFilePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: _AttachmentChip(
                    fileName: displayFileName ?? 'File',
                    onRemove: () {
                      HapticFeedback.lightImpact();
                      ref.read(chatAttachmentProvider.notifier).setAttachment(null);
                    },
                  ),
                ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.1, end: 0),

              // Input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  _CircleIconButton(
                    icon: Icons.attach_file_rounded,
                    color: EdgeXTheme.textSecondary,
                    onTap: _handleAttachFile,
                  ),
                  const SizedBox(width: 8),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: EdgeXTheme.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        style: const TextStyle(
                          color: EdgeXTheme.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message EdgeX...',
                          hintStyle: TextStyle(color: EdgeXTheme.textSecondary, fontWeight: FontWeight.w400),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => canSend ? _handleSend() : null,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mic / Send button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: canSend
                        ? _SendButton(key: const ValueKey('send'), onTap: _handleSend)
                        : _MicButton(
                            key: const ValueKey('mic'),
                            isListening: voiceState.isListening,
                            onTap: _handleMicPress,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// COMPONENT WIDGETS
// ─────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: EdgeXTheme.emeraldAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EdgeXTheme.emeraldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: EdgeXTheme.emeraldAccent,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms),
          const SizedBox(width: 5),
          const Text(
            'ON-DEVICE',
            style: TextStyle(
              color: EdgeXTheme.emeraldAccent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _QuickPromptChip({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: EdgeXTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: EdgeXTheme.cyanAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: EdgeXTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: EdgeXTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final ChatMessage msg;
  final bool isLastAi;

  const _MessageBubble({required this.msg, this.isLastAi = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            isUser ? _UserBubble(msg: msg) : _AiBubble(msg: msg),

            // Action row for AI messages
            if (!isUser && msg.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: _AiMessageActions(msg: msg, ref: ref),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage msg;
  const _UserBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: EdgeXTheme.userBubbleGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: EdgeXTheme.purpleAccent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.hasAttachment) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      msg.attachmentName ?? 'Document',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, letterSpacing: -0.1),
          ),
        ],
      ),
    );
  }
}

class _AiBubble extends ConsumerWidget {
  final ChatMessage msg;
  const _AiBubble({required this.msg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThinking = ref.watch(isThinkingProvider);
    // Last AI message is currently being streamed
    final isStreaming = isThinking && msg.text.isEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: EdgeXTheme.surface2.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            border: Border.all(
              color: isStreaming
                  ? EdgeXTheme.cyanAccent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.07),
              width: isStreaming ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isStreaming
                    ? EdgeXTheme.cyanAccent.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: MarkdownBody(
            data: msg.text.isEmpty ? '▍' : msg.text,
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: EdgeXTheme.textPrimary,
                fontSize: 16,
                height: 1.65,
                letterSpacing: -0.1,
              ),
              strong: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              em: TextStyle(color: EdgeXTheme.textPrimary.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
              h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
              h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              h3: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              listBullet: const TextStyle(color: EdgeXTheme.cyanAccent),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              code: GoogleFonts.jetBrainsMono(
                color: EdgeXTheme.cyanAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                fontSize: 14,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: EdgeXTheme.purpleAccent, width: 3),
                ),
              ),
            ),
            builders: {'code': _CodeBlockBuilder(context)},
          ),
        ),
      ),
    );
  }
}

class _AiMessageActions extends StatelessWidget {
  final ChatMessage msg;
  final WidgetRef ref;

  const _AiMessageActions({required this.msg, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(ttsProvider);
    final isSpeaking = ttsState.isSpeaking && ttsState.speakingMessageId == msg.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.content_copy_rounded,
          label: 'Copy',
          onTap: () {
            HapticFeedback.selectionClick();
            Clipboard.setData(ClipboardData(text: msg.text));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Copied to clipboard'),
              backgroundColor: EdgeXTheme.emeraldAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ));
          },
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
          label: isSpeaking ? 'Stop' : 'Speak',
          color: isSpeaking ? EdgeXTheme.amberAccent : null,
          onTap: () {
            ref.read(ttsProvider.notifier).speak(msg.text, msg.id);
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EdgeXTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

// Dark-theme thinking indicator with animated dots
class _ThinkingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: EdgeXTheme.surface2.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: EdgeXTheme.cyanAccent.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thinking', style: TextStyle(color: EdgeXTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            ...List.generate(3, (i) => _PulseDot(delay: i * 200)),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final int delay;
  const _PulseDot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 4),
      decoration: const BoxDecoration(
        color: EdgeXTheme.cyanAccent,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .scaleXY(begin: 0.5, end: 1.0, delay: delay.ms, duration: 400.ms, curve: Curves.easeInOut);
  }
}

// Animated voice waveform bar shown when mic is listening
class _VoiceWaveformBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heights = [18.0, 28.0, 22.0, 32.0, 20.0, 26.0, 18.0];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: EdgeXTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic_rounded, size: 16, color: EdgeXTheme.cyanAccent),
          const SizedBox(width: 12),
          ...heights.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3,
                height: e.value,
                decoration: BoxDecoration(
                  color: EdgeXTheme.cyanAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleY(
                    begin: 0.3,
                    end: 1.0,
                    delay: (e.key * 80).ms,
                    duration: 500.ms,
                    curve: Curves.easeInOut,
                  )),
          const SizedBox(width: 12),
          const Text('Listening...', style: TextStyle(color: EdgeXTheme.cyanAccent, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ModelSelectorChip extends StatelessWidget {
  final String selectedModel;
  final List<String> downloadedModels;
  final ValueChanged<String> onSelected;

  const _ModelSelectorChip({
    required this.selectedModel,
    required this.downloadedModels,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -140),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: EdgeXTheme.surface2,
      onSelected: onSelected,
      itemBuilder: (context) => downloadedModels.isEmpty
          ? [const PopupMenuItem(value: '', child: Text('No models downloaded', style: TextStyle(color: EdgeXTheme.textSecondary)))]
          : downloadedModels.map((m) => PopupMenuItem(
                value: m,
                child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600, color: EdgeXTheme.textPrimary)),
              )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: EdgeXTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EdgeXTheme.surfaceHighlight.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 12, color: EdgeXTheme.purpleAccent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                selectedModel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EdgeXTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: EdgeXTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const _AttachmentChip({required this.fileName, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EdgeXTheme.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file_rounded, size: 13, color: EdgeXTheme.cyanAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(fileName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: EdgeXTheme.cyanAccent, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: EdgeXTheme.cyanAccent),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: EdgeXTheme.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          gradient: EdgeXTheme.userBubbleGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: EdgeXTheme.purpleGlow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _MicButton({super.key, required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isListening ? EdgeXTheme.cyanAccent : EdgeXTheme.surface2,
          shape: BoxShape.circle,
          border: Border.all(
            color: isListening ? EdgeXTheme.cyanAccent : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: isListening
              ? [BoxShadow(color: EdgeXTheme.cyanAccent.withValues(alpha: 0.35), blurRadius: 12)]
              : null,
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 20,
          color: isListening ? Colors.white : EdgeXTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// CODE BLOCK BUILDER
// ─────────────────────────────────────────────────
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  _CodeBlockBuilder(this.context);

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code block header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                if (language.isNotEmpty) ...[
                  Text(language.toUpperCase(),
                      style: const TextStyle(
                          color: EdgeXTheme.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  const Spacer(),
                ],
                if (language.isEmpty) const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Code copied'),
                      backgroundColor: EdgeXTheme.emeraldAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.content_copy_rounded, size: 12, color: EdgeXTheme.textSecondary),
                      const SizedBox(width: 4),
                      const Text('Copy code',
                          style: TextStyle(color: EdgeXTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Syntax highlighted code
          Padding(
            padding: const EdgeInsets.all(14),
            child: HighlightView(
              code,
              language: language.isEmpty ? 'plaintext' : language,
              theme: atomOneDarkTheme,
              padding: EdgeInsets.zero,
              textStyle: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}