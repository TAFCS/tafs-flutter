import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message.dart';
import '../../data/models/grade_section_dto.dart';
import '../../domain/repositories/staff_announcements_repository.dart';

class StaffAnnouncementsState {
  final List<ChatMessage> messages;
  final bool loading;
  final bool sending;
  final String? error;
  final String? targetGrade;
  final String? targetSection;
  final bool isSocketConnected;
  final List<GradeOption> gradeOptions;
  final List<SectionOption> sectionOptions;
  final String? targetingWarning;

  const StaffAnnouncementsState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.error,
    this.targetGrade,
    this.targetSection,
    this.isSocketConnected = false,
    this.gradeOptions = const [],
    this.sectionOptions = const [],
    this.targetingWarning,
  });

  StaffAnnouncementsState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    String? error,
    String? targetGrade,
    String? targetSection,
    bool? isSocketConnected,
    List<GradeOption>? gradeOptions,
    List<SectionOption>? sectionOptions,
    String? targetingWarning,
    bool clearError = false,
    bool clearTargetGrade = false,
    bool clearTargetSection = false,
    bool clearTargetingWarning = false,
  }) =>
      StaffAnnouncementsState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
        targetGrade: clearTargetGrade ? null : (targetGrade ?? this.targetGrade),
        targetSection:
            clearTargetSection ? null : (targetSection ?? this.targetSection),
        isSocketConnected: isSocketConnected ?? this.isSocketConnected,
        gradeOptions: gradeOptions ?? this.gradeOptions,
        sectionOptions: sectionOptions ?? this.sectionOptions,
        targetingWarning: clearTargetingWarning
            ? null
            : (targetingWarning ?? this.targetingWarning),
      );
}

class StaffAnnouncementsCubit extends Cubit<StaffAnnouncementsState> {
  final StaffAnnouncementsRepository repository;
  StreamSubscription<ChatMessage>? _announcementSub;
  StreamSubscription<void>? _connectSub;
  StreamSubscription<void>? _disconnectSub;
  bool _initialized = false;

  StaffAnnouncementsCubit({required this.repository})
      : super(const StaffAnnouncementsState());

  Future<void> load() async {
    if (_initialized) {
      await _refreshHistory();
      return;
    }
    _initialized = true;
    emit(state.copyWith(loading: true, clearError: true));

    repository.ensureSocketConnected();
    emit(state.copyWith(isSocketConnected: repository.isSocketConnected));

    await _announcementSub?.cancel();
    await _connectSub?.cancel();
    await _disconnectSub?.cancel();

    _announcementSub = repository.onAnnouncementReceived.listen(_onAnnouncement);
    _connectSub = repository.onSocketConnect.listen((_) {
      emit(state.copyWith(isSocketConnected: true, clearError: true));
    });
    _disconnectSub = repository.onSocketDisconnect.listen((_) {
      emit(state.copyWith(isSocketConnected: false));
    });

    List<GradeOption> grades = const [];
    List<SectionOption> sections = const [];
    String? targetingWarning;

    try {
      grades = await repository.fetchGrades();
    } catch (_) {
      targetingWarning =
          'Grade list unavailable — you can still broadcast to all parents.';
    }

    try {
      sections = await repository.fetchSections();
    } catch (_) {
      targetingWarning = targetingWarning == null
          ? 'Section list unavailable — grade-only or all-parent targeting still works.'
          : 'Grade and section lists unavailable — you can still broadcast to all parents.';
    }

    try {
      final history = await repository.fetchHistory();
      emit(state.copyWith(
        loading: false,
        messages: history.reversed.toList(),
        gradeOptions: grades,
        sectionOptions: sections,
        targetingWarning: targetingWarning,
        isSocketConnected: repository.isSocketConnected,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load announcements.',
        gradeOptions: grades,
        sectionOptions: sections,
        targetingWarning: targetingWarning,
        isSocketConnected: repository.isSocketConnected,
      ));
    }
  }

  Future<void> _refreshHistory() async {
    try {
      final history = await repository.fetchHistory();
      emit(state.copyWith(
        messages: history.reversed.toList(),
        isSocketConnected: repository.isSocketConnected,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to refresh announcements.'));
    }
  }

  Future<void> refresh() => _refreshHistory();

  void setTargetGrade(String? grade) {
    emit(state.copyWith(
      targetGrade: grade,
      clearTargetSection: true,
      targetSection: null,
    ));
  }

  void setTargetSection(String? section) {
    emit(state.copyWith(targetSection: section));
  }

  void _onAnnouncement(ChatMessage message) {
    if (state.messages.any((m) => m.id == message.id)) return;
    emit(state.copyWith(messages: [...state.messages, message]));
  }

  Future<void> sendText(String content) async {
    if (content.trim().isEmpty) return;
    if (!repository.isSocketConnected) {
      emit(state.copyWith(error: 'You are offline. Reconnect to send announcements.'));
      return;
    }
    emit(state.copyWith(sending: true, clearError: true));
    try {
      repository.sendAnnouncement(
        messageType: 'TEXT',
        content: content.trim(),
        targetGrade: state.targetGrade,
        targetSection: state.targetSection,
      );
      emit(state.copyWith(sending: false));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _refreshHistory();
    } catch (e) {
      emit(state.copyWith(sending: false, error: 'Failed to send announcement.'));
    }
  }

  Future<void> sendMedia({
    required String messageType,
    required String content,
    Map<String, dynamic>? mediaMetadata,
  }) async {
    if (!repository.isSocketConnected) {
      emit(state.copyWith(error: 'You are offline. Reconnect to send announcements.'));
      return;
    }
    emit(state.copyWith(sending: true, clearError: true));
    try {
      repository.sendAnnouncement(
        messageType: messageType,
        content: content,
        mediaMetadata: mediaMetadata,
        targetGrade: state.targetGrade,
        targetSection: state.targetSection,
      );
      emit(state.copyWith(sending: false));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _refreshHistory();
    } catch (e) {
      emit(state.copyWith(sending: false, error: 'Failed to send attachment.'));
    }
  }

  void reset() {
    _initialized = false;
    _announcementSub?.cancel();
    _connectSub?.cancel();
    _disconnectSub?.cancel();
    _announcementSub = null;
    _connectSub = null;
    _disconnectSub = null;
    emit(const StaffAnnouncementsState());
  }

  @override
  Future<void> close() {
    _announcementSub?.cancel();
    _connectSub?.cancel();
    _disconnectSub?.cancel();
    return super.close();
  }
}
