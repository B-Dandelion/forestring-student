import '../domain/lesson.dart';
import '../domain/lesson_history.dart';
import 'lesson_repository.dart';

class ReviewLessonRepository extends LessonRepository {
  ReviewLessonRepository({
    required this.studentId,
  }) {
    _seedDemoData();
  }

  final String studentId;

  static const _teacherId = 'review-teacher';
  static const _teacherName = '박지은';

  final List<Lesson> _lessons = [];
  final Map<String, DateTime> _originalStartsByRight = {};
  final Map<String, DateTime?> _canceledAtByRight = {};
  final Map<String, DateTime?> _reservedAtByRight = {};
  final Map<String, String> _semesterIdByRight = {};
  final List<_ReviewSemester> _semesters = [];

  DateTime _atTime(DateTime date, int hour, [int minute = 0]) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _monthCode(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _seedDemoData() {
    if (_lessons.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    var anchorMonth = DateTime(now.year, now.month, 16);
    if (now.isBefore(anchorMonth)) {
      anchorMonth = DateTime(now.year, now.month - 1, 16);
    }

    var lessonSequence = 1;

    for (var semesterIndex = 0; semesterIndex < 4; semesterIndex++) {
      final start = DateTime(
        anchorMonth.year,
        anchorMonth.month + semesterIndex,
        16,
      );
      final end = DateTime(
        anchorMonth.year,
        anchorMonth.month + semesterIndex + 1,
        15,
      );
      final semesterId = 'review-semester-${semesterIndex + 1}';
      final lessonOffsets = semesterIndex == 0
          ? const [9, 12, 16, 19]
          : const [7, 14, 21, 28];

      _semesters.add(
        _ReviewSemester(
          id: semesterId,
          code: _monthCode(start),
          startsOn: start,
          endsOn: end,
        ),
      );

      for (var i = 0; i < lessonOffsets.length; i++) {
        final startAt = _atTime(
          start.add(Duration(days: lessonOffsets[i])),
          10,
        );
        final rightId = 'review-right-$lessonSequence';
        final lessonId = 'review-lesson-$lessonSequence';

        _originalStartsByRight[rightId] = startAt;
        _reservedAtByRight[rightId] = now;
        _canceledAtByRight[rightId] = null;
        _semesterIdByRight[rightId] = semesterId;

        _lessons.add(
          Lesson(
            id: lessonId,
            studentId: studentId,
            teacherId: _teacherId,
            startsAt: startAt,
            endsAt: startAt.add(const Duration(minutes: 30)),
            durationMinutes: 30,
            type: LessonType.regular,
            status: LessonStatus.scheduled,
            lessonRightId: rightId,
            occurrenceAt: startAt,
            teacherName: _teacherName,
          ),
        );

        lessonSequence++;
      }
    }
  }

  @override
  Future<DateTime?> fetchEnrollmentStartDate() async {
    if (_semesters.isEmpty) {
      return null;
    }

    final sorted = [..._semesters]
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    return sorted.first.startsOn;
  }

  @override
  Future<List<Lesson>> fetchMyLessons({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = [..._lessons]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return result;
  }

  @override
  Future<void> cancelLesson({
    required String lessonId,
    String? reason,
  }) async {
    final index = _lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (index < 0) {
      throw const LessonFailure('수업을 찾을 수 없습니다.');
    }

    final current = _lessons[index];
    if (current.isCanceled) {
      throw const LessonFailure('이미 취소된 수업입니다.');
    }

    final rightId = current.lessonRightId;
    if (rightId == null) {
      throw const LessonFailure('재예약 가능한 수업권이 없습니다.');
    }

    final now = DateTime.now();
    _canceledAtByRight[rightId] = now;
    _reservedAtByRight[rightId] = null;

    _lessons[index] = Lesson(
      id: current.id,
      studentId: current.studentId,
      teacherId: current.teacherId,
      startsAt: current.startsAt,
      endsAt: current.endsAt,
      durationMinutes: current.durationMinutes,
      type: current.type,
      status: LessonStatus.canceled,
      lessonRightId: current.lessonRightId,
      occurrenceAt: current.occurrenceAt,
      rescheduledBy: current.rescheduledBy,
      updatedAt: now,
      teacherName: current.teacherName,
    );
  }

  @override
  Future<LessonBookingWindow> getBookingWindow({
    required String rightId,
  }) async {
    final semesterId = _semesterIdByRight[rightId];
    if (semesterId == null) {
      throw const LessonFailure('수업권을 찾을 수 없습니다.');
    }

    final semester = _semesters.firstWhere(
      (item) => item.id == semesterId,
    );

    return LessonBookingWindow(
      startsOn: semester.startsOn,
      endsOn: semester.endsOn,
    );
  }

  @override
  Future<List<LessonBookingOption>> getBookingOptions({
    required String rightId,
    required DateTime selectedDate,
  }) async {
    if (!_originalStartsByRight.containsKey(rightId)) {
      throw const LessonFailure('수업권을 찾을 수 없습니다.');
    }

    final window = await getBookingWindow(rightId: rightId);
    final date = _dateOnly(selectedDate);
    if (date.isBefore(_dateOnly(window.startsOn)) ||
        date.isAfter(_dateOnly(window.endsOn))) {
      return const [];
    }

    final options = <LessonBookingOption>[];
    for (var hour = 9; hour <= 12; hour++) {
      for (var minute = 0; minute < 60; minute += 15) {
        final start = _atTime(date, hour, minute);
        if (start.isBefore(DateTime.now().add(const Duration(hours: 5)))) {
          continue;
        }

        final occupied = _lessons.any(
          (lesson) =>
              !lesson.isCanceled &&
              start.isBefore(lesson.endsAt) &&
              start.add(const Duration(minutes: 30)).isAfter(lesson.startsAt),
        );
        if (occupied) {
          continue;
        }

        options.add(
          LessonBookingOption(
            startsAt: start,
            endsAt: start.add(const Duration(minutes: 30)),
            teacherId: _teacherId,
          ),
        );
      }
    }
    return options;
  }

  @override
  Future<void> bookLessonRight({
    required String rightId,
    required DateTime startsAt,
  }) async {
    final index = _lessons.indexWhere(
      (lesson) => lesson.lessonRightId == rightId,
    );
    if (index < 0) {
      throw const LessonFailure('수업권을 찾을 수 없습니다.');
    }

    final current = _lessons[index];
    if (!current.isCanceled) {
      throw const LessonFailure('재예약 가능한 수업이 아닙니다.');
    }

    final now = DateTime.now();
    final originalStart = _originalStartsByRight[rightId] ?? current.startsAt;
    _reservedAtByRight[rightId] = now;

    _lessons[index] = Lesson(
      id: current.id,
      studentId: current.studentId,
      teacherId: current.teacherId,
      startsAt: startsAt,
      endsAt: startsAt.add(Duration(minutes: current.durationMinutes)),
      durationMinutes: current.durationMinutes,
      type: current.type,
      status: LessonStatus.scheduled,
      lessonRightId: current.lessonRightId,
      occurrenceAt: originalStart,
      rescheduledBy: studentId,
      updatedAt: now,
      teacherName: current.teacherName,
    );
  }

  @override
  Future<LessonHistoryData> fetchMyLessonHistory() async {
    final semesterHistories = <SemesterLessonHistory>[];

    for (final semester in _semesters) {
      final lessons = _lessons.where((lesson) {
        final rightId = lesson.lessonRightId;
        return rightId != null && _semesterIdByRight[rightId] == semester.id;
      }).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

      final rights = <LessonRightHistory>[];
      for (var i = 0; i < lessons.length; i++) {
        final lesson = lessons[i];
        final rightId = lesson.lessonRightId!;
        final canceledAt = _canceledAtByRight[rightId];
        final cancellations = canceledAt == null
            ? const <LessonCancellationHistory>[]
            : <LessonCancellationHistory>[
                LessonCancellationHistory(
                  origin: 'student',
                  actorId: studentId,
                  canceledAt: canceledAt,
                  countsTowardLimit: true,
                ),
              ];

        rights.add(
          LessonRightHistory(
            id: rightId,
            origin: 'regular_base',
            status: lesson.isCanceled ? 'available' : 'reserved',
            sequenceNo: i + 1,
            durationMinutes: lesson.durationMinutes,
            reservedAt: _reservedAtByRight[rightId],
            lesson: lesson,
            cancellations: cancellations,
          ),
        );
      }

      semesterHistories.add(
        SemesterLessonHistory(
          id: semester.id,
          code: semester.code,
          startsOn: semester.startsOn,
          endsOn: semester.endsOn,
          rights: rights,
        ),
      );
    }

    semesterHistories.sort((a, b) => b.startsOn.compareTo(a.startsOn));

    return LessonHistoryData(
      studentId: studentId,
      studentType: 'regular',
      semesters: semesterHistories,
    );
  }
}

class _ReviewSemester {
  const _ReviewSemester({
    required this.id,
    required this.code,
    required this.startsOn,
    required this.endsOn,
  });

  final String id;
  final String code;
  final DateTime startsOn;
  final DateTime endsOn;
}
