import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/lesson.dart';
import '../domain/lesson_history.dart';

class LessonFailure implements Exception {
  const LessonFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class LessonRepository {
  LessonRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DateTime?> fetchEnrollmentStartDate() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LessonFailure('로그인이 필요합니다.');
    }

    try {
      final rows = await _client
          .from('student_enrollment_periods')
          .select('starts_on')
          .eq('student_id', user.id)
          .order('starts_on')
          .limit(1);

      final list = rows as List;
      if (list.isEmpty) {
        return null;
      }

      final row = Map<String, dynamic>.from(list.first as Map);
      return DateTime.parse(row['starts_on'].toString());
    } on PostgrestException {
      return null;
    }
  }

  Future<List<Lesson>> fetchMyLessons({
    required DateTime from,
    required DateTime to,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LessonFailure('로그인이 필요합니다.');
    }

    try {
      final rows = await _client
          .from('lessons')
          .select(
            'id, student_id, teacher_id, occurrence_at, starts_at, '
            'duration_minutes, ends_at, lesson_type, status, lesson_right_id, '
            'rescheduled_by, updated_at',
          )
          .eq('student_id', user.id)
          .gte('starts_at', from.toUtc().toIso8601String())
          .lt('starts_at', to.toUtc().toIso8601String())
          .order('starts_at');

      final lessons = (rows as List)
          .map(
            (row) => Lesson.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      final teacherNames = await _fetchTeacherNames(
        lessons.map((lesson) => lesson.teacherId).toSet(),
      );

      return lessons
          .map(
            (lesson) => lesson.copyWithTeacherName(
              teacherNames[lesson.teacherId],
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    } catch (error) {
      throw LessonFailure('수업 정보를 불러오지 못했습니다.\n$error');
    }
  }

  Future<LessonHistoryData> fetchMyLessonHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const LessonFailure('로그인이 필요합니다.');
    }

    try {
      final studentRow = await _client
          .from('students')
          .select('student_type')
          .eq('id', user.id)
          .single();
      final studentType = studentRow['student_type'].toString();

      final rightsRows = await _client
          .from('lesson_rights')
          .select(
            'id, branch_id, usable_semester_id, origin, sequence_no, '
            'duration_minutes, status, issued_at, reserved_at',
          )
          .eq('student_id', user.id)
          .order('issued_at', ascending: false);

      final rightsList = rightsRows as List;
      if (rightsList.isEmpty) {
        return LessonHistoryData(
          studentId: user.id,
          studentType: studentType,
          semesters: const [],
        );
      }

      final lessonsRows = await _client
          .from('lessons')
          .select(
            'id, student_id, teacher_id, occurrence_at, starts_at, '
            'duration_minutes, ends_at, lesson_type, status, lesson_right_id, '
            'rescheduled_by, updated_at',
          )
          .eq('student_id', user.id)
          .order('starts_at');

      final parsedLessonsByRight = <String, Lesson>{};
      final teacherIds = <String>{};
      for (final raw in lessonsRows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final rightId = row['lesson_right_id'] as String?;
        if (rightId == null) {
          continue;
        }
        final lesson = Lesson.fromJson(row);
        parsedLessonsByRight[rightId] = lesson;
        teacherIds.add(lesson.teacherId);
      }

      final teacherNames = await _fetchTeacherNames(teacherIds);
      final lessonsByRight = <String, Lesson>{
        for (final entry in parsedLessonsByRight.entries)
          entry.key: entry.value.copyWithTeacherName(
            teacherNames[entry.value.teacherId],
          ),
      };

      final cancellationRows = await _client
          .from('lesson_cancellation_events')
          .select(
            'lesson_right_id, origin, actor_id, counts_toward_limit, '
            'canceled_at, created_at, lesson_starts_at, '
            'lesson_duration_minutes',
          )
          .eq('student_id', user.id)
          .order('created_at');

      final semesterRows = await _client
          .from('semesters')
          .select('id, code, starts_on, ends_on');

      List<dynamic> overrideRows = const [];
      try {
        overrideRows = await _client
            .from('branch_semester_overrides')
            .select('branch_id, semester_id, starts_on, ends_on');
      } on PostgrestException {
        overrideRows = const [];
      }

      final cancellationsByRight = <String, List<LessonCancellationHistory>>{};
      for (final raw in cancellationRows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final rightId = row['lesson_right_id'] as String;
        final actorId = row['actor_id'] as String;
        final canceledAtValue = row['canceled_at'] ?? row['created_at'];

        cancellationsByRight.putIfAbsent(rightId, () => []).add(
              LessonCancellationHistory(
                origin: row['origin'].toString(),
                actorId: actorId,
                canceledAt: DateTime.parse(
                  canceledAtValue.toString(),
                ).toLocal(),
                countsTowardLimit: row['counts_toward_limit'] == true,
                lessonStartsAt: row['lesson_starts_at'] == null
                    ? null
                    : DateTime.parse(
                        row['lesson_starts_at'].toString(),
                      ).toLocal(),
                lessonDurationMinutes:
                    row['lesson_duration_minutes'] as int?,
              ),
            );
      }

      final semestersById = <String, Map<String, dynamic>>{
        for (final raw in semesterRows as List)
          (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
      };

      final overridesByKey = <String, Map<String, dynamic>>{};
      for (final raw in overrideRows) {
        final row = Map<String, dynamic>.from(raw as Map);
        overridesByKey['${row['branch_id']}:${row['semester_id']}'] = row;
      }

      final rightsBySemester = <String, List<LessonRightHistory>>{};
      final branchBySemester = <String, String>{};

      for (final raw in rightsList) {
        final row = Map<String, dynamic>.from(raw as Map);
        final rightId = row['id'] as String;
        final semesterId = row['usable_semester_id'] as String;

        branchBySemester[semesterId] = row['branch_id'] as String;

        rightsBySemester.putIfAbsent(semesterId, () => []).add(
              LessonRightHistory(
                id: rightId,
                origin: row['origin'].toString(),
                status: row['status'].toString(),
                sequenceNo: row['sequence_no'] as int? ?? 0,
                durationMinutes: row['duration_minutes'] as int,
                reservedAt: row['reserved_at'] == null
                    ? null
                    : DateTime.parse(row['reserved_at'].toString()).toLocal(),
                lesson: lessonsByRight[rightId],
                cancellations: cancellationsByRight[rightId] ?? const [],
              ),
            );
      }

      final semesterHistories = <SemesterLessonHistory>[];
      for (final entry in rightsBySemester.entries) {
        final semester = semestersById[entry.key];
        if (semester == null) {
          continue;
        }

        final branchId = branchBySemester[entry.key];
        final override = branchId == null
            ? null
            : overridesByKey['$branchId:${entry.key}'];

        final startsOn = DateTime.parse(
          (override?['starts_on'] ?? semester['starts_on']).toString(),
        );
        final endsOn = DateTime.parse(
          (override?['ends_on'] ?? semester['ends_on']).toString(),
        );

        final rights = [...entry.value]
          ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

        semesterHistories.add(
          SemesterLessonHistory(
            id: entry.key,
            code: semester['code'].toString(),
            startsOn: startsOn,
            endsOn: endsOn,
            rights: rights,
          ),
        );
      }

      semesterHistories.sort((a, b) => b.startsOn.compareTo(a.startsOn));
      return LessonHistoryData(
        studentId: user.id,
        studentType: studentType,
        semesters: semesterHistories,
      );
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    } catch (error) {
      throw LessonFailure('수강 내역을 불러오지 못했습니다.\n$error');
    }
  }

  Future<void> cancelLesson({
    required String lessonId,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'cancel_lesson',
        params: {
          'p_lesson_id': lessonId,
          'p_reason': _nullIfBlank(reason),
        },
      );
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<LessonBookingWindow> getBookingWindow({
    required String rightId,
  }) async {
    try {
      final right = await _client
          .from('lesson_rights')
          .select('usable_semester_id, branch_id')
          .eq('id', rightId)
          .single();

      final semesterId = right['usable_semester_id'] as String;
      final branchId = right['branch_id'] as String;
      final semester = await _client
          .from('semesters')
          .select('starts_on, ends_on')
          .eq('id', semesterId)
          .single();

      final override = await _client
          .from('branch_semester_overrides')
          .select('starts_on, ends_on')
          .eq('branch_id', branchId)
          .eq('semester_id', semesterId)
          .maybeSingle();

      final startsOn = DateTime.parse(
        (override?['starts_on'] ?? semester['starts_on']).toString(),
      );
      final endsOn = DateTime.parse(
        (override?['ends_on'] ?? semester['ends_on']).toString(),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (today.isBefore(startsOn) || today.isAfter(endsOn)) {
        throw const LessonFailure(
          '현재 학기의 수업권만 변경할 수 있습니다.',
        );
      }

      return LessonBookingWindow(
        startsOn: startsOn,
        endsOn: endsOn,
      );
    } on LessonFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    } catch (_) {
      throw const LessonFailure('예약 가능한 기간을 확인하지 못했습니다.');
    }
  }

  Future<List<LessonBookingOption>> getBookingOptions({
    required String rightId,
    required DateTime selectedDate,
  }) async {
    try {
      final data = await _client.rpc(
        'get_lesson_right_booking_options',
        params: {
          'p_right_id': rightId,
          'p_selected_date': _dateText(selectedDate),
        },
      );

      return (data as List)
          .map(
            (row) => LessonBookingOption.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<void> bookLessonRight({
    required String rightId,
    required DateTime startsAt,
  }) async {
    try {
      await _client.rpc(
        'book_lesson_right',
        params: {
          'p_right_id': rightId,
          'p_new_starts_at': startsAt.toUtc().toIso8601String(),
        },
      );
    } on PostgrestException catch (error) {
      throw LessonFailure(_friendlyMessage(error.message));
    }
  }

  Future<Map<String, String>> _fetchTeacherNames(
    Set<String> teacherIds,
  ) async {
    if (teacherIds.isEmpty) {
      return const {};
    }

    try {
      final rows = await _client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', teacherIds.toList());

      return {
        for (final raw in rows as List)
          (raw as Map)['id'] as String: raw['display_name'] as String,
      };
    } on PostgrestException {
      return const {};
    }
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _friendlyMessage(String message) {
    if (message.contains('FORESTRING_EFFECTIVE_ACCESS_REQUIRED')) {
      return '현재 계정은 더 이상 사용할 수 없습니다.';
    }
    if (message.contains('FORESTRING_LESSON_NOT_FOUND')) {
      return '수업을 찾을 수 없습니다.';
    }
    if (message.contains('FORESTRING_STUDENT_SEMESTER_NOT_OPEN')) {
      return '현재 학기의 수업권만 변경할 수 있습니다.';
    }
    if (message.contains('FORESTRING_BOOKING_DATE_OUTSIDE_USABLE_SEMESTER')) {
      return '이 수업권을 사용할 수 있는 기간을 벗어났습니다.';
    }
    if (message.contains('FORESTRING_TEACHER_ASSIGNMENT_REQUIRED')) {
      return '선택한 날짜에는 예약 가능한 담당 선생님이 없습니다.';
    }
    if (message.contains('FORESTRING_BOOKING_SLOT_NOT_AVAILABLE') ||
        message.contains('FORESTRING_BOOKING_SLOT_TAKEN')) {
      return '선택한 시간이 더 이상 예약 가능하지 않습니다.';
    }
    if (message.contains('FORESTRING_LESSON_RIGHT_NOT_AVAILABLE')) {
      return '이미 사용되었거나 예약할 수 없는 수업권입니다.';
    }
    if (message.contains('FORESTRING_CANCEL') ||
        message.contains('QUOTA') ||
        message.contains('CANCELLATION')) {
      return '현재 정책상 이 수업을 취소할 수 없습니다.';
    }
    if (message.contains('FORESTRING_')) {
      return '요청을 처리할 수 없습니다.';
    }
    return '요청 처리 중 오류가 발생했습니다.';
  }
}
