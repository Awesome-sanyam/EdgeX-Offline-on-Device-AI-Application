import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/state/app_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _currentQuote = _welcomeQuotes[Random().nextInt(_welcomeQuotes.length)];
    _textController.addListener(() {
      final hasInput = _textController.text.trim().isNotEmpty;
      if (hasInput != _hasInput) {
        setState(() => _hasInput = hasInput);
      }
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
          const SnackBar(
            content: Text('Microphone permission is required for voice input.'),
          ),
        );
      }
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
          _buildInputBar(context, ref, attachedFilePath, canSend, voiceState),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> chatHistory, bool isThinking) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
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
          return _buildMessageBubble(chatHistory[index])
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
        }
        return _buildShimmerThinkingIndicator()
            .animate()
            .fadeIn(duration: 300.ms);
      },
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chat History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFF8B5CF6),
                          ),
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
                  Divider(
                    height: 1,
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 40,
                                  color: const Color(
                                    0xFF94A3B8,
                                  ).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No previous chats.',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: sessions.length,
                            separatorBuilder: (ignored, index2) => Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: const Color(0xFF0F172A).withValues(
                                alpha: 0.05,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                                title: Text(
                                  session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.heavyImpact();
                                    ref
                                        .read(sessionsProvider.notifier)
                                        .deleteSession(session.id);
                                  },
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(chatProvider.notifier)
                                      .loadChat(session.id);
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

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text(
              'EdgeX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFF64748B),
                ),
                tooltip: 'Export to PDF',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final messenger = ScaffoldMessenger.of(context);
                  final path = await ref
                      .read(chatProvider.notifier)
                      .exportChatToPDF();
                  if (path != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Saved: ${path.split('/').last}'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_box_outlined,
                  color: Color(0xFF8B5CF6),
                ),
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
                  height: 38,
                  width: 38,
                  margin: const EdgeInsets.only(right: 16, left: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 52,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _getDynamicGreeting(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentQuote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isUser ? 16 : 0),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF8B5CF6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.hasAttachment) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg.attachmentName ?? 'Document',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  isUser
                      ? Text(
                          msg.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: MarkdownBody(
                            data: msg.text,
                            selectable: true,
                            extensionSet: md.ExtensionSet.gitHubFlavored,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                height: 1.6,
                                letterSpacing: -0.1,
                              ),
                              strong: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              codeblockDecoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                            ),
                            builders: {'code': CodeElementBuilder(context)},
                          ),
                        ),
                ],
              ),
            ),

            // Copy button for AI messages
            if (!isUser && msg.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Copied to clipboard',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_copy,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 120,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model selector chip
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, -120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    ref.read(selectedModelProvider.notifier).setModel(val);
                  },
                  itemBuilder: (context) => downloadedModels.isEmpty
                      ? [
                          const PopupMenuItem(
                            value: '',
                            child: Text('No models downloaded yet'),
                          ),
                        ]
                      : downloadedModels
                          .map(
                            (m) => PopupMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedModel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Attachment chip
              if (attachedFilePath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description,
                        color: Color(0xFF8B5CF6),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          displayFileName ?? 'Document',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(chatAttachmentProvider.notifier)
                              .setAttachment(null);
                        },
                        child: const Icon(
                          Icons.cancel,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),

              // Input row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: voiceState.isListening
                      ? const Color(0xFFEF4444).withValues(alpha: 0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: voiceState.isListening
                        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF94A3B8),
                        size: 28,
                      ),
                      onPressed: voiceState.isListening
                          ? null
                          : () async {
                              HapticFeedback.lightImpact();
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                  );
                              if (result != null) {
                                ref
                                    .read(chatAttachmentProvider.notifier)
                                    .setAttachment(result.files.single.path);
                              }
                            },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: voiceState.isListening
                              ? 'Listening...'
                              : 'Message EdgeX...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: voiceState.isListening
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF94A3B8),
                            fontSize: 16,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: voiceState.isListening
                              ? const Color(0xFFEF4444)
                              : (canSend
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            canSend
                                ? Icons.arrow_upward
                                : (voiceState.isListening
                                    ? Icons.stop
                                    : Icons.mic),
                            color: (canSend || voiceState.isListening)
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed:
                              canSend ? _handleSend : _handleMicPress,
                        ),
                      )
                          .animate(target: voiceState.isListening ? 1.0 : 0.0)
                          .scaleXY(
                            end: 1.08,
                            duration: 400.ms,
                          )
                          .then()
                          .scaleXY(end: 1.0 / 1.08),
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

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      final lg = element.attributes['class'] as String;
      language = lg.startsWith('language-') ? lg.substring(9) : lg;
    }

    // Inline code
    if (!element.textContent.contains('\n')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          element.textContent,
          style: GoogleFonts.firaCode(
            color: const Color(0xFF8B5CF6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Block code
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2227),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isEmpty ? 'code' : language,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: element.textContent.trim()),
                    );
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Code copied',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
                      SizedBox(width: 5),
                      Text(
                        'Copy',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: HighlightView(
                element.textContent.trim(),
                language: language.isEmpty ? 'dart' : language,
                theme: atomOneDarkTheme,
                padding: const EdgeInsets.all(16),
                textStyle: GoogleFonts.firaCode(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}