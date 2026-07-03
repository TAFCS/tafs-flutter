import '../../../auth/domain/entities/student.dart';
import '../../domain/entities/notice_post.dart';

/// Mirrors the backend's post-targeting match semantics (see
/// NoticeBoardService.getPostsForFamily): for campus/class/section, an
/// empty id list on the post means "matches everyone at that level"; a
/// non-empty list requires the student's id to be present in it.
class NoticeTargeting {
  NoticeTargeting._();

  static bool isSpecificallyTargeted(NoticePost post) =>
      post.campusIds.isNotEmpty || post.classIds.isNotEmpty || post.sectionIds.isNotEmpty;

  static bool _levelMatches(List<int> postIds, int? studentId) {
    if (postIds.isEmpty) return true;
    if (studentId == null) return false;
    return postIds.contains(studentId);
  }

  static bool matchesStudent(NoticePost post, Student student) =>
      _levelMatches(post.campusIds, student.campusId) &&
      _levelMatches(post.classIds, student.classId) &&
      _levelMatches(post.sectionIds, student.sectionId);

  /// Empty for school-wide posts, or when no child matches.
  static List<Student> matchedStudents(NoticePost post, List<Student> students) {
    if (!isSpecificallyTargeted(post)) return const [];
    return students.where((s) => matchesStudent(post, s)).toList(growable: false);
  }
}
