import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../services/consult_service.dart';
import '../providers/consults_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const ChatScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _service = ConsultService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final msgs = await _service.getChatMessages(widget.appointmentId);
    if (mounted) {
      final wasEmpty = _messages.isEmpty;
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      if (wasEmpty && _messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    final msg = await _service.sendChatMessage(widget.appointmentId, text);
    if (msg != null) {
      setState(() => _messages = [..._messages, msg]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultsProvider);
    final appt = state.appointments.where((a) => a.id == widget.appointmentId).firstOrNull;
    final doctorName = appt?.doctor?.name ?? 'Consultation Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctorName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Chat with doctor', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.chatDots, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No messages yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            const Text('Send a message to start the conversation', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderName == 'You' || msg.senderId.isEmpty;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: EdgeInsets.only(
              left: 12, right: 8, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(PhosphorIconsFill.telegramLogo, color: AppColors.secondary, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    final formatted = DateFormat('hh:mm a').format(msg.timestamp);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
