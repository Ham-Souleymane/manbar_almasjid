import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers/firebase_providers.dart';
import '../domain/forum_message_model.dart';
import '../domain/imam_group_model.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

class ForumRepository {
  ForumRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('imam_groups');

  CollectionReference<Map<String, dynamic>> _messages(String groupId) =>
      _groups.doc(groupId).collection('messages');

  /// Streams all groups, optionally filtered by category and search term.
  Stream<List<ImamGroupModel>> watchGroups({
    String? category,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> query = _groups;

    if (category != null && category.isNotEmpty && category != 'الكل' && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => ImamGroupModel.fromFirestore(doc)).toList();

      // Client-side search filtering
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((g) {
          return g.name.toLowerCase().contains(q) ||
              g.nameEn.toLowerCase().contains(q) ||
              g.description.toLowerCase().contains(q) ||
              g.category.toLowerCase().contains(q);
        }).toList();
      }

      // Sort by membersCount descending
      list.sort((a, b) => b.membersCount.compareTo(a.membersCount));
      return list;
    });
  }

  /// Streams a single group by ID.
  Stream<ImamGroupModel?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ImamGroupModel.fromFirestore(doc);
    });
  }

  /// Get single group by ID.
  Future<ImamGroupModel?> getGroup(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return null;
    return ImamGroupModel.fromFirestore(doc);
  }

  /// Admin creates a new group.
  Future<String> createGroup(ImamGroupModel group) async {
    final docRef = _groups.doc();
    final newGroup = group.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
    );
    await docRef.set(newGroup.toFirestore());
    return docRef.id;
  }

  /// Admin updates a group.
  Future<void> updateGroup(ImamGroupModel group) async {
    await _groups.doc(group.id).update(group.toFirestore());
  }

  /// Admin deletes a group.
  Future<void> deleteGroup(String groupId) async {
    await _groups.doc(groupId).delete();
  }

  /// Join an Imam to a group and notify existing members.
  Future<void> joinGroup({
    required String groupId,
    required String imamId,
    String imamName = '',
    String groupName = '',
  }) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([imamId]),
      'membersCount': FieldValue.increment(1),
    });

    // Notify existing members about the new joiner
    try {
      final groupDoc = await _groups.doc(groupId).get();
      if (!groupDoc.exists) return;
      final data = groupDoc.data()!;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final resolvedGroupName = groupName.isNotEmpty ? groupName : (data['name'] ?? 'ملتقى الأئمة');
      final mutedField = 'mutedGroups';

      final batch = _firestore.batch();
      for (final memberId in memberIds) {
        if (memberId == imamId || memberId.trim().isEmpty) continue;

        // Check if member muted this group
        final memberDoc = await _firestore.collection('imams').doc(memberId).get();
        final mutedGroups = List<String>.from(memberDoc.data()?[mutedField] ?? []);
        if (mutedGroups.contains(groupId)) continue;

        final notifRef = _firestore
            .collection('imams')
            .doc(memberId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': 'عضو جديد في $resolvedGroupName',
          'body': '${imamName.isNotEmpty ? imamName : 'إمام جديد'} انضم إلى الملتقى',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'forum_join',
          'groupId': groupId,
          'senderName': imamName,
          'read': false,
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Leave a group.
  Future<void> leaveGroup({
    required String groupId,
    required String imamId,
  }) async {
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([imamId]),
      'membersCount': FieldValue.increment(-1),
    });
  }

  /// Streams real-time messages for a group.
  Stream<List<ForumMessageModel>> watchMessages(String groupId) {
    return _messages(groupId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ForumMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Extracts @mentioned display names from a message text.
  /// Returns them as a list of lowercased name tokens (after @).
  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@([\w\u0600-\u06FF]+(?:\s[\w\u0600-\u06FF]+)?)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!.trim().toLowerCase())
        .toList();
  }

  /// Sends a message in a group chat with enriched notification logic:
  ///  - @mention  → dedicated 'forum_mention' notif to mentioned member(s).
  ///  - reply     → dedicated 'forum_reply' notif to the original sender.
  ///  - broadcast → 'forum_message' notif to all other members (mute-aware).
  Future<void> sendMessage({
    required String groupId,
    required ForumMessageModel message,
  }) async {
    final docRef = _messages(groupId).doc();
    final newMsg = message.copyWith(
      id: docRef.id,
      groupId: groupId,
      createdAt: DateTime.now(),
    );
    await docRef.set(newMsg.toFirestore());

    // Update group's last activity
    await _groups.doc(groupId).update({
      'lastActivity': Timestamp.fromDate(DateTime.now()),
      'lastMessageText': newMsg.text.isNotEmpty ? newMsg.text : '[صورة]',
      'lastMessageSender': newMsg.senderName,
    });

    // Build notification payloads
    try {
      final groupDoc = await _groups.doc(groupId).get();
      if (!groupDoc.exists) return;
      final data = groupDoc.data()!;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final groupName = data['name'] ?? 'ملتقى الأئمة';

      final mentions = _extractMentions(newMsg.text);
      final repliedToSenderId = newMsg.replyToMessageId != null
          ? await _getMessageSenderId(groupId, newMsg.replyToMessageId!)
          : null;

      final batch = _firestore.batch();

      for (final memberId in memberIds) {
        if (memberId == message.senderId || memberId.trim().isEmpty) continue;

        // Check mute
        final memberDoc = await _firestore.collection('imams').doc(memberId).get();
        final memberData = memberDoc.data() ?? {};
        final mutedGroups = List<String>.from(memberData['mutedGroups'] ?? []);
        final memberName = (memberData['fullName'] as String? ?? '').toLowerCase();

        // Determine notification type & priority
        final isMentioned = mentions.any((m) => memberName.contains(m) || m.contains(memberName.split(' ').first));
        final isReplied = repliedToSenderId != null && memberId == repliedToSenderId;

        // Mentions and replies always go through even if muted
        String? notifType;
        String? notifTitle;
        String? notifBody;

        if (isMentioned) {
          notifType = 'forum_mention';
          notifTitle = '${newMsg.senderName} ذكرك في $groupName';
          notifBody = newMsg.text.isNotEmpty ? newMsg.text : '[صورة]';
        } else if (isReplied) {
          notifType = 'forum_reply';
          notifTitle = '${newMsg.senderName} رد على رسالتك في $groupName';
          notifBody = newMsg.text.isNotEmpty ? newMsg.text : '[صورة]';
        } else {
          // Regular broadcast — skip if muted
          if (mutedGroups.contains(groupId)) continue;
          notifType = 'forum_message';
          notifTitle = 'رسالة جديدة في $groupName';
          notifBody = '${newMsg.senderName}: ${newMsg.text.isNotEmpty ? newMsg.text : (newMsg.mediaUrl != null ? "أرسل صورة" : "رسالة جديدة")}';
        }

        final notifRef = _firestore
            .collection('imams')
            .doc(memberId)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'title': notifTitle,
          'body': notifBody,
          'timestamp': FieldValue.serverTimestamp(),
          'type': notifType,
          'groupId': groupId,
          'senderName': newMsg.senderName,
          if (newMsg.senderPhoto != null) 'senderPhoto': newMsg.senderPhoto,
          'read': false,
        });
      }
      await batch.commit();
    } catch (_) {
      // Don't fail the message send if notification fails
    }
  }

  /// Fetches the senderId of a specific message (for reply notifications).
  Future<String?> _getMessageSenderId(String groupId, String messageId) async {
    try {
      final doc = await _messages(groupId).doc(messageId).get();
      if (!doc.exists) return null;
      return doc.data()?['senderId'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Mutes notifications for a group for a given imam.
  Future<void> muteGroup({required String groupId, required String imamId}) async {
    await _firestore.collection('imams').doc(imamId).update({
      'mutedGroups': FieldValue.arrayUnion([groupId]),
    });
  }

  /// Unmutes notifications for a group for a given imam.
  Future<void> unmuteGroup({required String groupId, required String imamId}) async {
    await _firestore.collection('imams').doc(imamId).update({
      'mutedGroups': FieldValue.arrayRemove([groupId]),
    });
  }

  /// Returns whether the imam has muted a specific group (one-shot read).
  Future<bool> isGroupMuted({required String groupId, required String imamId}) async {
    try {
      final doc = await _firestore.collection('imams').doc(imamId).get();
      final mutedGroups = List<String>.from(doc.data()?['mutedGroups'] ?? []);
      return mutedGroups.contains(groupId);
    } catch (_) {
      return false;
    }
  }

  /// Soft deletes a message.
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    await _messages(groupId).doc(messageId).update({
      'isDeleted': true,
      'text': 'تم حذف هذه الرسالة',
    });
  }

  /// Toggle an emoji reaction on a message.
  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    required String imamId,
  }) async {
    final docRef = _messages(groupId).doc(messageId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() ?? {};
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final currentList = List<String>.from(reactions[emoji] ?? []);

    if (currentList.contains(imamId)) {
      currentList.remove(imamId);
    } else {
      currentList.add(imamId);
    }

    if (currentList.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = currentList;
    }

    await docRef.update({'reactions': reactions});
  }

  /// Upload chat media image (using Cloudinary or Firebase Storage).
  Future<String> uploadChatMedia({
    required File file,
    required String imamId,
  }) async {
    try {
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      const uploadPreset = 'ml_default';
      const apiKey = '469544593144925';
      const apiSecret = 'KmhsBEK1uXT4lgbHI9WYh5ib7X8';

      final sortedParams =
          'timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret';
      final signature = sha1.convert(utf8.encode(sortedParams)).toString();

      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/vbc9yur2/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resBytes = await response.stream.toBytes();
        final resString = String.fromCharCodes(resBytes);
        final json = jsonDecode(resString);
        return json['secure_url'] as String;
      }
    } catch (_) {
      // Fallback to Firebase storage if Cloudinary fails
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
    final ref = _storage.ref().child('forum_chats/$imamId/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Seeds default specialized religious groups if the collection is empty.
  Future<void> seedDefaultGroupsIfEmpty() async {
    try {
      final snapshot = await _groups.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final defaultGroups = [
        ImamGroupModel(
          id: 'fiqh_forum',
          name: 'Fiqh Forum (ملتقى الفقه)',
          nameEn: 'Fiqh Forum',
          category: 'الفقه',
          description:
              'مناقشات متعمقة في الفقه الإسلامي المقارن والنوازل الفقهية المعاصرة مع كبار العلماء.',
          iconName: 'menu_book',
          colorKey: 'emerald',
          membersCount: 1240,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          rules: [
            'الالتزام بالأدب العلمي واحترام الآراء الفقهية المعتبرة.',
            'عزو الأقوال إلى مصادرها الفقهية المعتمدة.',
            'تجنب الجدال العقيم والتركيز على التأصيل الشرعي.',
          ],
        ),
        ImamGroupModel(
          id: 'hadith_scholars',
          name: 'Hadith Scholars (علماء الحديث)',
          nameEn: 'Hadith Scholars',
          category: 'الحديث الشريف',
          description:
              'دراسة وتخريج الأحاديث النبوية ومناقشة علوم الرجال والمصطلح.',
          iconName: 'library_books',
          colorKey: 'amber',
          membersCount: 856,
          createdAt: DateTime.now().subtract(const Duration(days: 75)),
          rules: [
            'تحري الدقة في نقل الأحاديث وعزوها لكتب السنة.',
            'ذكر درجات الأحاديث بناءً على أحكام أئمة الحديث المعتمدين.',
          ],
        ),
        ImamGroupModel(
          id: 'contemporary_issues',
          name: 'Contemporary Issues (قضايا معاصرة)',
          nameEn: 'Contemporary Issues',
          category: 'قضايا معاصرة',
          description:
              'تدارس القضايا الفكرية والاجتماعية الحديثة وطرق توجيه المجتمع الإسلامي.',
          iconName: 'public',
          colorKey: 'teal',
          membersCount: 2105,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          rules: [
            'ربط القضايا المستجدة بمقاصد الشريعة الإسلامية.',
            'طرح الحلول العملية والمبادرات التوعوية للمجتمع.',
          ],
        ),
        ImamGroupModel(
          id: 'mosque_management',
          name: 'Mosque Management (إدارة المساجد)',
          nameEn: 'Mosque Management',
          category: 'إدارة المساجد',
          description:
              'تبادل الخبرات في إدارة شؤون المساجد وتفعيل دورها في المجتمع.',
          iconName: 'mosque',
          colorKey: 'green',
          membersCount: 430,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          rules: [
            'مشاركة التجارب الناجحة في تنظيم دروس وحلقات المسجد.',
            'تطوير الأنشطة الاجتماعية والمجتمعية لرواد المسجد.',
          ],
        ),
        ImamGroupModel(
          id: 'quran_tajweed',
          name: 'Quran & Tajweed (علوم القرآن والتجويد)',
          nameEn: 'Quran & Tajweed',
          category: 'القرآن والتجويد',
          description:
              'مدارسة أحكام التلاوة والتجويد والقراءات القرآنية وعلوم التفسير.',
          iconName: 'auto_stories',
          colorKey: 'gold',
          membersCount: 680,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          rules: [
            'التحقق من الروايات والإسناد القرآني.',
            'تبادل مناهج التحفيظ والإجازات بالسند المتصل.',
          ],
        ),
        ImamGroupModel(
          id: 'khutbah_dawa',
          name: 'Khutbah & Preaching (فن الخطابة والدعوة)',
          nameEn: 'Khutbah & Preaching',
          category: 'الخطابة والدعوة',
          description:
              'تطوير مهارات الإلقاء المنبري، واختيار موضوعات خطب الجمعة المؤثرة والمعاصرة.',
          iconName: 'record_voice_over',
          colorKey: 'purple',
          membersCount: 520,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          rules: [
            'تبادل نماذج وعناصر لخطب الجمعة والمناسبات.',
            'توجيه الخطاب بما يعزز الوحدة والأخلاق في المجتمع.',
          ],
        ),
      ];

      for (final g in defaultGroups) {
        await _groups.doc(g.id).set(g.toFirestore());
      }
    } catch (_) {
      // Ignore initial seed errors if permissions or offline
    }
  }
}
