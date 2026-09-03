import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../registration/data/registration_repository.dart';
import '../data/forum_repository.dart';
import '../domain/forum_message_model.dart';
import '../domain/imam_group_model.dart';
import '../../notifications/data/notification_model.dart';

/// Filter state for discovering groups
class ForumFilterState {
  const ForumFilterState({
    this.category = 'الكل',
    this.searchQuery = '',
  });

  final String category;
  final String searchQuery;

  ForumFilterState copyWith({
    String? category,
    String? searchQuery,
  }) {
    return ForumFilterState(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Provider for forum filter parameters
final forumFilterProvider =
    NotifierProvider.autoDispose<ForumFilterNotifier, ForumFilterState>(
  ForumFilterNotifier.new,
);

class ForumFilterNotifier extends Notifier<ForumFilterState> {
  @override
  ForumFilterState build() => const ForumFilterState();

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Streams all Imam groups based on the active filter
final imamGroupsStreamProvider =
    StreamProvider.autoDispose<List<ImamGroupModel>>((ref) {
  final repo = ref.watch(forumRepositoryProvider);
  final filter = ref.watch(forumFilterProvider);

  return repo.watchGroups(
    category: filter.category == 'الكل' || filter.category == 'All'
        ? null
        : filter.category,
    searchQuery: filter.searchQuery,
  );
});

/// Streams a single group's details
final singleGroupStreamProvider =
    StreamProvider.autoDispose.family<ImamGroupModel?, String>((ref, groupId) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.watchGroup(groupId);
});

/// Streams messages for a group chat
final groupMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<ForumMessageModel>, String>((ref, groupId) {
  final repo = ref.watch(forumRepositoryProvider);
  return repo.watchMessages(groupId);
});

/// Streams unread forum-only notification count for the current imam.
/// Returns 0 if not logged in.
final forumUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final imam = ref.watch(currentImamProvider).asData?.value;
  if (imam == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('imams')
      .doc(imam.id)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .where('type', whereIn: NotifType.forumTypes)
      .snapshots()
      .map((snap) => snap.docs.length);
});

/// Streams the list of mutedGroupIds for the current imam.
final mutedGroupsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final imam = ref.watch(currentImamProvider).asData?.value;
  if (imam == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('imams')
      .doc(imam.id)
      .snapshots()
      .map((doc) => List<String>.from(doc.data()?['mutedGroups'] ?? []));
});

/// Controller for performing group and messaging actions
final forumControllerProvider =
    NotifierProvider<ForumController, AsyncValue<void>>(() {
  return ForumController();
});

class ForumController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  ForumRepository get _repository => ref.read(forumRepositoryProvider);

  Future<bool> joinGroup({
    required String groupId,
    required String imamId,
    String imamName = '',
    String groupName = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.joinGroup(
        groupId: groupId,
        imamId: imamId,
        imamName: imamName,
        groupName: groupName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> leaveGroup({
    required String groupId,
    required String imamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveGroup(groupId: groupId, imamId: imamId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendMessage({
    required String groupId,
    required ForumMessageModel message,
  }) async {
    try {
      await _repository.sendMessage(groupId: groupId, message: message);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String?> uploadImage({
    required File file,
    required String imamId,
  }) async {
    try {
      return await _repository.uploadChatMedia(file: file, imamId: imamId);
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleReaction({
    required String groupId,
    required String messageId,
    required String emoji,
    required String imamId,
  }) async {
    try {
      await _repository.toggleReaction(
        groupId: groupId,
        messageId: messageId,
        emoji: emoji,
        imamId: imamId,
      );
    } catch (_) {}
  }

  Future<bool> createGroup(ImamGroupModel group) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createGroup(group);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateGroup(ImamGroupModel group) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGroup(group);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGroup(groupId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> muteGroup({required String groupId, required String imamId}) async {
    try {
      await _repository.muteGroup(groupId: groupId, imamId: imamId);
    } catch (_) {}
  }

  Future<void> unmuteGroup({required String groupId, required String imamId}) async {
    try {
      await _repository.unmuteGroup(groupId: groupId, imamId: imamId);
    } catch (_) {}
  }
}
