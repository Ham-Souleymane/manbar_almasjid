import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../registration/data/registration_repository.dart';
import '../application/forum_providers.dart';
import '../domain/forum_message_model.dart';
import 'group_info_screen.dart';

class ImamGroupChatScreen extends ConsumerStatefulWidget {
  const ImamGroupChatScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<ImamGroupChatScreen> createState() =>
      _ImamGroupChatScreenState();
}

class _ImamGroupChatScreenState extends ConsumerState<ImamGroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  ForumMessageModel? _replyingTo;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final imam = ref.read(currentImamProvider).asData?.value;
    final user = ref.read(firebaseAuthProvider).currentUser;
    final mosque = ref.read(currentMosqueProvider).asData?.value;

    final senderId = imam?.id ?? user?.uid ?? 'imam_anonymous';
    final senderName = imam?.fullName.isNotEmpty == true
        ? imam!.fullName
        : (user?.displayName ?? 'فضيلة الإمام');
    final senderPhoto = imam?.photo ?? user?.photoURL;
    final senderMosque = mosque?.name ?? '';

    final message = ForumMessageModel(
      id: '',
      groupId: widget.groupId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      senderMosqueName: senderMosque,
      senderRole: 'إمام وخطيب',
      text: text,
      mediaUrl: imageUrl,
      mediaType: imageUrl != null ? 'image' : null,
      createdAt: DateTime.now(),
      replyToMessageId: _replyingTo?.id,
      replyToText: _replyingTo?.text.isNotEmpty == true
          ? _replyingTo!.text
          : (_replyingTo?.mediaUrl != null ? '[صورة]' : null),
      replyToSenderName: _replyingTo?.senderName,
    );

    _messageController.clear();
    setState(() => _replyingTo = null);

    await ref
        .read(forumControllerProvider.notifier)
        .sendMessage(groupId: widget.groupId, message: message);

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    final imam = ref.read(currentImamProvider).asData?.value;
    final currentImamId =
        imam?.id ?? ref.read(firebaseAuthProvider).currentUser?.uid ?? 'imam';

    setState(() => _isSending = true);
    final url = await ref.read(forumControllerProvider.notifier).uploadImage(
          file: File(picked.path),
          imamId: currentImamId,
        );
    setState(() => _isSending = false);

    if (url != null) {
      await _sendMessage(imageUrl: url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر رفع الصورة، يرجى المحاولة مرة أخرى'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMessageOptions(ForumMessageModel message, String currentUserId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final emojis = ['🤲', '👍', '❤️', '💡', '📚', '✍️'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick emoji reaction bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: emojis.map((emoji) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref
                            .read(forumControllerProvider.notifier)
                            .toggleReaction(
                              groupId: widget.groupId,
                              messageId: message.id,
                              emoji: emoji,
                              imamId: currentUserId,
                            );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),

                // Reply Action
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: AppColors.emerald),
                  title: const Text('رد على الرسالة'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() => _replyingTo = message);
                  },
                ),

                // Copy Action
                if (message.text.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('نسخ نص الرسالة'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ النص')),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupAsync = ref.watch(singleGroupStreamProvider(widget.groupId));
    final messagesAsync =
        ref.watch(groupMessagesStreamProvider(widget.groupId));
    final imam = ref.watch(currentImamProvider).asData?.value;
    final currentUserId =
        imam?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';

    return groupAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFEFEAE2),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('ملتقى الأئمة')),
        body: Center(child: Text('حدث خطأ: $e')),
      ),
      data: (group) {
        if (group == null) {
          return const Scaffold(
            body: Center(child: Text('المجموعة غير موجودة')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEFEAE2),
          appBar: AppBar(
            backgroundColor: const Color(0xFF003527),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 1,
            titleSpacing: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : null,
            title: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(groupId: group.id),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFFC3ECD7),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF064E3B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${group.membersCount} عضو • ${group.category}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFC3ECD7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Mute / Unmute button
              Builder(builder: (context) {
                final mutedGroups = ref.watch(mutedGroupsProvider).asData?.value ?? [];
                final isMuted = mutedGroups.contains(widget.groupId);
                final imam = ref.watch(currentImamProvider).asData?.value;
                return IconButton(
                  tooltip: isMuted ? 'تفعيل الإشعارات' : 'كتم الإشعارات',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded,
                      key: ValueKey(isMuted),
                      color: isMuted ? const Color(0xFFFFD166) : Colors.white,
                    ),
                  ),
                  onPressed: imam == null
                      ? null
                      : () async {
                          final notifier = ref.read(forumControllerProvider.notifier);
                          final messenger = ScaffoldMessenger.of(context);
                          if (isMuted) {
                            await notifier.unmuteGroup(
                              groupId: widget.groupId,
                              imamId: imam.id,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('تم تفعيل الإشعارات لهذا الملتقى'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF0F766E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            await notifier.muteGroup(
                              groupId: widget.groupId,
                              imamId: imam.id,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.notifications_off_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('تم كتم إشعارات هذا الملتقى'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF6B7280),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                );
              }),
              IconButton(
                tooltip: 'معلومات الملتقى',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupInfoScreen(groupId: group.id),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages Feed
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.emerald),
                  ),
                  error: (e, _) => Center(child: Text('خطأ في تحميل الرسائل: $e')),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.forum_rounded,
                                color: AppColors.emeraldDark,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'مرحباً بكم في ${group.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'شات علمي مخصص للأئمة والعلماء لتبادل الخبرات والاستشارات الشرعية. ابدأ النقاش وشارك فائدة.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUserId;
                        final showDateHeader = index == 0 ||
                            !_isSameDay(
                              messages[index - 1].createdAt,
                              msg.createdAt,
                            );

                        return Column(
                          children: [
                            if (showDateHeader)
                              _DateChip(date: msg.createdAt),
                            _MessageBubble(
                              message: msg,
                              isMe: isMe,
                              onLongPress: () =>
                                  _showMessageOptions(msg, currentUserId),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Replying To Banner
              if (_replyingTo != null)
                Container(
                  color: const Color(0xFFE8F5E9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'رد على: ${_replyingTo!.senderName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                            Text(
                              _replyingTo!.text.isNotEmpty
                                  ? _replyingTo!.text
                                  : '[صورة]',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _replyingTo = null),
                      ),
                    ],
                  ),
                ),

              // WhatsApp-style Input Area
              _buildInputArea(l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message Input Pill
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment button
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _AttachOption(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'الكاميرا',
                                    color: Colors.pink,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickAndSendImage(ImageSource.camera);
                                    },
                                  ),
                                  _AttachOption(
                                    icon: Icons.image_rounded,
                                    label: 'المعرض',
                                    color: Colors.purple,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickAndSendImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: l10n.typeMessage,
                          hintStyle: const TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send / Mic Circle Button
            GestureDetector(
              onTap: _isSending ? null : () => _sendMessage(),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF003527),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String text;
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      text = 'اليوم';
    } else if (now.year == date.year &&
        now.month == date.month &&
        now.day - date.day == 1) {
      text = 'أمس';
    } else {
      text = DateFormat('dd MMMM yyyy', 'ar').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  final ForumMessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;

  Color _getSenderColor(String name) {
    final colors = [
      const Color(0xFF0F766E),
      const Color(0xFF1D4ED8),
      const Color(0xFFB45309),
      const Color(0xFF7E22CE),
      const Color(0xFFBE185D),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a', 'ar').format(message.createdAt);
    final senderColor = _getSenderColor(message.senderName);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other imams
            if (!isMe) ...[
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.emeraldPale,
                backgroundImage: message.senderPhoto != null &&
                        message.senderPhoto!.isNotEmpty
                    ? NetworkImage(message.senderPhoto!)
                    : null,
                child: message.senderPhoto == null ||
                        message.senderPhoto!.isEmpty
                    ? const Icon(Icons.person,
                        color: AppColors.emeraldDark, size: 16)
                    : null,
              ),
              const SizedBox(width: 6),
            ],

            // Message Body Container
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFD8F2E3) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Name & Mosque Tag (if not me)
                    if (!isMe) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: senderColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (message.senderMosqueName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${message.senderMosqueName})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Reply Quote block
                    if (message.replyToSenderName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFC0E8D0)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            right: BorderSide(
                              color: isMe
                                  ? AppColors.emeraldDark
                                  : senderColor,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToSenderName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe
                                    ? AppColors.emeraldDark
                                    : senderColor,
                              ),
                            ),
                            Text(
                              message.replyToText ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Image attachment
                    if (message.mediaUrl != null &&
                        message.mediaUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 180,
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.emerald,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Text Content
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          height: 1.35,
                        ),
                      ),

                    const SizedBox(height: 2),

                    // Timestamp & Delivery Check
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: Color(0xFF0F766E),
                          ),
                        ],
                      ],
                    ),

                    // Emoji Reactions
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: message.reactions.entries.map((entry) {
                          if (entry.value.isEmpty) return const SizedBox();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              '${entry.key} ${entry.value.length}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
