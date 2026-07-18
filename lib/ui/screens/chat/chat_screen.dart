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

  final List<String> _welcomeQuotes = [
    "Your local intelligence is ready.\nWhat shall we build today?",
    "Offline, secure, and private.\nHow can I assist you?",
    "Neural Engine engaged.\nReady for your commands.",
  ];

  @override
  void initState() {
    super.initState();
    _currentQuote = _welcomeQuotes[Random().nextInt(_welcomeQuotes.length)];
    _textController.addListener(() {
      setState(() { _hasInput = _textController.text.trim().isNotEmpty; });
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
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuart);
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
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        HapticFeedback.mediumImpact();
        voiceNotifier.startListening((words) {
          _textController.text = words;
          _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required.')));
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

    ref.listen(isThinkingProvider, (prev, next) { if (next) _scrollToBottom(); });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      drawer: _buildHistoryDrawer(context, ref),
      appBar: _buildCleanAppBar(context, ref),
      body: Column(
        children: [
          Expanded(
            child: chatHistory.isEmpty && !isThinking
                ? _buildEmptyState().animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(left: 16, right: 16, top: MediaQuery.of(context).padding.top + kToolbarHeight + 32, bottom: 24),
                    itemCount: chatHistory.length + (isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatHistory.length) return _buildMessageBubble(chatHistory[index]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                      return _buildShimmerThinkingIndicator().animate().fadeIn(duration: 300.ms);
                    },
                  ),
          ),
          _buildErgonomicInputBar(context, ref, attachedFilePath, canSend, voiceState),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF0F172A)),
                  const SizedBox(width: 12),
                  const Text('Chat History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.add_box_outlined, color: Color(0xFF8B5CF6)), onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(chatProvider.notifier).createNewChat();
                    Navigator.pop(context);
                  })
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sessions.isEmpty 
                ? const Center(child: Text("No previous chats.", style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF64748B)),
                        title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
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
    );
  }

  PreferredSizeWidget _buildCleanAppBar(BuildContext context, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.5), elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text('loc.ai', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), letterSpacing: -1.0)),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF64748B)),
                tooltip: 'Export to PDF',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final path = await ref.read(chatProvider.notifier).exportChatToPDF();
                  if (path != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat saved to: $path')));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_box_outlined, color: Color(0xFF8B5CF6)),
                tooltip: 'New Chat',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(chatProvider.notifier).createNewChat();
                },
              ),
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); context.push('/settings'); },
                child: Container(
                  height: 40, width: 40, margin: const EdgeInsets.only(right: 16, left: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Icon(Icons.settings_outlined, size: 22, color: Color(0xFF64748B)),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, size: 56, color: Color(0xFF8B5CF6))),
          const SizedBox(height: 32),
          Text(_getDynamicGreeting(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1.0)),
          const SizedBox(height: 8),
          Text(_currentQuote, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Color(0xFF64748B), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isUser ? 16 : 0), 
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF8B5CF6) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.hasAttachment) ...[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white), const SizedBox(width: 8), Text(msg.attachmentName ?? 'Document', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                    const SizedBox(height: 12),
                  ],
                  isUser 
                    ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.4, letterSpacing: -0.2))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.only(topLeft: const Radius.circular(24), topRight: const Radius.circular(24), bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))]),
                        child: MarkdownBody(
                          data: msg.text,
                          selectable: false, 
                          extensionSet: md.ExtensionSet.gitHubFlavored,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, height: 1.6, letterSpacing: -0.1), 
                            strong: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            codeblockDecoration: const BoxDecoration(color: Colors.transparent),
                          ),
                          builders: {'code': CodeElementBuilder(context)},
                        ),
                      ),
                ],
              ),
            ),
            
            // --- THE CHATGPT STYLE COPY BUTTON ---
            if (!isUser && msg.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Response copied to clipboard', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2)));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.content_copy, size: 14, color: Color(0xFF94A3B8)),
                      SizedBox(width: 6),
                      Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
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
        margin: const EdgeInsets.only(bottom: 24), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))]),
        child: Shimmer.fromColors(baseColor: Colors.grey.shade200, highlightColor: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))), const SizedBox(height: 16), Container(width: 140, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)))]))),
    );
  }

  Widget _buildErgonomicInputBar(BuildContext context, WidgetRef ref, String? attachedFilePath, bool canSend, VoiceState voiceState) {
    final selectedModel = ref.watch(selectedModelProvider);
    String? displayFileName = attachedFilePath != null ? attachedFilePath.split('/').last : null;
    final downloadedModels = ref.watch(modelsProvider).where((m) => m.isDownloaded).map((m) => m.title).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom > 0 ? 24 : 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.8), width: 1))),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: PopupMenuButton<String>(
                offset: const Offset(0, -120),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) { HapticFeedback.selectionClick(); ref.read(selectedModelProvider.notifier).setModel(val); },
                itemBuilder: (context) => downloadedModels.isEmpty 
                    ? [const PopupMenuItem(value: '', child: Text('No models downloaded'))]
                    : downloadedModels.map((m) => PopupMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text(selectedModel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ),
            if (attachedFilePath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description, color: Color(0xFF8B5CF6), size: 18),
                    const SizedBox(width: 12),
                    Flexible(child: Text(displayFileName ?? 'Document', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 16),
                    GestureDetector(onTap: () { HapticFeedback.lightImpact(); ref.read(chatAttachmentProvider.notifier).setAttachment(null); }, child: const Icon(Icons.cancel, size: 22, color: Color(0xFF94A3B8))),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: voiceState.isListening ? const Color(0xFFEF4444).withOpacity(0.05) : Colors.white, 
                borderRadius: BorderRadius.circular(32), 
                border: Border.all(color: voiceState.isListening ? const Color(0xFFEF4444).withOpacity(0.5) : const Color(0xFFE2E8F0), width: 1.5), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF94A3B8), size: 30), 
                    onPressed: voiceState.isListening ? null : () async { 
                      HapticFeedback.lightImpact(); 
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                      if (result != null) {
                        ref.read(chatAttachmentProvider.notifier).setAttachment(result.files.single.path);
                      }
                    }
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController, focusNode: _focusNode, minLines: 1, maxLines: 5, keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: voiceState.isListening ? 'Listening...' : 'Message loc.ai...', 
                        border: InputBorder.none, 
                        hintStyle: TextStyle(color: voiceState.isListening ? const Color(0xFFEF4444) : const Color(0xFF94A3B8), fontSize: 17), 
                        contentPadding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 17),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: voiceState.isListening ? const Color(0xFFEF4444) : (canSend ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9)), 
                        shape: BoxShape.circle
                      ),
                      child: IconButton(
                        icon: Icon(
                          canSend ? Icons.arrow_upward : (voiceState.isListening ? Icons.stop : Icons.mic), 
                          color: (canSend || voiceState.isListening) ? Colors.white : const Color(0xFF94A3B8), 
                          size: 22
                        ), 
                        onPressed: canSend ? _handleSend : _handleMicPress
                      ),
                    ).animate(target: voiceState.isListening ? 1 : 0).scaleXY(end: 1.1, duration: 400.ms).then().scaleXY(end: 1.0/1.1),
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

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.startsWith('language-') ? lg.substring(9) : lg;
    }
    
    if (!element.textContent.contains('\n')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
        child: Text(element.textContent, style: GoogleFonts.firaCode(color: const Color(0xFF8B5CF6), fontSize: 14, fontWeight: FontWeight.w600)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF282C34), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(color: Color(0xFF1E2227), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.isEmpty ? 'code' : language, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: element.textContent.trim()));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Copied', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2)));
                  },
                  child: const Row(children: [Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)), SizedBox(width: 6), Text('Copy', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700))]),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
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