import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/staff_notice_post.dart';
import '../../domain/repositories/staff_notice_board_repository.dart';

class StaffNoticeBoardState {
  final List<StaffNoticePost> posts;
  final List<CampusScope> campuses;
  final bool loading;
  final bool actionLoading;
  final bool uploading;
  final String? error;
  final String? actionError;

  const StaffNoticeBoardState({
    this.posts = const [],
    this.campuses = const [],
    this.loading = false,
    this.actionLoading = false,
    this.uploading = false,
    this.error,
    this.actionError,
  });

  StaffNoticeBoardState copyWith({
    List<StaffNoticePost>? posts,
    List<CampusScope>? campuses,
    bool? loading,
    bool? actionLoading,
    bool? uploading,
    String? error,
    String? actionError,
    bool clearError = false,
    bool clearActionError = false,
  }) =>
      StaffNoticeBoardState(
        posts: posts ?? this.posts,
        campuses: campuses ?? this.campuses,
        loading: loading ?? this.loading,
        actionLoading: actionLoading ?? this.actionLoading,
        uploading: uploading ?? this.uploading,
        error: clearError ? null : (error ?? this.error),
        actionError: clearActionError ? null : (actionError ?? this.actionError),
      );
}

class StaffNoticeBoardCubit extends Cubit<StaffNoticeBoardState> {
  final StaffNoticeBoardRepository repository;
  bool _initialized = false;

  StaffNoticeBoardCubit({required this.repository})
      : super(const StaffNoticeBoardState());

  Future<void> load() async {
    if (_initialized) {
      await refresh();
      return;
    }
    _initialized = true;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final results = await Future.wait([
        repository.getPosts(),
        repository.getCampuses(),
      ]);
      emit(StaffNoticeBoardState(
        posts: results[0] as List<StaffNoticePost>,
        campuses: results[1] as List<CampusScope>,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load notice board.',
      ));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final posts = await repository.getPosts();
      emit(state.copyWith(posts: posts, loading: false));
    } catch (_) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to refresh notice board.',
      ));
    }
  }

  Future<NoticeReadStats?> loadReadStats(int postId) async {
    try {
      return await repository.getReadStats(postId);
    } catch (_) {
      return null;
    }
  }

  Future<StaffNoticePost?> createPost({
    String? title,
    required String body,
    required List<int> campusIds,
    required List<int> classIds,
    required List<int> sectionIds,
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required bool isPinned,
    DateTime? expiresAt,
  }) async {
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final post = await repository.createPost(
        title: title,
        body: body,
        campusIds: campusIds,
        classIds: classIds,
        sectionIds: sectionIds,
        mediaUrls: mediaUrls,
        mediaTypes: mediaTypes,
        isPinned: isPinned,
        expiresAt: expiresAt,
      );
      emit(state.copyWith(
        posts: [post, ...state.posts],
        actionLoading: false,
      ));
      return post;
    } catch (_) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Failed to create post.',
      ));
      return null;
    }
  }

  Future<bool> togglePin(StaffNoticePost post) async {
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      final updated = await repository.togglePin(post.id, !post.isPinned);
      final posts = state.posts.map((p) {
        if (p.id == post.id) {
          return StaffNoticePost(
            id: updated.id,
            title: updated.title,
            body: updated.body,
            postedByName: post.postedByName,
            campusIds: post.campusIds,
            classIds: post.classIds,
            sectionIds: post.sectionIds,
            mediaUrls: post.mediaUrls,
            mediaTypes: post.mediaTypes,
            isPinned: updated.isPinned,
            postedAt: post.postedAt,
            expiresAt: post.expiresAt,
            readCount: post.readCount,
          );
        }
        return p;
      }).toList();
      posts.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.postedAt.compareTo(a.postedAt);
      });
      emit(state.copyWith(posts: posts, actionLoading: false));
      return updated.isPinned;
    } catch (_) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Failed to update pin.',
      ));
      return post.isPinned;
    }
  }

  Future<bool> deletePost(int postId) async {
    emit(state.copyWith(actionLoading: true, clearActionError: true));
    try {
      await repository.deletePost(postId);
      emit(state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
        actionLoading: false,
      ));
      return true;
    } catch (_) {
      emit(state.copyWith(
        actionLoading: false,
        actionError: 'Failed to delete post.',
      ));
      return false;
    }
  }

  Future<UploadedNoticeMedia?> uploadMedia(XFile file, String displayName) async {
    emit(state.copyWith(uploading: true, clearActionError: true));
    try {
      final media = await repository.uploadMedia(file, displayName);
      emit(state.copyWith(uploading: false));
      return media;
    } catch (_) {
      emit(state.copyWith(
        uploading: false,
        actionError: 'Failed to upload file.',
      ));
      return null;
    }
  }

  void reset() {
    _initialized = false;
    emit(const StaffNoticeBoardState());
  }
}

String scopeLabelForPost(StaffNoticePost post, List<CampusScope> campuses) {
  if (post.isSchoolWide) return 'School-wide';
  final parts = <String>[];
  if (post.campusIds.isNotEmpty) {
    final names = campuses
        .where((c) => post.campusIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    if (names.isNotEmpty) parts.add(names.join(', '));
  }
  return parts.isNotEmpty ? parts.join(' · ') : 'Targeted';
}
